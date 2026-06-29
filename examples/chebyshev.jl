# Chebyshev nodes and interpolation properties with universal number types.
#
# To run from the root:
#   julia --project=. examples/chebyshev.jl
#
# Example taken from "Approximation Theory and Approximation Practice" 
#   by Lloyd N. Trefethen (see p. 28-29).

using UniversalNumbers
using LinearAlgebra

"""
    chebpts(n, kind=1; T=Float64)

Return `n` Chebyshev nodes on [-1, 1] of the given `kind`:
- `kind=1`: roots of T_n(x)      x_k = cos((2k-1)π / 2n)
- `kind=2`: extrema of T_{n-1}   x_k = cos((k-1)π / (n-1))
"""
function chebpts(n::Int, kind::Int = 1; T = Float64)
    kind == 1 && return T[cos((2k - 1) * π / (2n)) for k in 1:n]
    kind == 2 && return T[cos((k - 1)  * π / (n - 1)) for k in 1:n]
    error("kind must be 1 or 2")
end

"""
    diff(x, y)

Return the elementwise difference `x .- y` for two equal-length vectors.
"""
function diff(x::AbstractVector{T}, y::AbstractVector{T}) where T
    length(x) == length(y) || error("vectors must have the same length")
    x .- y
end

"""
    linscale(x, c, d)

Linearly map points `x` from [-1, 1] to [c, d].
"""
function linscale(x::AbstractVector{T}, c::Real, d::Real) where T
    c, d = T(c), T(d)
    [(d - c) / T(2) * xi + (d + c) / T(2) for xi in x]
end

"""
    meandistance(x)

Return the geometric mean of all pairwise distances |x_i - x_j|, i ≠ j.
Computed via log-sum to avoid overflow and the need for fractional exponentiation.
"""
function meandistance(x::AbstractVector{T}) where T
    n = length(x)
    dists = T[abs(x[i] - x[j]) for i in 1:n for j in 1:n if i != j]
    exp(sum(log.(dists)) / T(length(dists)))
end

# ------------------------------------------------------------------
# Demo
# ------------------------------------------------------------------
println("=== Chebyshev Nodes Demo ===\n")

n = 6

for T in (Float64, Posit{32,2}, Posit{64,2})
    println("[$T]")

    pts1 = chebpts(n, 1; T)
    pts2 = chebpts(n, 2; T)

    println("  1st-kind nodes: ", round.(Float64.(pts1), sigdigits=6))
    println("  2nd-kind nodes: ", round.(Float64.(pts2), sigdigits=6))

    # Scale 1st-kind nodes from [-1,1] to [0, π]
    scaled = linscale(pts1, 0, π)
    println("  Scaled to [0,π]: ", round.(Float64.(scaled), sigdigits=6))

    # Elementwise difference between 1st and 2nd kind (same length only when n matches)
    d = diff(pts1, pts2)
    println("  Diff (1st - 2nd): ", round.(Float64.(d), sigdigits=6))

    # Geometric mean pairwise distance
    gm = meandistance(pts1)
    println("  Geometric mean pairwise distance: ", round(Float64(gm), sigdigits=6))

    # Monic Chebyshev property: max|T_n(x)| on [-1,1] = 2^{1-n}
    monic_max = 2.0^(1 - n)
    println("  Monic Chebyshev bound 2^{1-n} = ", monic_max)

    println()
end
