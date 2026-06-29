# test_universal.jl
#
# Manual test(s) / demo for a few core types.
# Run from the project root: julia --project=. examples/test_universal.jl

using UniversalNumbers

function test()
    println("Testing CFloat{8,2} (quarter precision)")
    a = CFloat{8,2}(1.0)
    b = CFloat{8,2}(2.0)
    println("  1.0 + 2.0 = ", Float64(a + b))

    println("\nTesting CFloat{16,5} (half precision)")
    a16 = CFloat{16,5}(1.5)
    b16 = CFloat{16,5}(2.5)
    println("  1.5 + 2.5 = ", Float64(a16 + b16))

    println("\nTesting LNS{16,5} (logarithmic number system)")
    al = LNS{16,5}(1.5)
    bl = LNS{16,5}(2.0)
    println("  1.5 * 2.0 = ", Float64(al * bl), "  (log-domain quantization)")

    println("\nTesting Posit{8,0}")
    println("  1.0 + 2.0 = ", Float64(Posit{8,0}(1.0) + Posit{8,0}(2.0)))

    println("\nTesting Posit{16,1}")
    println("  1.5 + 2.5 = ", Float64(Posit{16,1}(1.5) + Posit{16,1}(2.5)))

    println("\nTesting Posit{32,2}")
    println("  1.5 + 2.5 = ", Float64(Posit{32,2}(1.5) + Posit{32,2}(2.5)))

    println("\nTesting NaR (Not-a-Real)")
    n = Posit{16,1}(NaN)
    println("  Posit{16,1}(NaN) is NaR: ", isnan(n))
    println("  NaR == NaR: ", n == n, "  (true in posit land, unlike IEEE NaN)")
    println("  NaR < 1.0:  ", n < Posit{16,1}(1.0))
end

test()
