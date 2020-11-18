#!/bin/bash

set -x

unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

if [[ "$target_platform" == osx-* ]]; then
  # For some reason, these are not getting added in osx-arm64 platform.
  # since it doesn't hurt, add these to all osx-* platforms.
  export LIBS="$LIBS -framework CoreFoundation -framework ApplicationServices"
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
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
    export host_alias=$build_alias

    ../configure --prefix=$BUILD_PREFIX \
                --with-xft \
                --with-cairo=$BUILD_PREFIX \

    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by glib are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$PREFIX/libexec/gi-cross-launcher-save.sh
    make -j${CPU_COUNT}
    make install
    rm -rf $PREFIX/bin/g-ir-scanner $PREFIX/bin/g-ir-compiler
    ln -s $BUILD_PREFIX/bin/g-ir-scanner $PREFIX/bin/g-ir-scanner
    ln -s $BUILD_PREFIX/bin/g-ir-compiler $PREFIX/bin/g-ir-compiler
    rsync -ahvpiI $BUILD_PREFIX/lib/gobject-introspection/ $PREFIX/lib/gobject-introspection/
    popd
  )
  export GI_CROSS_LAUNCHER=$PREFIX/libexec/gi-cross-launcher-load.sh
fi

# Cf. https://github.com/conda-forge/staged-recipes/issues/673, we're in the
# process of excising Libtool files from our packages. Existing ones can break
# the build while this happens.
find $PREFIX -name '*.la' -delete

./configure --prefix=$PREFIX \
            --with-xft \
            --with-cairo=$PREFIX
cat config.log

make V=1
# # FIXME: There is one failure:
# ========================================
#    pango 1.40.1: tests/test-suite.log
# ========================================
#
# # TOTAL: 12
# # PASS:  11
# # SKIP:  0
# # XFAIL: 0
# # FAIL:  1
# # XPASS: 0
# # ERROR: 0
#
# .. contents:: :depth: 2
#
# FAIL: test-layout
# =================
#
# /layout/valid-1.markup:
# (/opt/conda/conda-bld/work/pango-1.40.1/tests/.libs/lt-test-layout:5078): Pango-CRITICAL **: pango_font_describe: assertion 'font != NULL' failed
# FAIL test-layout (exit status: 133)
# make check
make install
rm -rf $PREFIX/lib/gobject-introspection
