#!/bin/bash

set -xeo pipefail

if [[ "$target_platform" = osx-* ]] ; then
    # The -dead_strip_dylibs option breaks g-ir-scanner in this package: the
    # scanner links a test executable to find paths to dylibs, but with this
    # option the linker strips them out. The resulting error message is
    # "ERROR: can't resolve libraries to shared libraries: ...".
    export LDFLAGS="$(echo $LDFLAGS |sed -e "s/-Wl,-dead_strip_dylibs//g")"
    export LDFLAGS_LD="$(echo $LDFLAGS_LD |sed -e "s/-dead_strip_dylibs//g")"
fi

meson_options_common=(
    --buildtype=release
    --backend=ninja
    -Dlibdir=lib
    -Dintrospection=enabled
    -Duse_fontconfig=true
    -Dgtk_doc=false
)
meson_options_build=("${meson_options_common[@]}")
meson_options_host=("${meson_options_common[@]}")


if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  (
    mkdir -p native-build
    pushd native-build

    export CC=$CC_FOR_BUILD
    export AR=($CC_FOR_BUILD -print-prog-name=ar)
    export NM=($CC_FOR_BUILD -print-prog-name=nm)
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
    export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CPPFLAGS

    meson "${meson_options_build[@]}" --prefix=$BUILD_PREFIX ..
    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by glib are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-save.sh
    ninja -j$CPU_COUNT -v
    ninja install
    popd
  )
  export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-load.sh
fi

mkdir forgebuild
cd forgebuild

export XDG_DATA_DIRS=${XDG_DATA_DIRS}:$PREFIX/share
export PKG_CONFIG="$BUILD_PREFIX/bin/pkg-config"
export PKG_CONFIG_PATH_FOR_BUILD="$BUILD_PREFIX/lib/pkgconfig"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig"
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != 1 ]]; then
  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig"
fi

meson "${meson_options_host[@]}" $MESON_ARGS --prefix=$PREFIX ..
ninja -j$CPU_COUNT -v
ninja install

cd $PREFIX
rm -rf share/gtk-doc

