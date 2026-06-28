using UniversalNumbers
using LinearAlgebra
using Test

# Tolerances matched to each posit's precision
const POSIT_ATOL = Dict(
    Posit{8,0}  => 0.15,
    Posit{8,1}  => 0.15,
    Posit{8,2}  => 0.15,
    Posit{12,1} => 0.02,
    Posit{16,1} => 0.01,
    Posit{16,2} => 0.01,
    Posit{19,2} => 1e-3,
    Posit{19,3} => 1e-3,
    Posit{32,2} => 1e-5,
    Posit{64,2} => 1e-10,
    Posit{64,3} => 1e-10,
)

const ALL_POSITS   = (Posit{8,0}, Posit{8,1}, Posit{8,2}, Posit{12,1},
                      Posit{16,1}, Posit{16,2}, Posit{19,2},
                      Posit{19,3}, Posit{32,2}, Posit{64,2}, Posit{64,3})
const WIDE_POSITS  = (Posit{12,1}, Posit{16,1}, Posit{16,2}, Posit{19,2},
                      Posit{19,3}, Posit{32,2}, Posit{64,2}, Posit{64,3})
const LA_POSITS    = (Posit{12,1}, Posit{16,1}, Posit{16,2}, Posit{19,2},
                      Posit{19,3}, Posit{32,2}, Posit{64,2}, Posit{64,3})
const HPREC_POSITS = (Posit{32,2}, Posit{64,2}, Posit{64,3})

