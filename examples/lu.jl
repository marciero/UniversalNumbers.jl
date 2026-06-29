using UniversalNumbers
using LinearAlgebra
using SparseArrays
using MatrixDepot

T = Posit{16,2};

A = SparseMatrixCSC{T, Int64}(matrixdepot(sp(6))) # ID=6 is arc130 (Harwell-Boeing collection)
L, U = UniversalNumbers.LU.lu(A);

# and we have: 
L*U â‰ˆ A
