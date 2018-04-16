using BinaryBuilder

# Collection of sources required to build DecFP
sources = [
    "https://software.intel.com/sites/default/files/m/d/4/1/d/8/IntelRDFPMathLib20U1.tar.gz" =>
    "dcd56b70a57d783d31c73798cabc33d715d0fdca8465725e4eebfb9de88444dd",
]

# Bash recipe for building across all platforms
script = raw"""
if [ $target == "x86_64-w64-mingw32" ]; then

cd $WORKSPACE/srcdir
cd IntelRDFPMathLib20U1/LIBRARY/src/
wget https://raw.githubusercontent.com/weolar/miniblink49/master/vc6/include/crt/float.h
cd ..
make CC_NAME_INDEX=3 CC_INDEX=3 _HOST_OS=Windows_NT _HOST_ARCH=x86_64 _NUM_CPUS=1 CC=x86_64-w64-mingw32-gcc CFLAGS_OPT="-O2 -DBID_THREAD= -DBID_MS_FLAGS" CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
$CC -shared -o libbid.dll *.obj
mkdir $prefix/bin
cp libbid.dll $prefix/bin/.

elif [ $target == "i686-w64-mingw32" ]; then

cd $WORKSPACE/srcdir
cd IntelRDFPMathLib20U1/LIBRARY/src/
wget https://raw.githubusercontent.com/weolar/miniblink49/master/vc6/include/crt/float.h
cd ..
make CC_NAME_INDEX=3 CC_INDEX=3 _HOST_OS=Windows_NT _HOST_ARCH=x86 _NUM_CPUS=1 CC=i686-w64-mingw32-gcc CFLAGS_OPT="-O2 -DBID_THREAD= -DBID_MS_FLAGS" CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
$CC -shared -o libbid.dll *.obj
mkdir $prefix/bin
cp libbid.dll $prefix/bin/.

elif [ $target == "i686-linux-gnu" ]; then

cd $WORKSPACE/srcdir
cd IntelRDFPMathLib20U1/LIBRARY/
make _HOST_ARCH=i686 CC=gcc CFLAGS_OPT="-O2 -fPIC" CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
$CC -shared -o libbid.so *.o
mkdir $prefix/lib
cp libbid.* $prefix/lib/.

elif [ $target == "x86_64-apple-darwin14" ]; then

cd $WORKSPACE/srcdir
cd IntelRDFPMathLib20U1/LIBRARY/
make CC=gcc CFLAGS_OPT="-O2 -fPIC" CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
$CC -shared -o libbid.dylib *.o
mkdir $prefix/lib
cp libbid.* $prefix/lib/.

else

cd $WORKSPACE/srcdir
cd IntelRDFPMathLib20U1/LIBRARY/
make CC=gcc CFLAGS_OPT="-O2 -fPIC" CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
$CC -shared -o libbid.so *.o
mkdir $prefix/lib
cp libbid.* $prefix/lib/.

fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    # Linux(:aarch64, :glibc),
    # Linux(:armv7l, :glibc),
    # Linux(:powerpc64le, :glibc),
    MacOS(),
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
build_tarballs(ARGS, "DecFP", sources, script, platforms, products, dependencies)
