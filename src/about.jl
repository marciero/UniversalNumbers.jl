# about.jl -- pure-Julia semantic field decoder for all UniversalNumber types.
# Calls printbits (untouched, always to stdout), then writes decoded fields to io.
# 
# Attempt to implement suggestion in https://github.com/takum-arithmetic/Takums.jl/issues/6


# Posit
function _posit_decode(data::BT, N::Int, ES::Int) where BT <: Unsigned
    nbits_storage = sizeof(BT) * 8
    mask = N == nbits_storage ? typemax(BT) : (one(BT) << N) - one(BT)

    (data & mask) == zero(BT)           && return (kind=:zero,)
    (data & mask) == (one(BT) << (N-1)) && return (kind=:nar,)

    sign = Int((data >> (N-1)) & 1)
    mag  = sign == 1 ? ((~data + one(BT)) & mask) : (data & mask)

    pos = N - 2
    k = 0
    regime_str = ""

    if pos >= 0
        run = Int((mag >> pos) & 1)
        if run == 1
            cnt = 0
            while pos >= 0 && Int((mag >> pos) & 1) == 1
                regime_str *= "1"; cnt += 1; pos -= 1
            end
            k = cnt - 1
            if pos >= 0; regime_str *= "0"; pos -= 1; end
        else
            cnt = 0
            while pos >= 0 && Int((mag >> pos) & 1) == 0
                regime_str *= "0"; cnt += 1; pos -= 1
            end
            k = -cnt
            if pos >= 0; regime_str *= "1"; pos -= 1; end
        end
    end

    e = 0
    exp_str = ""
    for _ in 1:ES
        if pos >= 0
            b = Int((mag >> pos) & 1)
            e = (e << 1) | b
            exp_str *= b == 1 ? "1" : "0"
            pos -= 1
        else
            exp_str *= "0"
        end
    end

    frac = 0.0
    frac_str = ""
    weight = 0.5
    while pos >= 0
        b = Int((mag >> pos) & 1)
        frac_str *= b == 1 ? "1" : "0"
        frac += b * weight
        weight *= 0.5
        pos -= 1
    end

    return (kind=:normal, sign=sign, k=k, e=e, frac=frac,
            regime_str=regime_str, exp_str=exp_str, frac_str=frac_str)
end

function about(x::Posit{N,ES,BT}, io::IO=stdout) where {N,ES,BT}
    printbits(x)
    println(io)
    d = _posit_decode(x.data, N, ES)
    if d.kind == :zero; println(io, "  value:  0 (exact)"); return; end
    if d.kind == :nar;  println(io, "  NaR -- Not-a-Real (the posit exception value)"); return; end

    useed_exp = 1 << ES
    total_exp = d.k * useed_exp + d.e
    scale_str = total_exp == 0 ? "1" : "2^$total_exp"

    println(io, "  sign:      $(d.sign)  -->   $(d.sign == 0 ? "+" : "-")")
    println(io, "  regime:    $(d.regime_str)  -->   k = $(d.k)  (useed = 2^$(useed_exp),  2^($(d.k)×$(useed_exp)) = 2^$(d.k * useed_exp))")
    if ES > 0
        println(io, "  exponent:  $(isempty(d.exp_str) ? "(none)" : d.exp_str)  -->   e = $(d.e)  -->   2^$(d.e)")
    end
    if isempty(d.frac_str)
        println(io, "  fraction:  (none)  -->   1 + 0 = 1.0")
    else
        println(io, "  fraction:  $(d.frac_str)  -->   1 + $(d.frac) = $(1.0 + d.frac)")
    end
    println(io, "  scale:     2^($(d.k)×$(useed_exp) + $(d.e)) = $scale_str")
    println(io, "  value:     $(d.sign == 0 ? "+" : "-") × $scale_str × $(1.0 + d.frac) = $(Float64(x))")
end


