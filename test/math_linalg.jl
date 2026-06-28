using UniversalNumbers
using Test
using LinearAlgebra

@testset "UniversalNumbers Parametric Interface" begin
    @testset "Arithmetic (Posit{16, 1})" begin
        # New parametric syntax
        a = Posit{16, 1}(1.5)
        b = Posit{16, 1}(2.5)
        @test Float64(a + b) == 4.0
        @test Float64(a - b) == -1.0
        @test Float64(a * b) == 3.75
        @test Float64(b / a) ≈ 1.6666666666666667 atol=1e-3
    end

    @testset "Custom Type (Posit{19, 3})" begin
        # Testing the first "custom" type added via the registry
        p = Posit{19, 3}(3.14159)
        @test Float64(p) ≈ 3.14159 atol=1e-4

        a = Posit{19, 3}(1.0)
        b = Posit{19, 3}(2.0)
        @test Float64(a + b) == 3.0
    end

    @testset "CFloat and LNS" begin
        # Verified that the registry handles these too
        f = CFloat{8, 2}(1.5)
        @test Float64(f) == 1.5

        l = LNS{16, 5}(2.0)
        @test Float64(l) == 2.0
    end

    @testset "Float64-fallback math functions" begin
        # tan and the exp/log family are provided via Float64 round-trip.
        for T in (Posit{32, 2}, Takum{16}, CFloat{24, 5})
            x = T(0.5)
            y = T(2.0)
            @test Float64(tan(x))   ≈ tan(0.5)   atol = 1e-2
            @test Float64(atan(x))  ≈ atan(0.5)  atol = 1e-2
            @test Float64(asin(x))  ≈ asin(0.5)  atol = 1e-2
            @test Float64(acos(x))  ≈ acos(0.5)  atol = 1e-2
            @test Float64(sinh(x))  ≈ sinh(0.5)  atol = 1e-2
            @test Float64(cosh(x))  ≈ cosh(0.5)  atol = 1e-2
            @test Float64(tanh(x))  ≈ tanh(0.5)  atol = 1e-2
            @test Float64(exp2(y))  ≈ 4.0        atol = 1e-2
            @test Float64(exp10(x)) ≈ exp10(0.5) atol = 1e-2
            @test Float64(expm1(x)) ≈ expm1(0.5) atol = 1e-2
            @test Float64(log2(y))  ≈ 1.0        atol = 1e-2
            @test Float64(log10(y)) ≈ log10(2.0) atol = 1e-2
            @test Float64(log1p(x)) ≈ log1p(0.5) atol = 1e-2
            @test Float64(cbrt(T(8.0))) ≈ 2.0    atol = 1e-2
        end
        # tan identity: tan(x) ≈ sin(x)/cos(x)
        let x = Posit{32, 2}(0.7)
            @test Float64(tan(x)) ≈ Float64(sin(x)) / Float64(cos(x)) atol = 1e-5
        end
    end

    @testset "Native Comparisons" begin
        # Testing that we don't lose precision in comparisons
        p1 = Posit{32, 2}(1.0000001)
        p2 = Posit{32, 2}(1.0000002)
        @test p1 < p2
        @test p1 != p2
    end

    @testset "Linear Algebra" begin
        A = [Posit{16, 1}(1.0) Posit{16, 1}(2.0);
             Posit{16, 1}(3.0) Posit{16, 1}(4.0)]
        v = [Posit{16, 1}(1.0), Posit{16, 1}(1.0)]
        res = A * v
        @test Float64(res[1]) == 3.0
        @test Float64(res[2]) == 7.0
    end
end
