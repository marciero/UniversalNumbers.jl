using UniversalNumbers
using LinearAlgebra
using Test

const LA_ATOL = Dict(
    Posit{32,2} => 1e-4,
    Takum{32}   => 1e-2,
    LNS{32,16}  => 1e-3,
)

const LA_TYPES = (Posit{32,2}, Takum{32}, LNS{32,16})

@testset "Linear Algebra -- cross-family" begin

    @testset "Solve Ax=b 2×2 -- $T" for T in LA_TYPES
        tol = LA_ATOL[T]
        A = T.([4.0 1.0; 1.0 3.0])
        b = T.([1.0, 2.0])
        x = A \ b
        @test Float64(x[1]) ≈ 1/11 atol=tol
        @test Float64(x[2]) ≈ 7/11 atol=tol
    end

    @testset "Solve Ax=b 3×3 tridiagonal -- $T" for T in (Posit{32,2}, Takum{32})
        tol = LA_ATOL[T]
        A = T.([4.0 1.0 0.0; 1.0 4.0 1.0; 0.0 1.0 4.0])
        b = T.([1.0, 2.0, 1.0])
        x = A \ b
        @test Float64(norm(b - A * x)) < tol * 100
    end

    @testset "Vector norm ‖[3,4]‖ = 5 -- $T" for T in LA_TYPES
        tol = LA_ATOL[T]
        v = T.([3.0, 4.0])
        @test Float64(norm(v)) ≈ 5.0 atol=tol
    end

    @testset "Operator norms -- $T" for T in LA_TYPES
        tol = LA_ATOL[T]
        A   = T.([1.0 2.0; 3.0 4.0])
        ref = [1.0 2.0; 3.0 4.0]
        @test Float64(opnorm(A, 1))   ≈ opnorm(ref, 1)   rtol=0.05
        @test Float64(opnorm(A, Inf)) ≈ opnorm(ref, Inf) rtol=0.05
    end

    @testset "Condition number κ₁ -- $T" for T in (Posit{32,2}, Takum{32})
        A   = T.([4.0 1.0; 1.0 3.0])
        κ   = Float64(opnorm(A, 1)) * Float64(opnorm(inv(A), 1))
        ref = cond([4.0 1.0; 1.0 3.0], 1)
        @test κ ≈ ref rtol=0.05
    end

    @testset "Determinant -- $T" for T in LA_TYPES
        tol = LA_ATOL[T]
        A = T.([4.0 1.0; 1.0 3.0])    # det = 11
        @test Float64(det(A)) ≈ 11.0 atol=tol * 100
    end

    @testset "Matrix inverse A·A⁻¹ ≈ I -- $T" for T in (Posit{32,2}, Takum{32})
        tol = LA_ATOL[T]
        A = T.([4.0 1.0; 1.0 3.0])
        E = A * inv(A)
        @test Float64(E[1,1]) ≈ 1.0 atol=tol
        @test Float64(E[2,2]) ≈ 1.0 atol=tol
        @test Float64(E[1,2]) ≈ 0.0 atol=tol
        @test Float64(E[2,1]) ≈ 0.0 atol=tol
    end

    @testset "LU decomposition ‖PA − LU‖ -- $T" for T in (Posit{32,2}, Takum{32})
        tol = LA_ATOL[T]
        A = T.([2.0 1.0 1.0; 4.0 3.0 3.0; 8.0 7.0 9.0])
        F = lu(A)
        @test Float64(norm(F.P * A - F.L * F.U)) < tol * 100
    end

    @testset "QR decomposition ‖QR − A‖ -- $T" for T in (Posit{32,2},)
        tol = LA_ATOL[T]
        A = T.([1.0 2.0; 3.0 4.0; 5.0 6.0])
        F = qr(A)
        @test Float64(norm(Matrix(F.Q) * F.R - A)) < tol * 100
    end

    @testset "Dot product -- $T" for T in LA_TYPES
        tol = LA_ATOL[T]
        v = T.([1.0, 2.0, 3.0])
        w = T.([4.0, 5.0, 6.0])
        @test Float64(dot(v, w)) ≈ 32.0 atol=tol * 100
    end

    @testset "Scalar broadcast -- $T" for T in LA_TYPES
        tol = LA_ATOL[T]
        v = T.([1.0, 2.0, 3.0])
        u = 2.0 .* v
        @test Float64(u[1]) ≈ 2.0 atol=tol
        @test Float64(u[2]) ≈ 4.0 atol=tol
        @test Float64(u[3]) ≈ 6.0 atol=tol
    end

end
