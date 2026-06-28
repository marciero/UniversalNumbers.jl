# benchmark.jl -- compare UniversalNumbers against Posits.jl and Takums.jl
#
# Both libraries call into compiled C (libposit_jll / libtakum_jll vs. Universal C++),
# so this is Universal vs. libposit/libtakum, not C++ vs. pure Julia.
#
# Usage:
#   julia --startup-file=no --project=. test/benchmark.jl

include("../src/UniversalNumbers.jl")
using .UniversalNumbers
using BenchmarkTools
using Posits
using Takums

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2000

_ms(t) = string(round(minimum(t).time / 1e6, digits=4), " ms   (min of ", t.params.samples, " samples)")
_ns(t) = string(round(minimum(t).time,        digits=1), " ns")

function bench_section(title)
    println()
    println("=" ^ 60)
    println("  ", title)
    println("=" ^ 60)
end

function bench_row(label, t)
    ns = round(minimum(t).time, digits=1)
    println(rpad("  " * label, 42), lpad(string(ns, " ns"), 12))
end

println()
println("UniversalNumbers vs. Posits.jl / Takums.jl")
println("Julia ", VERSION, "  |  BenchmarkTools min-time (ns)")
println()
println(rpad("Operation", 42), lpad("min (ns)", 12))
println("-" ^ 54)

# Posit arithmetic

bench_section("Posit 8-bit  (+, *, /, sqrt)")

let au = Posit{8,0}(1.5),  bu = Posit{8,0}(2.5),
    ap = Posit8(1.5),       bp = Posit8(2.5)
    bench_row("UN  Posit{8,0}    add",  @benchmark $au + $bu)
    bench_row("Posits  Posit8   add",   @benchmark $ap + $bp)
    bench_row("UN  Posit{8,0}    mul",  @benchmark $au * $bu)
    bench_row("Posits  Posit8   mul",   @benchmark $ap * $bp)
    bench_row("UN  Posit{8,0}    div",  @benchmark $au / $bu)
    bench_row("Posits  Posit8   div",   @benchmark $ap / $bp)
    bench_row("UN  Posit{8,0}    sqrt", @benchmark sqrt($au))
    bench_row("Posits  Posit8   sqrt",  @benchmark sqrt($ap))
end

bench_section("Posit 16-bit  (+, *, /, sqrt, sin, exp, log)")

let au = Posit{16,1}(1.5),  bu = Posit{16,1}(2.5),
    ap = Posit16(1.5),       bp = Posit16(2.5)
    bench_row("UN  Posit{16,1}   add",  @benchmark $au + $bu)
    bench_row("Posits  Posit16  add",   @benchmark $ap + $bp)
    bench_row("UN  Posit{16,1}   mul",  @benchmark $au * $bu)
    bench_row("Posits  Posit16  mul",   @benchmark $ap * $bp)
    bench_row("UN  Posit{16,1}   div",  @benchmark $au / $bu)
    bench_row("Posits  Posit16  div",   @benchmark $ap / $bp)
    bench_row("UN  Posit{16,1}   sqrt", @benchmark sqrt($au))
    bench_row("Posits  Posit16  sqrt",  @benchmark sqrt($ap))
    bench_row("UN  Posit{16,1}   sin",  @benchmark sin($au))
    bench_row("Posits  Posit16  sin",   @benchmark sin($ap))
    bench_row("UN  Posit{16,1}   exp",  @benchmark exp($au))
    bench_row("Posits  Posit16  exp",   @benchmark exp($ap))
    bench_row("UN  Posit{16,1}   log",  @benchmark log($au))
    bench_row("Posits  Posit16  log",   @benchmark log($ap))
end

bench_section("Posit 32-bit  (+, *, /, sqrt, sin, exp, log)")

let au = Posit{32,2}(1.5),  bu = Posit{32,2}(2.5),
    ap = Posit32(1.5),       bp = Posit32(2.5)
    bench_row("UN  Posit{32,2}   add",  @benchmark $au + $bu)
    bench_row("Posits  Posit32  add",   @benchmark $ap + $bp)
    bench_row("UN  Posit{32,2}   mul",  @benchmark $au * $bu)
    bench_row("Posits  Posit32  mul",   @benchmark $ap * $bp)
    bench_row("UN  Posit{32,2}   div",  @benchmark $au / $bu)
    bench_row("Posits  Posit32  div",   @benchmark $ap / $bp)
    bench_row("UN  Posit{32,2}   sqrt", @benchmark sqrt($au))
    bench_row("Posits  Posit32  sqrt",  @benchmark sqrt($ap))
    bench_row("UN  Posit{32,2}   sin",  @benchmark sin($au))
    bench_row("Posits  Posit32  sin",   @benchmark sin($ap))
    bench_row("UN  Posit{32,2}   exp",  @benchmark exp($au))
    bench_row("Posits  Posit32  exp",   @benchmark exp($ap))
    bench_row("UN  Posit{32,2}   log",  @benchmark log($au))
    bench_row("Posits  Posit32  log",   @benchmark log($ap))
