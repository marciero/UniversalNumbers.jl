using UniversalNumbers
using Test
using Random

@testset "Broadcasting and Array Support" begin
    @testset "Random Generation" begin
        # rand(Type, dims...)
        A = rand(Posit{16, 1}, 5, 5)
        @test size(A) == (5, 5)
        @test eltype(A) <: UniversalNumber
        @test all(0.0 .<= Float64.(A) .<= 1.0)

        # Another type
        B = rand(CFloat{8, 2}, 10)
        @test length(B) == 10
        @test eltype(B) <: UniversalNumber
    end

    @testset "Broadcasting" begin
        A = rand(Posit{16, 1}, 3, 3)

        # Binary op with scalar (promotion)
        B = A .+ 1.0
        @test eltype(B) <: UniversalNumber
        @test Float64(B[1,1]) ≈ Float64(A[1,1]) + 1.0 atol=1e-3

        # Math function broadcasting
        S = sin.(A)
        @test eltype(S) <: UniversalNumber
        @test Float64(S[1,1]) ≈ sin(Float64(A[1,1])) atol=1e-3

        # In-place broadcasting
        A .= A .* 2.0
        @test all(Float64.(A) .>= 0.0)
    end
end
