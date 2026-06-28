using UniversalNumbers
using LinearAlgebra

# Define your number type
T = Posit{32,2}

# Define a Matrix A.  
# The following matrix taken from:
# "A collection of matrices for testing computational algorithms" 
# by Gregory and Karney (see p. 29).  Inverse is known (see below).  
A = T.([1.0 -2 3 1; -2 1 -2 -1; 3 -2 1 5; 1 -1 5 3]);
LU = lu(A)

x = ones(T,4)
b = T.([3, -4, 7, 8])

# Solve Ax = b
x_computed = A\b
norm(A*x_computed - b)
norm(x_computed - x)


# Solve using LU 
x_computed_LU = LU\b


# Inverse 
Ai = T(1/52)*T.([-15.0 -38 -1 -6; -38 -20 -6 16; -1 -6 -7 10; -6 16 10 8])
norm(A*Ai - I)

# Solve using the inverse
x_computed_inv = Ai*b
norm(A*x_computed_inv - b)
norm(x_computed_inv - x)

# Some matrix properties (note, condition, egien, and svd convert to Float64, else error).
cond_A = cond(Float64.(A))
cond_Ai = cond(Float64.(Ai))
norm(A,2)
norm(Ai,2)
cond(Float64.(A)) ≈ norm(A,2)*norm(Ai,2)
eigen(Float64.(A))
svd(Float64.(A))