end

bench_section("Posit 64-bit  (+, *, /, sqrt, sin, exp, log)")

let au = Posit{64,3}(1.5),  bu = Posit{64,3}(2.5),
    ap = Posit64(1.5),       bp = Posit64(2.5)
    bench_row("UN  Posit{64,3}   add",  @benchmark $au + $bu)
    bench_row("Posits  Posit64  add",   @benchmark $ap + $bp)
    bench_row("UN  Posit{64,3}   mul",  @benchmark $au * $bu)
    bench_row("Posits  Posit64  mul",   @benchmark $ap * $bp)
    bench_row("UN  Posit{64,3}   div",  @benchmark $au / $bu)
    bench_row("Posits  Posit64  div",   @benchmark $ap / $bp)
    bench_row("UN  Posit{64,3}   sqrt", @benchmark sqrt($au))
    bench_row("Posits  Posit64  sqrt",  @benchmark sqrt($ap))
    bench_row("UN  Posit{64,3}   sin",  @benchmark sin($au))
    bench_row("Posits  Posit64  sin",   @benchmark sin($ap))
    bench_row("UN  Posit{64,3}   exp",  @benchmark exp($au))
    bench_row("Posits  Posit64  exp",   @benchmark exp($ap))
    bench_row("UN  Posit{64,3}   log",  @benchmark log($au))
    bench_row("Posits  Posit64  log",   @benchmark log($ap))
end

# Takum arithmetic

bench_section("Takum 8-bit  (+, *, /, sqrt)")

let au = Takum{8}(1.5),   bu = Takum{8}(2.5),
    at = Takums.Takum8(1.5), bt = Takums.Takum8(2.5)
    bench_row("UN  Takum{8}      add",  @benchmark $au + $bu)
    bench_row("Takums  Takum8   add",   @benchmark $at + $bt)
    bench_row("UN  Takum{8}      mul",  @benchmark $au * $bu)
    bench_row("Takums  Takum8   mul",   @benchmark $at * $bt)
    bench_row("UN  Takum{8}      div",  @benchmark $au / $bu)
    bench_row("Takums  Takum8   div",   @benchmark $at / $bt)
    bench_row("UN  Takum{8}      sqrt", @benchmark sqrt($au))
    bench_row("Takums  Takum8   sqrt",  @benchmark sqrt($at))
end

bench_section("Takum 16-bit  (+, *, /, sqrt, sin, exp, log)")

let au = Takum{16}(1.5),   bu = Takum{16}(2.5),
    at = Takums.Takum16(1.5), bt = Takums.Takum16(2.5)
    bench_row("UN  Takum{16}     add",  @benchmark $au + $bu)
    bench_row("Takums  Takum16  add",   @benchmark $at + $bt)
    bench_row("UN  Takum{16}     mul",  @benchmark $au * $bu)
    bench_row("Takums  Takum16  mul",   @benchmark $at * $bt)
    bench_row("UN  Takum{16}     div",  @benchmark $au / $bu)
    bench_row("Takums  Takum16  div",   @benchmark $at / $bt)
    bench_row("UN  Takum{16}     sqrt", @benchmark sqrt($au))
    bench_row("Takums  Takum16  sqrt",  @benchmark sqrt($at))
    bench_row("UN  Takum{16}     sin",  @benchmark sin($au))
    bench_row("Takums  Takum16  sin",   @benchmark sin($at))
    bench_row("UN  Takum{16}     exp",  @benchmark exp($au))
    bench_row("Takums  Takum16  exp",   @benchmark exp($at))
    bench_row("UN  Takum{16}     log",  @benchmark log($au))
    bench_row("Takums  Takum16  log",   @benchmark log($at))
end

bench_section("Takum 32-bit  (+, *, /, sqrt, sin, exp, log)")

