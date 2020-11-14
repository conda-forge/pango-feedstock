#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

if [[ "$target_platform" == osx-* ]]; then
  # For some reason, these are not getting added in osx-arm64 platform.
  # since it doesn't hurt, add these to all osx-* platforms.
  export LIBS="$LIBS -framework CoreFoundation -framework ApplicationServices"
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
