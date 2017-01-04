type AFArray{T,N} <: AbstractArray{T,N}
    arr::af_array
    function AFArray(arr::af_array)
        @assert get_type(arr) == T "type mismatch: $(get_type(arr)) != $T"
        @assert get_numdims(arr) == N "dims mismatch: $(get_numdims(arr)) != $N"
        a = new(arr)
        finalizer(a, x -> release_array(x))
        a
    end
end

typealias AFVector{T} AFArray{T,1}
typealias AFMatrix{T} AFArray{T,2}
typealias AFVolume{T} AFArray{T,3}
typealias AFTensor{T} AFArray{T,4}

export AFArray, AFVector, AFMatrix, AFVolume, AFTensor

import Base: convert, copy, deepcopy_internal, broadcast

convert{T1,T2,N}(::Type{AFArray{T1}}, a::AFArray{T2,N}) = recast_array(AFArray{T1}, a)::AFArray{T1,N}
convert{T1,T2,N}(::Type{AFArray{T1,N}}, a::AFArray{T2,N}) = recast_array(AFArray{T1}, a)::AFArray{T1,N}
convert{T,N}(::Type{Array{T,N}}, a::AFArray{T,N}) = convert_array(a)
convert{T,N}(::Type{AFArray{T,N}}, a::AbstractArray{T,N}) = convert_array(a)
convert{T,N}(::Type{Array}, a::AFArray{T,N}) = convert_array(a)::Array{T,N}
convert{T,N}(::Type{AFArray}, a::AbstractArray{T,N}) = convert_array(a)::AFArray{T,N}
deepcopy_internal{T,N}(a::AFArray{T,N}, d::ObjectIdDict) = haskey(d, a) ? d[a]::AFArray{T,N} : copy(a)

import Base: size, eltype, ndims, abs, acos, acosh, asin, asinh, atan, atan2, atanh, cbrt, ceil, clamp, cos, cosh
import Base: count, cov, det, div, dot, erf, erfc, exp, expm1, factorial, fft, floor, gradient, hypot
import Base: identity, ifft, imag, isinf, isnan, join, lgamma, log, log10, log1p, log2, lu, maximum, mean, median
import Base: minimum, mod, norm, prod, qr, randn, range, rank, real, rem, replace, round, scale, select, show
import Base: signbit, sin, sinh, sort, sqrt, sub, sum, svd, tan, tanh, transpose, trunc, var, any, all

eltype{T,N}(a::AFArray{T,N}) = T
ndims{T,N}(a::AFArray{T,N}) = N
size(a::AFVector) = (s = get_dims(a); (s[1],))
size(a::AFMatrix) = (s = get_dims(a); (s[1],s[2]))
size(a::AFVolume) = (s = get_dims(a); (s[1],s[2],s[3]))
size(a::AFTensor) = get_dims(a)
any(a::AFArray) = any_true_all(a)[1] == 1
all(a::AFArray) = all_true_all(a)[1] == 1
sum{T<:Real,N}(a::AFArray{T,N}) = T(sum_all(a)[1])
sum{T<:Complex,N}(a::AFArray{T,N}) = T(sum_all(a)...)

function broadcast(f, A::AFArray, Bs...)
    old, bcast[] = bcast[], true
    try
        return f(A, Bs...)
    finally
        bcast[] = old
    end
end

import Base: /, *, +, -

/(a::AFArray, b::AFArray) = div(a, b, bcast[])
*(a::Real, b::AFArray)    = mul(AFArray([a]) ,b, true)
*(a::AFArray, b::AFArray) = mul(a, b, bcast[])
+(a::Real, b::AFArray)    = add(AFArray([a]), b, true)
+(a::AFArray, b::AFArray) = add(a, b, bcast[])
-(a::Real, b::AFArray)    = sub(AFArray([a]), b, true)
-(a::AFArray, b::AFArray) = sub(a, b, bcast[])
-{T,N}(a::AFArray{T,N})   = T(0) - a
