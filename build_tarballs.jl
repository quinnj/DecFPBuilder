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

elif [ $target == "armv7l-linux-gnu" ]; then

cd $WORKSPACE/srcdir
cd IntelRDFPMathLib20U1
sed -i -e 's/^#if \(!defined _MSC_VER || defined __INTEL_COMPILER\)/#if !defined __ENABLE_BINARY80__ \&\& (\1)/' LIBRARY/src/bid_functions.h TESTS/test_bid_functions.h
cd LIBRARY
make _HOST_ARCH=i686 CC=gcc CFLAGS_OPT="-O2 -fPIC -fsigned-char -D__ENABLE_BINARY80__=0" CALL_BY_REF=0 GLOBAL_RND=1 GLOBAL_FLAGS=1 UNCHANGED_BINARY_FLAGS=1
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
    Linux(:armv7l, :glibc),
    # Linux(:powerpc64le, :glibc),
    MacOS(),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = Product[
    LibraryProduct(prefix, "libbid", :libbid)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Parse out some command-line arguments
BUILD_ARGS = ARGS

# This sets whether we should build verbosely or not
verbose = "--verbose" in BUILD_ARGS
BUILD_ARGS = filter!(x -> x != "--verbose", BUILD_ARGS)

# This flag skips actually building and instead attempts to reconstruct a
# build.jl from a GitHub release page.  Use this to automatically deploy a
# build.jl file even when sharding targets across multiple CI builds.
only_buildjl = "--only-buildjl" in BUILD_ARGS
BUILD_ARGS = filter!(x -> x != "--only-buildjl", BUILD_ARGS)

if !only_buildjl
    # If the user passed in a platform (or a few, comma-separated) on the
    # command-line, use that instead of our default platforms
    if length(BUILD_ARGS) > 0
        platforms = platform_key.(split(BUILD_ARGS[1], ","))
    end
    info("Building for $(join(triplet.(platforms), ", "))")

    # Build the given platforms using the given sources
    autobuild(pwd(), "DecFP", platforms, sources, script, products;
                                      dependencies=dependencies, verbose=verbose)
else
    # If we're only reconstructing a build.jl file on Travis, grab the information and do it
    if !haskey(ENV, "TRAVIS_REPO_SLUG") || !haskey(ENV, "TRAVIS_TAG")
        error("Must provide repository name and tag through Travis-style environment variables!")
    end
    repo_name = ENV["TRAVIS_REPO_SLUG"]
    tag_name = ENV["TRAVIS_TAG"]
    product_hashes = product_hashes_from_github_release(repo_name, tag_name; verbose=verbose)
    bin_path = "https://github.com/$(repo_name)/releases/download/$(tag_name)"
    dummy_prefix = Prefix(pwd())
    print_buildjl(pwd(), products(dummy_prefix), product_hashes, bin_path)

    if verbose
        info("Writing out the following reconstructed build.jl:")
        print_buildjl(STDOUT, product_hashes; products=products(dummy_prefix), bin_path=bin_path)
    end
end
