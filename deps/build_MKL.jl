using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libmkl_core", "mkl_core"], :libmkl_core),
    LibraryProduct(prefix, ["libmkl_rt", "mkl_rt"], :libmkl_rt),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaPackaging/Yggdrasil/releases/download/MKL-v2019.0.117"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:x86_64)   => ("$bin_prefix/MKL.v2019.0.117.x86_64-linux-gnu.tar.gz", "9a496908c05eccdb331218f4cf32229b024790b30bf7bc0ca0f5587e030d34e6"),
    Linux(:i686)     => ("$bin_prefix/MKL.v2019.0.117.i686-linux-gnu.tar.gz", "ccdce675bf48738f28878bc831231498c7c9560a94f756da8c114f664790ffee"),
    MacOS(:x86_64)   => ("$bin_prefix/MKL.v2019.0.117.x86_64-apple-darwin14.tar.gz", "605da525b16f61837bc35834f3a6ff90609b1d0a5f1606faa25bf45180ced6e9"),
    Windows(:x86_64) => ("$bin_prefix/MKL.v2019.0.117.x86_64-w64-mingw32.tar.gz", "0a9aaac254421fde0f26a95856b595deb8cce85d039050d8167293d049fd716d"),
    Windows(:i686)   => ("$bin_prefix/MKL.v2019.0.117.i686-w64-mingw32.tar.gz", "53cac3a29bbb2acdc383297c256e3b68b3d4712e1b83417226da4971582e80cd"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
