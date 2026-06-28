using UniversalNumbers
using LinearAlgebra
using Test

@testset "Advanced Linear Algebra (LU)" begin
    @testset "LU Decomposition (Posit{32, 2})" begin
        # 3x3 Matrix
        A = Posit{32, 2}.([
            4.0  1.0  2.0;
            1.0  5.0  3.0;
            2.0  3.0  6.0
        ])

        # Test basic Matrix operations first
        @test eltype(A) <: Posit{32, 2}

        # Attempt LU
        println("Attempting LU decomposition...")
        try
            F = lu(A)
            println("LU successful!")

            # Verify L * U ≈ P * A
            @test Float64.(F.L * F.U) ≈ Float64.(F.P * A) atol=1e-6
        catch e
            println("LU failed with error: ", e)
            rethrow(e)
        end
    end

    @testset "Solving Linear Systems" begin
        A = Posit{32, 2}.([
            4.0  1.0;
            1.0  3.0
        ])
        b = Posit{32, 2}.([1.0, 2.0])

        # Solve Ax = b using \ (which often uses LU)
        x = A \ b

        # Verify A * x ≈ b
        @test Float64.(A * x) ≈ Float64.(b) atol=1e-6
    end
end
