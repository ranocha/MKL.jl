module MKL

using MKL_jll

using LinearAlgebra

if Base.USE_BLAS64
    const MKLBlasInt = Int64
else
    const MKLBlasInt = Int32
end

@enum Threading begin
    THREADING_INTEL
    THREADING_SEQUENTIAL
    THREADING_PGI
    THREADING_GNU
    THREADING_TBB
end

@enum Interface begin
    INTERFACE_LP64
    INTERFACE_ILP64
    INTERFACE_GNU
end

function set_threading_layer(layer::Threading = THREADING_SEQUENTIAL)
    err = ccall((:MKL_Set_Threading_Layer, libmkl_rt), Cint, (Cint,), layer)
    err == -1 && throw(ErrorException("return value was -1"))
    return nothing
end

function set_interface_layer(interface = Base.USE_BLAS64 ? INTERFACE_ILP64 : INTERFACE_LP64)
    err = ccall((:MKL_Set_Interface_Layer, libmkl_rt), Cint, (Cint,), interface)
    err == -1 && throw(ErrorException("return value was -1"))
    return nothing
end

function __init__()
    if MKL_jll.is_available()
        set_interface_layer()
        if Sys.isapple()
            set_threading_layer(THREADING_SEQUENTIAL)
        else
            set_threading_layer(THREADING_INTEL)
        end
        BLAS.lbt_forward(libmkl_rt, clear=true)
    end
end

function mklnorm(x::Vector{Float64})
    ccall((:dnrm2_, libmkl_rt), Float64,
          (Ref{MKLBlasInt}, Ptr{Float64}, Ref{MKLBlasInt}),
          length(x), x, 1)
end

end # module