let au = Takum{32}(1.5),   bu = Takum{32}(2.5),
    at = Takums.Takum32(1.5), bt = Takums.Takum32(2.5)
    bench_row("UN  Takum{32}     add",  @benchmark $au + $bu)
    bench_row("Takums  Takum32  add",   @benchmark $at + $bt)
    bench_row("UN  Takum{32}     mul",  @benchmark $au * $bu)
    bench_row("Takums  Takum32  mul",   @benchmark $at * $bt)
    bench_row("UN  Takum{32}     div",  @benchmark $au / $bu)
    bench_row("Takums  Takum32  div",   @benchmark $at / $bt)
    bench_row("UN  Takum{32}     sqrt", @benchmark sqrt($au))
    bench_row("Takums  Takum32  sqrt",  @benchmark sqrt($at))
    bench_row("UN  Takum{32}     sin",  @benchmark sin($au))
    bench_row("Takums  Takum32  sin",   @benchmark sin($at))
    bench_row("UN  Takum{32}     exp",  @benchmark exp($au))
    bench_row("Takums  Takum32  exp",   @benchmark exp($at))
    bench_row("UN  Takum{32}     log",  @benchmark log($au))
    bench_row("Takums  Takum32  log",   @benchmark log($at))
end

bench_section("Takum 64-bit  (+, *, /, sqrt, sin, exp, log)")

let au = Takum{64}(1.5),   bu = Takum{64}(2.5),
    at = Takums.Takum64(1.5), bt = Takums.Takum64(2.5)
    bench_row("UN  Takum{64}     add",  @benchmark $au + $bu)
    bench_row("Takums  Takum64  add",   @benchmark $at + $bt)
    bench_row("UN  Takum{64}     mul",  @benchmark $au * $bu)
    bench_row("Takums  Takum64  mul",   @benchmark $at * $bt)
    bench_row("UN  Takum{64}     div",  @benchmark $au / $bu)
    bench_row("Takums  Takum64  div",   @benchmark $at / $bt)
    bench_row("UN  Takum{64}     sqrt", @benchmark sqrt($au))
    bench_row("Takums  Takum64  sqrt",  @benchmark sqrt($at))
    bench_row("UN  Takum{64}     sin",  @benchmark sin($au))
    bench_row("Takums  Takum64  sin",   @benchmark sin($at))
    bench_row("UN  Takum{64}     exp",  @benchmark exp($au))
    bench_row("Takums  Takum64  exp",   @benchmark exp($at))
    bench_row("UN  Takum{64}     log",  @benchmark log($au))
    bench_row("Takums  Takum64  log",   @benchmark log($at))
end

# Reference: Float64

bench_section("Reference: native Float64")

let a = 1.5, b = 2.5
    bench_row("Float64  add",  @benchmark $a + $b)
    bench_row("Float64  mul",  @benchmark $a * $b)
    bench_row("Float64  div",  @benchmark $a / $b)
    bench_row("Float64  sqrt", @benchmark sqrt($a))
    bench_row("Float64  sin",  @benchmark sin($a))
    bench_row("Float64  exp",  @benchmark exp($a))
    bench_row("Float64  log",  @benchmark log($a))
end

println()
println("Note: UN = UniversalNumbers (stillwater-sc/universal C++ library)")
println("      Posits/Takums call libtakum_jll / libposit_jll (takum-arithmetic.org)")
println("      All timings are minimum observed latency (single scalar operation).")
println()

# Accuracy benchmarks
# Error vs. Float64 reference over uniform grids.  Float64 is treated as ground
# truth; errors measure quantisation + math-function approximation combined.

function _acc_stats(errs::Vector{Float64})
    isempty(errs) && return (n=0, mae=NaN, maxe=NaN, rmse=NaN)
    n    = length(errs)
    mae  = sum(abs, errs) / n
    maxe = maximum(abs, errs)
    rmse = sqrt(sum(x -> x^2, errs) / n)
    (n=n, mae=mae, maxe=maxe, rmse=rmse)
end

function _roundtrip_errs(T, vals)
    errs = Float64[]
    for v in vals
        try
            r = Float64(T(v))
            isfinite(r) && push!(errs, r - v)
        catch; end
    end
    errs
end

function _fn_errs(T, vals, fn_t, fn_ref)
    errs = Float64[]
    for v in vals
        try
            r   = Float64(fn_t(T(v)))
            ref = fn_ref(v)
            (isfinite(r) && isfinite(ref)) && push!(errs, r - ref)
        catch; end
    end
    errs
end

function acc_row(label, errs)
    s = _acc_stats(errs)
    s.n == 0 && return
    println(rpad("  " * label, 44),
            lpad(string(round(s.mae,  sigdigits=3)), 13),
            lpad(string(round(s.maxe, sigdigits=3)), 14),
            lpad(string(round(s.rmse, sigdigits=3)), 13))
