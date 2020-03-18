setlocal EnableDelayedExpansion
@echo on

:: meson options
:: (set pkg_config_path so deps in host env can be found)
set ^"MESON_OPTIONS=^
  --prefix="%LIBRARY_PREFIX%" ^
  --pkg-config-path="%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig" ^
  --wrap-mode=nofallback ^
  --buildtype=release ^
  --backend=ninja ^
 ^"

:: configure build using meson
%BUILD_PREFIX%\python.exe %BUILD_PREFIX%\Scripts\meson setup builddir !MESON_OPTIONS!
if errorlevel 1 exit 1

:: print results of build configuration
%BUILD_PREFIX%\python.exe %BUILD_PREFIX%\Scripts\meson configure builddir
if errorlevel 1 exit 1

ninja -v -C builddir -j %CPU_COUNT%
if errorlevel 1 exit 1

ninja -C builddir install -j %CPU_COUNT%
if errorlevel 1 exit 1
