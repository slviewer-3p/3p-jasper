#!/usr/bin/env bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

if [ -z "$AUTOBUILD" ] ; then 
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

stage="$(pwd)/stage"
src="$(pwd)/jasper"

source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

build=${AUTOBUILD_BUILD_ID:=0}

pushd "$stage"
    case "$AUTOBUILD_PLATFORM" in
        windows*)
            load_vsvars

			cmake -DCMAKE_C_FLAGS="/arch:AVX"  -DJAS_ENABLE_SHARED=OFF -G "${AUTOBUILD_WIN_CMAKE_GEN}" -S `cygpath -w ${src}`
			cmake --build . --config Release
			mkdir -p lib/release/
			mkdir -p include

			cp src/libjasper/jasper.lib lib/release/
			cp -a ${src}/src/libjasper/include/* include/
			cp -a src/libjasper/include/* include/
			cat include/jasper/jas_config.h | gawk '/JAS_VERSION /{ print $3}' | tr -d '"' > VERSION.txt

			;;
		
        darwin64)
			cmake -DJAS_ENABLE_SHARED=OFF -DCMAKE_OSX_ARCHITECTURES="x86_64" -DJAS_ENABLE_LIBJPEG=OFF  -S ${src}
			cmake --build . --config Release
			mkdir -p lib/release/
			mkdir -p include

			cp src/libjasper/libjasper.a lib/release/
			cp -a ${src}/src/libjasper/include/* include/
			cp -a src/libjasper/include/* include/
			cat include/jasper/jas_config.h | awk '/JAS_VERSION /{ print $3}' | tr -d '"' > VERSION.txt
		   
			;;
        linux64)
			cmake -DJAS_ENABLE_SHARED=OFF -DCMAKE_OSX_ARCHITECTURES="x86_64" -DJAS_ENABLE_LIBJPEG=OFF  -S ${src}
			cmake --build . --config Release
			mkdir -p lib/release/
			mkdir -p include

			cp src/libjasper/libjasper.a lib/release/
			cp -a ${src}/src/libjasper/include/* include/
			cp -a src/libjasper/include/* include/
			cat include/jasper/jas_config.h | awk '/JAS_VERSION /{ print $3}' | tr -d '"' > VERSION.txt
		   
			;;

	*)
	    echo "Unsupported platform"
	    exit 1
    esac
    mkdir -p "$stage/LICENSES"
    cp ${src}/LICENSE.txt "$stage/LICENSES/jasper.txt"
popd
