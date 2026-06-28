using UniversalNumbers
using LinearAlgebra
using Test

@testset "LNS Support" begin
    @testset "Arithmetic (LNS{16, 5})" begin
        # 16 bits, 5 fractional bits
        a = LNS{16, 5}(2.0)
        b = LNS{16, 5}(4.0)

        @test Float64(a + b) ≈ 6.0 atol=0.1
        @test Float64(b - a) ≈ 2.0 atol=0.1
        @test Float64(a * b) ≈ 8.0 atol=0.1
        @test Float64(b / a) ≈ 2.0 atol=0.1
    end

    @testset "Math Functions (LNS{16, 5})" begin
        l = LNS{16, 5}(1.0)
        @test Float64(exp(l)) ≈ exp(1.0) atol=0.1
        @test Float64(sqrt(LNS{16, 5}(4.0))) ≈ 2.0 atol=0.1
    end

    @testset "Linear Algebra (LNS{16, 5})" begin
        A = LNS{16, 5}.([
            4.0  1.0;
            1.0  3.0
        ])
        b = LNS{16, 5}.([1.0, 2.0])

        # Solve Ax = b
        x = A \ b

        # Verify A * x ≈ b
        res = A * x
        @test Float64(res[1]) ≈ 1.0 atol=0.1
        @test Float64(res[2]) ≈ 2.0 atol=0.1
    end

    @testset "Arithmetic (LNS{32, 16})" begin
        # 32 bits, 16 fractional bits (much higher precision)
        a = LNS{32, 16}(2.0)
        b = LNS{32, 16}(4.0)

        @test Float64(a + b) ≈ 6.0 atol=1e-5
        @test Float64(b - a) ≈ 2.0 atol=1e-5
        @test Float64(a * b) ≈ 8.0 atol=1e-5
        @test Float64(b / a) ≈ 2.0 atol=1e-5
    end

    @testset "Math Functions (LNS{32, 16})" begin
        l = LNS{32, 16}(1.0)
        @test Float64(exp(l)) ≈ exp(1.0) atol=1e-4
        @test Float64(sqrt(LNS{32, 16}(4.0))) ≈ 2.0 atol=1e-5
    end
end
