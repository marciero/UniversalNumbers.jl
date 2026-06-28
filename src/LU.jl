# See LICENSE file for copyright and license details.
module LU

using LinearAlgebra
using SparseArrays

# Unpivoted left-looking LU. Assumes a nonzero diagonal (see solve, which
# supplies a row/column permutation that guarantees it).
function lu(A::SparseMatrixCSC{T, <:Integer}) where {T <: AbstractFloat}
	n = size(A, 1)
	L = spdiagm(ones(T, n))     # unit lower triangular
	U = spzeros(T, n, n)

	for j in 1:n
		# Augmented matrix is unit lower triangular; wrap it so the solve uses
		# forward-substitution rather than recursing into our sparse \.
		M = [L[:, 1:(j - 1)] [
			spzeros(T, j - 1, n - j + 1)
			spdiagm(ones(T, n - j + 1))
		]]
		x = LowerTriangular(M) \ Vector(A[:, j])
		U[1:j, j] = x[1:j]
		L[(j + 1):n, j] = x[(j + 1):n] ./ x[j]
	end

	# Assigning dense column slices stores zeros structurally; compact them out.
	dropzeros!(L)
	dropzeros!(U)

	return LowerTriangular(L), UpperTriangular(U)
end

function solve(
	A::AbstractMatrix,
	b::AbstractVector,
	permutation_rows::AbstractVector,
	permutation_columns::AbstractVector,
)
	# Row-equilibration scaling, then apply row (P) and column (S) permutations:
	# PCAS = (C A)[p, q] has a nonzero diagonal, so unpivoted LU is safe.
	C = Diagonal(1 ./ sum(abs.(A); dims = 2)[:])
	PCAS = (C * A)[permutation_rows, permutation_columns]
	L, U = LU.lu(PCAS)

	# Solve LU z = y with y = (C b)[p], then undo the column permutation (x = S z).
	y = (C * b)[permutation_rows]
	w = L \ y
	z = U \ w
	return z[invperm(permutation_columns)]
end

end