end

const _RT  = collect(range(-4.0,   4.0,  length=300))   # roundtrip
const _SQ  = collect(range( 0.01, 16.0,  length=300))   # sqrt
const _SIN = collect(range(-π,     π,    length=300))   # sin
const _EXP = collect(range(-3.0,   3.0,  length=300))   # exp
const _LOG = collect(range( 0.01, 10.0,  length=300))   # log

println()
println("=" ^ 84)
println("  Accuracy vs. Float64 reference  (N=300 uniform test points per domain)")
println("  roundtrip [-4,4]  |  sqrt [0.01,16]  |  sin [-π,π]  |  exp [-3,3]  |  log [0.01,10]")
println("=" ^ 84)
println(rpad("  Operation / Type", 44),
        lpad("MAE", 13), lpad("max|err|", 14), lpad("RMSE", 13))
println("-" ^ 84)

for (lbl_un, T_un, lbl_ext, T_ext) in [
    ("UN  Posit{8,0}",  Posit{8,0},   "Posits  Posit8",  Posit8),
    ("UN  Posit{16,1}", Posit{16,1},  "Posits  Posit16", Posit16),
    ("UN  Posit{32,2}", Posit{32,2},  "Posits  Posit32", Posit32),
    ("UN  Posit{64,3}", Posit{64,3},  "Posits  Posit64", Posit64),
]
    println()
    println("  $lbl_un  vs  $lbl_ext")
    acc_row("roundtrip  $lbl_un",  _roundtrip_errs(T_un,  _RT))
    acc_row("roundtrip  $lbl_ext", _roundtrip_errs(T_ext, _RT))
    acc_row("sqrt       $lbl_un",  _fn_errs(T_un,  _SQ,  sqrt, sqrt))
    acc_row("sqrt       $lbl_ext", _fn_errs(T_ext, _SQ,  sqrt, sqrt))
    acc_row("sin        $lbl_un",  _fn_errs(T_un,  _SIN, sin,  sin))
    acc_row("sin        $lbl_ext", _fn_errs(T_ext, _SIN, sin,  sin))
    acc_row("exp        $lbl_un",  _fn_errs(T_un,  _EXP, exp,  exp))
    acc_row("exp        $lbl_ext", _fn_errs(T_ext, _EXP, exp,  exp))
    acc_row("log        $lbl_un",  _fn_errs(T_un,  _LOG, log,  log))
    acc_row("log        $lbl_ext", _fn_errs(T_ext, _LOG, log,  log))
end

for (lbl_un, T_un, lbl_ext, T_ext) in [
    ("UN  Takum{8}",  Takum{8},  "Takums  Takum8",  Takums.Takum8),
    ("UN  Takum{16}", Takum{16}, "Takums  Takum16", Takums.Takum16),
    ("UN  Takum{32}", Takum{32}, "Takums  Takum32", Takums.Takum32),
    ("UN  Takum{64}", Takum{64}, "Takums  Takum64", Takums.Takum64),
]
    println()
    println("  $lbl_un  vs  $lbl_ext")
    acc_row("roundtrip  $lbl_un",  _roundtrip_errs(T_un,  _RT))
    acc_row("roundtrip  $lbl_ext", _roundtrip_errs(T_ext, _RT))
    acc_row("sqrt       $lbl_un",  _fn_errs(T_un,  _SQ,  sqrt, sqrt))
    acc_row("sqrt       $lbl_ext", _fn_errs(T_ext, _SQ,  sqrt, sqrt))
    acc_row("sin        $lbl_un",  _fn_errs(T_un,  _SIN, sin,  sin))
    acc_row("sin        $lbl_ext", _fn_errs(T_ext, _SIN, sin,  sin))
    acc_row("exp        $lbl_un",  _fn_errs(T_un,  _EXP, exp,  exp))
    acc_row("exp        $lbl_ext", _fn_errs(T_ext, _EXP, exp,  exp))
    acc_row("log        $lbl_un",  _fn_errs(T_un,  _LOG, log,  log))
    acc_row("log        $lbl_ext", _fn_errs(T_ext, _LOG, log,  log))
end

println()
println("Note: error = (result converted to Float64) − (Float64 reference).")
println("      8-bit types have ≤254 finite representable values; grid points alias heavily.")
println("      Identical MAE for UN vs library pair means same underlying algorithm/table.")
println()
