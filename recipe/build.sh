#!/bin/bash


set -ex

meson_config_args=(
    -D gtk_doc=false
    -D introspection=true
    -D install-tests=false
)

# ensure that the post install script is ignored
export DESTDIR="/"

meson setup builddir \
    "${meson_config_args[@]}" \
    --buildtype=release \
    --prefix=$PREFIX \
    --libdir=$PREFIX/lib  \
    --wrap-mode=nofallback
ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir install -j ${CPU_COUNT}
