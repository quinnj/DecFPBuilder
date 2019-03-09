# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "DecFP"
version = v"2.2.0" # 2.0 Update 2

# Collection of sources required to build DecFP
sources = [
    "https://www.netlib.org/misc/intel/IntelRDFPMathLib20U2.tar.gz" =>
    "93c0c78e0989df88f8540bf38d6743734804cef1e40706fd8fe5c6a03f79e173",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd IntelRDFPMathLib20U2
sed -i -e 's/^#if \(!defined _MSC_VER || defined __INTEL_COMPILER\)/#if !defined __ENABLE_BINARY80__ \&\& (\1)/' LIBRARY/src/bid_functions.h TESTS/test_bid_functions.h
cd LIBRARY
if [ "$nbits" == 64 ]; then
     _HOST_ARCH=x86_64
else
     _HOST_ARCH=x86
fi

if [[ $target == *"-w64-"* ]]; then
    make CC_NAME=cc _HOST_OS=Windows_NT AR_CMD="ar rv" _HOST_ARCH=$_HOST_ARCH CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
    $CC $LDFLAGS -shared -o libbid.$dlext *.obj
    mkdir -p $prefix/bin
    cp libbid.$dlext $prefix/bin/
else
    CFLAGS_OPT="-fPIC -fsigned-char -D__ENABLE_BINARY80__=0"
    if [[ $target == *"-musl"* ]]; then
        CFLAGS_OPT+=" -D__QNX__"
    elif [[ $target == *"freebsd"* ]]; then
        CFLAGS_OPT+=" -D__linux"
    fi
    make CC_NAME=cc CFLAGS_OPT="$CFLAGS_OPT" CFLAGS="$CFLAGS_OPT" _HOST_ARCH=$_HOST_ARCH CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
    $CC $LDFLAGS -shared -o libbid.$dlext *.o
    mkdir -p $prefix/lib
    cp libbid.$dlext $prefix/lib/
fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libbid", :libbid)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
