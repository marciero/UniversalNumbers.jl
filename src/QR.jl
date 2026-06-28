# See LICENSE file for copyright and license details.
# Laslo Hunhold (see: https://github.com/takum-arithmetic/MuFoLAB/blob/master/src/QR.jl)

module QR

using LinearAlgebra
using SparseArrays

import LinearAlgebra: qr

export HouseholderReflection, qr_householder, qr_givens, qr, qr_solve

@kwdef struct HouseholderReflection
	normal_vector::AbstractVector{<:AbstractFloat}
	indices::Vector{Int}
end

# We overload the constructor with this function, that takes a full
# column and the index of the diagonal element to yield a householder
# reflection that maps all the non-zero entries below the diagonal to zero
function get_householder_reflection_and_lambda(;
	column::AbstractVector{T},
	diagonal_index::Int,
) where {T <: AbstractFloat}
	# identify the non-zero indices in the column and remove all which
	# are smaller than the diagonal index (we won't touch them)
	indices = filter!(i -> (i > diagonal_index), findall(!iszero, column))

	# re-add the diagonal index
	prepend!(indices, diagonal_index)

	# catch the special case where indices is empty (all other cases
	# work seamlessly). Also, just for convenience, catch the
	# case where length(indices) == 1 and indices[1] == diagonal_index,
	# because then the reflection would be trivial, too.
	if isempty(indices) || (length(indices) == 1 && indices[1] == diagonal_index)
		return nothing, zero(T)
	end

	# filter out the target vector from the column
	target = column[indices]

	# determine lambda, which is simply the norm of the target vector
	# multiplied with the sign of -target[1] to avoid numerical
	# cancellation (by convention we say sign(0)=1)
	lambda = (-target[1] >= 0) ? norm(target, 2) : -norm(target, 2)

	# The normal vector is the normalised result of
	# (target - (lambda,0,...,0)).
	raw_normal_vector = target
	raw_normal_vector[1] -= lambda
	normal_vector = raw_normal_vector ./ norm(raw_normal_vector, 2)

	# Return the reflection and lambda
	return HouseholderReflection(; normal_vector = normal_vector, indices = indices),
	lambda
end

function Base.:*(
	reflection::HouseholderReflection,
	A::AbstractVecOrMat{T},
) where {T <: AbstractFloat}
	M = copy(A)
	M[reflection.indices, :] -=
		(T(2.0) .* reflection.normal_vector) *
		(reflection.normal_vector' * M[reflection.indices, :])
	return M
end

function Base.:*(Q::Vector{HouseholderReflection}, A::AbstractVecOrMat{T}) where {T <: AbstractFloat}
	#
	# It holds
	#
	#    Q = reflection_1 * ... * reflection_n
	#
	# and thus
	#
	#    Q * A = reflection_1 * ... * reflection_n * A
	#
	# so we first apply reflection n from the left, then n-1, etc.
	#
	M = copy(A)
	for i in reverse(1:length(Q))
		M = Q[i] * M
	end
	return M
end

# given we only work with real numbers this is fine
Base.adjoint(reflection::HouseholderReflection) = reflection

#
# It holds
#
#    Q = reflection_1 * ... * reflection_n
#
# and, making use of the fact that Householder matrices are symmetric,
#
#    Q^T = (reflection_1 * ... * reflection_n)^T
#        = reflection_n^T * ... * reflection_1^T
#        = reflection_n * ... * reflection_1
#
Base.adjoint(Q::Vector{HouseholderReflection}) = reverse(Q)

# Dense Householder QR. Q is returned as a Vector{HouseholderReflection};
# Q * X applies it and Q' * X applies its transpose (overloaded *).
function qr_householder(A::AbstractMatrix{T}) where {T <: AbstractFloat}
	R = copy(A)
	Q = HouseholderReflection[]

	for column_index in 1:size(R, 2)
		reflection, lambda = get_householder_reflection_and_lambda(;
			column = R[:, column_index],
			diagonal_index = column_index,
		)

		if reflection == nothing
			continue          # column already zero below the diagonal
		else
			# Set the diagonal to lambda, zero the rest of the column, and
			# apply the reflection to the remaining (right-hand) columns.
			R[reflection.indices, column_index] .= zero(T)
			R[column_index, column_index] = lambda
			R[:, (column_index + 1):end] =
				reflection *
				R[:, (column_index + 1):end]
			push!(Q, reflection)
		end
	end

	return Q, R
end

# Sparse Givens QR. Returns (Qrot, R) with the lazy rotation Qrot satisfying
# adjoint(Qrot) * R = A. Use qr(A) for an explicit Q, or qr_solve to solve.
function qr_givens(A::SparseMatrixCSC{T, <:Integer}) where {T <: AbstractFloat}
	R = copy(A)
	Q = LinearAlgebra.Rotation{T}([])

	for j in 1:(R.n)
		nonzero_indices = filter(ind -> (ind > j), R[:, j].nzind)

		# Bottom-up: cancel each subdiagonal entry against the one above it
		# (or against the diagonal for the topmost).
		for m in reverse(1:length(nonzero_indices))
			top_index    = (m == 1) ? j : nonzero_indices[m - 1]
			bottom_index = nonzero_indices[m]

			g = LinearAlgebra.givens(
				R[top_index, j],
				R[bottom_index, j],
				top_index,
				bottom_index,
			)

			Q = Q * g[1]
			R = g[1] * R
			R[bottom_index, j] = 0.0
		end
	end

	dropzeros!(R)

	return Q, UpperTriangular(R)
end

# qr(A): explicit (Q, R) with Q * R = A (Q a plain Matrix), materialising the
# orthogonal factor from qr_givens. Float64 sparse qr stays with SPQR, whose
# concrete-eltype method is more specific than this AbstractFloat one.
function qr(A::SparseMatrixCSC{T, <:Integer}) where {T <: AbstractFloat}
	Qrot, R = qr_givens(A)
	n = size(A, 1)
	Q = lmul!(adjoint(Qrot), Matrix{T}(I, n, n))
	return (; Q, R)
end

# Solve A x = b via Givens QR without forming Q: apply each rotation to the
# right-hand side as it is applied to R (giving G*b, with G*A = R), then a single
# back-substitution x = R \ (G*b). Avoids the lazy Rotation, whose adjoint is
# unreliable for non-BLAS element types.
function qr_solve(A::SparseMatrixCSC{T, <:Integer}, b::AbstractVector) where {T <: AbstractFloat}
	R = copy(A)
	c = Vector{T}(copy(b))

	for j in 1:(R.n)
		nonzero_indices = filter(ind -> (ind > j), R[:, j].nzind)

		for m in reverse(1:length(nonzero_indices))
			top_index    = (m == 1) ? j : nonzero_indices[m - 1]
			bottom_index = nonzero_indices[m]

			g = LinearAlgebra.givens(
				R[top_index, j],
				R[bottom_index, j],
				top_index,
				bottom_index,
			)

			# Same rotation applied to both R and the right-hand side
			R = g[1] * R
			R[bottom_index, j] = zero(T)
			c = g[1] * c
		end
	end

	dropzeros!(R)

	return UpperTriangular(R) \ c
end

function solve(
	A::AbstractMatrix,
	b::AbstractVector,
	permutation_rows::AbstractVector,
	permutation_columns::AbstractVector,
)
	# PAS = A[p, q] with a fill-reducing reordering, then x = S (R \ Q' P b).
	PAS = A[permutation_rows, permutation_columns]
	Q, R = QR.qr_householder(PAS)
	z = Q' * b[permutation_rows]
	return (R \ z)[invperm(permutation_columns)]
end

end