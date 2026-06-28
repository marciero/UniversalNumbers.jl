using UniversalNumbers
using LinearAlgebra
using Test

@testset "Takum Support" begin
    @testset "Arithmetic (Takum{16})" begin
        a = Takum{16}(2.0)
        b = Takum{16}(4.0)

        @test Float64(a + b) ≈ 6.0 atol=0.01
        @test Float64(b - a) ≈ 2.0 atol=0.01
        @test Float64(a * b) ≈ 8.0 atol=0.01
        @test Float64(b / a) ≈ 2.0 atol=0.01
    end

    @testset "Linear Algebra (Takum{16})" begin
        # Using a very simple matrix
        A = Takum{16}.([
            1.0  0.0;
            0.0  1.0
        ])
        b = Takum{16}.([1.0, 2.0])
        x = A \ b
        @test Float64(x[1]) == 1.0
        @test Float64(x[2]) == 2.0

        # A bit more complex
        A2 = Takum{16}.([
            2.0  1.0;
            1.0  2.0
        ])
        b2 = Takum{16}.([3.0, 3.0])
        # Solution should be [1.0, 1.0]
        x2 = A2 \ b2
        println("Takum A2 \\ b2 solution: ", x2)
        @test Float64(x2[1]) ≈ 1.0 atol=0.01
        @test Float64(x2[2]) ≈ 1.0 atol=0.01
    end
end
