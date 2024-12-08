setlocal EnableDelayedExpansion
@echo on

:: set pkg-config path so that host deps can be found
:: (set as env var so it's used by both meson and during build with g-ir-scanner)
set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig"

:: get mixed path (forward slash) form of prefix so host prefix replacement works
set "LIBRARY_PREFIX_M=%LIBRARY_PREFIX:\=/%"

:: By default Meson tries to run glib-mkenums with the %BUILD_PREFIX% Python, which fails.
:: In order to override this, we need to use a Meson machine file, because otherwise
:: Meson prioritizes the results from the glib-2.0 pkg-config file, which don't work.
echo [binaries] >native_file.txt
echo glib-mkenums = ['%PREFIX%\python.exe', '%LIBRARY_PREFIX%\bin\glib-mkenums'] >>native_file.txt

set "XDG_DATA_DIRS=%XDG_DATA_DIRS%;%LIBRARY_PREFIX%\share"

:: meson options
:: (set pkg_config_path so deps in host env can be found)
set ^"MESON_OPTIONS=^
  --prefix="%LIBRARY_PREFIX_M%" ^
  --wrap-mode=nofallback ^
  --buildtype=release ^
  --backend=ninja ^
  --native-file=native_file.txt ^
  -Dintrospection=enabled ^
  -Dfontconfig=enabled ^
  -Dfreetype=enabled ^
  -Dgtk_doc=false ^
 ^"

:: configure build using meson
%BUILD_PREFIX%\Scripts\meson setup builddir !MESON_OPTIONS!
if errorlevel 1 exit 1

:: print results of build configuration
%BUILD_PREFIX%\Scripts\meson configure builddir
if errorlevel 1 exit 1

ninja -v -C builddir -j %CPU_COUNT%
if errorlevel 1 exit 1

ninja -C builddir install -j %CPU_COUNT%
if errorlevel 1 exit 1
