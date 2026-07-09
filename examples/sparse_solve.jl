# Sparse linear solve across number formats.
#
# Builds a 1D Laplacian (sparse, symmetric positive definite) whose exact solution is
# the all-ones vector, casts it to each format, and solves with `A \ b`. The elimination
# runs in the chosen format's arithmetic -- the package's native sparse LU for the Posit
# cases -- so accuracy tracks precision: Float64 near machine epsilon, Posit{32,2} ~1e-7,
# Posit{16,1} visibly degraded. No Float64 detour, no external solver.
#
# Run with:  julia --project=examples examples/sparse_solve.jl

using UniversalNumbers, SparseArrays, LinearAlgebra

n  = 100
Af = spdiagm(-1 => -ones(n-1), 0 => 2.0 * ones(n), 1 => -ones(n-1))  # 1D Laplacian
bf = Af * ones(n)                                                     # exact solution: all ones

for T in (Float64, Posit{32,2}, Posit{16,1})
    A = T.(Af)          
    b = T.(bf)
    x = A \ b
    err = norm(Float64.(x) .- 1.0)
    println(rpad(string(T), 14), " ||x - 1|| = ", err)
end