# CFloat
function about(x::CFloat{N,ES,BT}, io::IO=stdout) where {N,ES,BT}
    printbits(x)
    println(io)
    data      = x.data
    fracbits  = N - 1 - ES
    bias      = (1 << (ES - 1)) - 1
    exp_mask  = (1 << ES) - 1
    frac_mask = fracbits > 0 ? (1 << fracbits) - 1 : 0

    sign     = Int((data >> (N-1)) & 1)
    exp_raw  = Int((data >> fracbits) & exp_mask)
    frac_raw = fracbits > 0 ? Int(data & frac_mask) : 0
    frac_val = ldexp(Float64(frac_raw), -fracbits)
    sign_str = sign == 0 ? "+" : "-"
    exp_str  = string(exp_raw,  base=2, pad=ES)
    frac_str = fracbits > 0 ? string(frac_raw, base=2, pad=fracbits) : "(none)"

    println(io, "  sign:      $sign  -->   $sign_str")
    if exp_raw == exp_mask
        # Delegate to C bridge: Universal uses non-IEEE encoding for NaN vs Inf
        payload = isnan(x) ? "NaN" : "Inf"
        println(io, "  exponent:  $exp_str  -->   all-ones  -->   $payload")
        println(io, "  fraction:  $frac_str  -->   $payload  (Universal cfloat encoding)")
        println(io, "  value:     $sign_str$payload")
    elseif exp_raw == 0
        val = (sign == 0 ? 1.0 : -1.0) * ldexp(frac_val, 1 - bias)
        println(io, "  exponent:  $exp_str  -->   0 (subnormal),  scale = 2^$(1-bias)")
        println(io, "  fraction:  $frac_str  -->   $frac_val  (no implicit leading 1)")
        println(io, "  value:     $sign_str × 2^$(1-bias) × $frac_val = $val")
    else
        exp_val = exp_raw - bias
        val = (sign == 0 ? 1.0 : -1.0) * ldexp(1.0 + frac_val, exp_val)
        println(io, "  exponent:  $exp_str  -->   $exp_raw − $bias = $exp_val  -->   2^$exp_val")
        println(io, "  fraction:  $frac_str  -->   1 + $frac_val = $(1.0 + frac_val)")
        println(io, "  value:     $sign_str × 2^$exp_val × $(1.0 + frac_val) = $val")
    end
end


# BF16
function about(x::BF16, io::IO=stdout)
    printbits(x)
    println(io)
    data     = x.data
    sign     = Int((data >> 15) & 1)
    exp_raw  = Int((data >>  7) & 0xFF)
    frac_raw = Int(data & 0x7F)
    bias     = 127
    frac_val = ldexp(Float64(frac_raw), -7)
    sign_str = sign == 0 ? "+" : "-"
    exp_str  = string(exp_raw,  base=2, pad=8)
    frac_str = string(frac_raw, base=2, pad=7)

    println(io, "  sign:      $sign  -->   $sign_str")
    if exp_raw == 255
        payload = frac_raw == 0 ? "Inf" : "NaN"
        println(io, "  exponent:  $exp_str  -->   all-ones  -->   $payload")
        println(io, "  fraction:  $frac_str  -->   $payload")
        println(io, "  value:     $sign_str$payload")
    elseif exp_raw == 0
        val = (sign == 0 ? 1.0 : -1.0) * ldexp(frac_val, 1 - bias)
        println(io, "  exponent:  $exp_str  -->   0 (subnormal),  scale = 2^$(1-bias)")
        println(io, "  fraction:  $frac_str  -->   $frac_val  (no implicit leading 1)")
        println(io, "  value:     $sign_str × 2^$(1-bias) × $frac_val = $val")
    else
        exp_val = exp_raw - bias
        val = (sign == 0 ? 1.0 : -1.0) * ldexp(1.0 + frac_val, exp_val)
        println(io, "  exponent:  $exp_str  -->   $exp_raw − $bias = $exp_val  -->   2^$exp_val")
        println(io, "  fraction:  $frac_str  -->   1 + $frac_val = $(1.0 + frac_val)")
        println(io, "  value:     $sign_str × 2^$exp_val × $(1.0 + frac_val) = $val")
    end
end


