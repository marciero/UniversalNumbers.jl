using UniversalNumbers
using Test

@testset "Bit inspection (printbits / about)" begin

    @testset "printbits does not throw -- $T" for (T, val) in [
        (Posit{8,0},   1.5),
        (Posit{16,1},  1.5),
        (Posit{32,2},  3.14159),
        (CFloat{8,2},  1.5),
        (CFloat{24,5}, 3.14159),
        (LNS{16,5},    1.5),
        (LNS{32,16},   3.14159),
        (Takum{16},    1.5),
        (Takum{32},    3.14159),
        (BF16,         1.5),
        (DD,           3.14159),
    ]
        @test (redirect_stdout(devnull) do; printbits(T(val)); end; true)
    end

    @testset "printbits NaR -- Posit{16,1}" begin
        @test (redirect_stdout(devnull) do; printbits(Posit{16,1}(NaN)); end; true)
    end

    @testset "about writes non-empty output -- $T" for (T, val) in [
        (Posit{16,1},  1.5),
        (Posit{32,2},  3.14159),
        (CFloat{24,5}, 1.5),
        (Takum{16},    1.5),
        (BF16,         1.5),
    ]
        buf = IOBuffer()
        about(T(val), buf)
        @test length(take!(buf)) > 0
    end

    @testset "raw bits accessible via .data" begin
        x = Posit{16,1}(0.0)
        @test x.data isa UInt16
        @test x.data == zero(UInt16)

        y = Posit{8,0}(1.0)
        @test y.data isa UInt8
    end

end