@testset "Posit Support" begin

    # ------------------------------------------------------------------
    @testset "Arithmetic -- $T" for T in ALL_POSITS
        tol = POSIT_ATOL[T]
        a = T(2.0);  b = T(4.0)
        @test Float64(a + b) ≈ 6.0 atol=tol
        @test Float64(b - a) ≈ 2.0 atol=tol
        @test Float64(a * b) ≈ 8.0 atol=tol
        @test Float64(b / a) ≈ 2.0 atol=tol
        @test Float64(-a)    ≈ -2.0 atol=tol
        @test Float64(abs(T(-3.0))) ≈ 3.0 atol=tol
    end

    # ------------------------------------------------------------------
    @testset "Math functions -- $T" for T in WIDE_POSITS
        tol = POSIT_ATOL[T]
        @test Float64(sqrt(T(4.0)))  ≈ 2.0        atol=tol
        @test Float64(sqrt(T(2.0)))  ≈ sqrt(2.0)  atol=max(tol, 1e-4)
        @test Float64(sin(T(0.0)))   ≈ 0.0        atol=tol
        @test Float64(cos(T(0.0)))   ≈ 1.0        atol=tol
        @test Float64(exp(T(0.0)))   ≈ 1.0        atol=tol
        @test Float64(log(T(1.0)))   ≈ 0.0        atol=tol
        @test Float64(exp(log(T(2.0)))) ≈ 2.0     atol=max(tol*10, 1e-3)
    end

    # ------------------------------------------------------------------
    @testset "NaR (not-a-real) -- $T" for T in ALL_POSITS
        nar = T(NaN)
        @test isnan(nar)
        @test !isfinite(nar)
        @test nar == nar       # NaR equals itself (posit standard)
        @test !(nar < nar)
    end

    # ------------------------------------------------------------------
    @testset "Constants and predicates -- $T" for T in ALL_POSITS
        @test iszero(zero(T))
        @test isone(one(T))
        @test Float64(zero(T)) == 0.0
        @test Float64(one(T))  == 1.0
        @test floatmax(T) > floatmin(T) > zero(T)
        @test eps(T) > zero(T)
        @test !isnan(zero(T))
        @test !isnan(one(T))
    end

    # ------------------------------------------------------------------
    @testset "Adjacent values -- $T" for T in ALL_POSITS
        x = T(1.0)
        # Compare as posit values; 64-bit posits have sub-Float64 ULP spacing
        # so Float64 conversion would round adjacent values to the same number.
        @test nextfloat(x) > x
        @test prevfloat(x) < x
        @test prevfloat(nextfloat(x)) == x
        @test nextfloat(prevfloat(x)) == x
    end

    # ------------------------------------------------------------------
    @testset "Conversion and promotion -- $T" for T in WIDE_POSITS
        tol = POSIT_ATOL[T]
        p = T(3.14)
        @test Float64(p) ≈ 3.14 atol=max(tol, 1e-3)
        @test Float32(p) isa Float32
        # Posit + scalar promotes scalar to Posit
        r = T(1.0) + 1.5
        @test r isa T
        @test Float64(r) ≈ 2.5 atol=max(tol, 0.01)
    end

    # ------------------------------------------------------------------
    @testset "Comparisons -- $T" for T in ALL_POSITS
        a = T(1.0);  b = T(2.0)
        @test a < b
        @test b > a
        @test a <= a
        @test a == a
        @test a != b
    end

    # ------------------------------------------------------------------
    @testset "Vector norm ‖[3,4]‖ = 5 -- $T" for T in LA_POSITS
        tol = POSIT_ATOL[T]
        v = T.([3.0, 4.0])
        @test Float64(norm(v)) ≈ 5.0 atol=max(tol * 10, 0.01)
    end

    # ------------------------------------------------------------------
    @testset "Solve Ax=b 2x2 -- $T" for T in LA_POSITS
        tol = POSIT_ATOL[T]
        A = T.([4.0 1.0; 1.0 3.0])
        b = T.([1.0, 2.0])
        x = A \ b
        @test Float64(x[1]) ≈ 1/11 atol=max(tol * 100, 0.01)
        @test Float64(x[2]) ≈ 7/11 atol=max(tol * 100, 0.01)
    end

    # ------------------------------------------------------------------
    @testset "Solve Ax=b 3x3 tridiagonal -- $T" for T in HPREC_POSITS
        tol = POSIT_ATOL[T]
        A = T.([4.0 1.0 0.0; 1.0 4.0 1.0; 0.0 1.0 4.0])
        b = T.([1.0, 2.0, 1.0])
        x = A \ b
        r = b - A * x
        @test Float64(norm(r)) < max(tol * 100, 1e-4)
    end

    # ------------------------------------------------------------------
    @testset "Determinant -- $T" for T in LA_POSITS
        tol = POSIT_ATOL[T]
        A = T.([4.0 1.0; 1.0 3.0])    # det = 11
        @test Float64(det(A)) ≈ 11.0 atol=max(tol * 100, 0.05)
    end

    # ------------------------------------------------------------------
    @testset "Matrix inverse A·A⁻¹ ≈ I -- $T" for T in HPREC_POSITS
        tol = POSIT_ATOL[T]
        A = T.([4.0 1.0; 1.0 3.0])
        E = A * inv(A)
        @test Float64(E[1,1]) ≈ 1.0 atol=max(tol * 100, 1e-4)
        @test Float64(E[2,2]) ≈ 1.0 atol=max(tol * 100, 1e-4)
        @test Float64(E[1,2]) ≈ 0.0 atol=max(tol * 100, 1e-4)
        @test Float64(E[2,1]) ≈ 0.0 atol=max(tol * 100, 1e-4)
    end

    # ------------------------------------------------------------------
    @testset "Matrix and operator norms -- $T" for T in HPREC_POSITS
        tol = POSIT_ATOL[T]
        A   = T.([1.0 2.0; 3.0 4.0])
        ref = [1.0 2.0; 3.0 4.0]
        @test Float64(opnorm(A, 1))   ≈ opnorm(ref, 1)   rtol=0.01
        @test Float64(opnorm(A, Inf)) ≈ opnorm(ref, Inf) rtol=0.01
    end

    # ------------------------------------------------------------------
    @testset "Condition number κ₁ -- $T" for T in HPREC_POSITS
        A   = T.([4.0 1.0; 1.0 3.0])
        κ   = Float64(opnorm(A, 1)) * Float64(opnorm(inv(A), 1))
        ref = cond([4.0 1.0; 1.0 3.0], 1)
        @test κ ≈ ref rtol=0.05
    end

    # ------------------------------------------------------------------
    @testset "LU decomposition ‖PA − LU‖ -- $T" for T in HPREC_POSITS
        tol = POSIT_ATOL[T]
        A = T.([2.0 1.0 1.0; 4.0 3.0 3.0; 8.0 7.0 9.0])
        F = lu(A)
        @test Float64(norm(F.P * A - F.L * F.U)) < max(tol * 1000, 1e-4)
    end

    # ------------------------------------------------------------------
    @testset "QR decomposition ‖QR − A‖ -- $T" for T in HPREC_POSITS
        tol = POSIT_ATOL[T]
        A = T.([1.0 2.0; 3.0 4.0; 5.0 6.0])
        F = qr(A)
        @test Float64(norm(Matrix(F.Q) * F.R - A)) < max(tol * 1000, 1e-4)
    end

    # ------------------------------------------------------------------
    @testset "Dot product -- $T" for T in HPREC_POSITS
        tol = POSIT_ATOL[T]
        v = T.([1.0, 2.0, 3.0])
        w = T.([4.0, 5.0, 6.0])
        @test Float64(dot(v, w)) ≈ 32.0 atol=max(tol * 100, 1e-4)
    end

    # ------------------------------------------------------------------
    @testset "Random generation -- $T" for T in ALL_POSITS
        v = rand(T, 8)
        @test length(v) == 8
        @test eltype(v) <: T
        M = rand(T, 3, 3)
        @test size(M) == (3, 3)
        @test eltype(M) <: T
    end

    # ------------------------------------------------------------------
    @testset "Broadcasting -- $T" for T in WIDE_POSITS
        tol = POSIT_ATOL[T]
        v = T.([1.0, 2.0, 3.0])
        u = 2.0 .* v
        @test Float64(u[1]) ≈ 2.0 atol=max(tol * 10, 0.01)
        @test Float64(u[2]) ≈ 4.0 atol=max(tol * 10, 0.01)
        @test Float64(u[3]) ≈ 6.0 atol=max(tol * 10, 0.01)
        w = sin.(v)
        @test Float64(w[1]) ≈ sin(1.0) atol=max(tol * 10, 0.01)
    end

end