# LNS
function about(x::LNS{N,R,BT}, io::IO=stdout) where {N,R,BT}
    printbits(x)
    println(io)
    data     = x.data
    sign     = Int((data >> (N-1)) & 1)
    int_bits = N - 1 - R

    int_raw = int_bits > 0 ? Int((data >> R) & ((1 << int_bits) - 1)) : 0
    int_val = (int_bits > 0 && (int_raw >> (int_bits - 1)) == 1) ? int_raw - (1 << int_bits) : int_raw

    frac_raw = R > 0 ? Int(data & ((1 << R) - 1)) : 0
    frac_val = ldexp(Float64(frac_raw), -R)
    log_val  = int_val + frac_val

    int_str  = string(int_raw,  base=2, pad=max(1, int_bits))
    frac_str = R > 0 ? string(frac_raw, base=2, pad=R) : "(none)"

    println(io, "  sign:      $sign  -->   $(sign == 0 ? "+" : "-")")
    println(io, "  integer:   $int_str  -->   $int_val  (signed)")
    println(io, "  fraction:  $frac_str  -->   $frac_val")
    println(io, "  log₂:      $int_val + $frac_val = $log_val")
    val = (sign == 0 ? 1.0 : -1.0) * exp2(log_val)
    println(io, "  value:     $(sign == 0 ? "+" : "-") × 2^$log_val = $val")
end


# Fixed
function about(x::Fixed{N,R,BT}, io::IO=stdout) where {N,R,BT}
    printbits(x)
    println(io)
    data = x.data
    raw  = Int(data)
    if (data >> (N-1)) & 1 == 1
        raw -= (1 << N)
    end
    int_part = raw >> R
    frac_raw = Int(data) & ((1 << R) - 1)
    frac_val = ldexp(Float64(frac_raw), -R)

    int_str  = string(Int((data >> R) & ((1 << (N-R)) - 1)), base=2, pad=N-R)
    frac_str = R > 0 ? string(frac_raw, base=2, pad=R) : "(none)"

    println(io, "  integer:   $int_str  -->   $int_part  (MSB = sign, two's complement)")
    println(io, "  fraction:  $frac_str  -->   $frac_val")
    println(io, "  value:     $int_part + $frac_val = $(int_part + frac_val)")
end


# Takum
function about(x::Takum{N,BT}, io::IO=stdout) where {N,BT}
    printbits(x)
    println(io)
    data = x.data
    sign = N >= 1 ? Int((data >> (N-1)) & 1) : 0
    dir  = N >= 2 ? Int((data >> (N-2)) & 1) : 0
    println(io, "  sign:      $sign  -->   $(sign == 0 ? "+" : "-")")
    println(io, "  direction: $dir  -->   $(dir == 1 ? "D=1  (away from 0)" : "D=0  (towards 0)")")
    println(io, "  value:     $(Float64(x))  (regime/characteristic/mantissa follow the takum standard)")
end


# DD
function about(x::DD, io::IO=stdout)
    printbits(x)
    println(io)
    hi = reinterpret(Float64, UInt64(x.data & 0xFFFFFFFFFFFFFFFF))
    lo = reinterpret(Float64, UInt64((x.data >> 64) & 0xFFFFFFFFFFFFFFFF))
    println(io, "  hi:        $hi  (primary IEEE-754 double)")
    println(io, "  lo:        $lo  (error correction; |lo| ≤ ½ ulp(hi))")
    println(io, "  sum:       hi + lo  ≈  $(Float64(x))")
    println(io, "  precision: ~106 significand bits  (≈ 31.9 decimal digits)")
end


# HFloat
function about(x::HFloat{N,ES,BT}, io::IO=stdout) where {N,ES,BT}
    printbits(x)
    println(io)
    println(io, "  IBM hexadecimal float (base-16 exponent, $(sizeof(BT)*8)-bit storage)")
    println(io, "  value:     $(Float64(x))")
end


# DFloat
function about(x::DFloat{N,ES,BT}, io::IO=stdout) where {N,ES,BT}
    printbits(x)
    println(io)
    println(io, "  IEEE 754-2008 decimal float, BID encoding ($(sizeof(BT)*8)-bit storage)")
    println(io, "  value:     $(Float64(x))")
end