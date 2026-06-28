# Precomputed lookup tables for 8-bit UniversalNumber types.
# Built once during __init__(). All ops become pure Julia array indexing.
# Memory: ~500 KB per type × 7 types ≈ 3.5 MB. Build cost: one-time in __init__().
#
# Note: Fixed-point C++ sqrt/log throw on out-of-domain inputs (negative sqrt,
# non-positive log) regardless of FIXPNT_THROW_ARITHMETIC_EXCEPTION=0.
# The `fixpnt` flag triggers domain-guarded calls for those functions.

struct LUT8
    add    :: Matrix{UInt8}    # [Int(a)+1, Int(b)+1] → result bits
    sub    :: Matrix{UInt8}
    mul    :: Matrix{UInt8}
    div    :: Matrix{UInt8}
    abs_   :: Vector{UInt8}    # [Int(a)+1] → result bits
    sqrt_  :: Vector{UInt8}
    sin_   :: Vector{UInt8}
    cos_   :: Vector{UInt8}
    exp_   :: Vector{UInt8}
    log_   :: Vector{UInt8}
    next_  :: Vector{UInt8}
    prev_  :: Vector{UInt8}
    eq     :: Matrix{Bool}
    lt     :: Matrix{Bool}
    le     :: Matrix{Bool}     # explicit -- needed for NaR/NaN semantics (≠ !lt[b,a])
    isnan_ :: Vector{Bool}
    isinf_ :: Vector{Bool}
    to_f64 :: Vector{Float64}
end

const _LUT8 = Dict{String, LUT8}()

function _build_lut8!(cprefix::String; fixpnt::Bool = false)
    add_sym   = get_sym(Symbol(cprefix * "_add"))
    sub_sym   = get_sym(Symbol(cprefix * "_sub"))
    mul_sym   = get_sym(Symbol(cprefix * "_mul"))
    div_sym   = get_sym(Symbol(cprefix * "_div"))
    abs_sym   = get_sym(Symbol(cprefix * "_abs"))
    sqrt_sym  = get_sym(Symbol(cprefix * "_sqrt"))
    sin_sym   = get_sym(Symbol(cprefix * "_sin"))
    cos_sym   = get_sym(Symbol(cprefix * "_cos"))
    exp_sym   = get_sym(Symbol(cprefix * "_exp"))
    log_sym   = get_sym(Symbol(cprefix * "_log"))
    next_sym  = get_sym(Symbol(cprefix * "_next"))
    prev_sym  = get_sym(Symbol(cprefix * "_prev"))
    eq_sym    = get_sym(Symbol(cprefix * "_eq"))
    lt_sym    = get_sym(Symbol(cprefix * "_lt"))
    le_sym    = get_sym(Symbol(cprefix * "_le"))
    isnan_sym = get_sym(Symbol(cprefix * "_isnan"))
    isinf_sym = get_sym(Symbol(cprefix * "_isinf"))
    f64_sym   = get_sym(Symbol(cprefix * "_to_double"))

    n = 256
    add_t   = Matrix{UInt8}(undef, n, n)
    sub_t   = Matrix{UInt8}(undef, n, n)
    mul_t   = Matrix{UInt8}(undef, n, n)
    div_t   = Matrix{UInt8}(undef, n, n)
    abs_t   = Vector{UInt8}(undef, n)
    sqrt_t  = Vector{UInt8}(undef, n)
    sin_t   = Vector{UInt8}(undef, n)
    cos_t   = Vector{UInt8}(undef, n)
    exp_t   = Vector{UInt8}(undef, n)
    log_t   = Vector{UInt8}(undef, n)
    next_t  = Vector{UInt8}(undef, n)
    prev_t  = Vector{UInt8}(undef, n)
    eq_t    = Matrix{Bool}(undef, n, n)
    lt_t    = Matrix{Bool}(undef, n, n)
    le_t    = Matrix{Bool}(undef, n, n)
    isnan_t = Vector{Bool}(undef, n)
    isinf_t = Vector{Bool}(undef, n)
    f64_t   = Vector{Float64}(undef, n)

    # Phase 1: float64 conversion -- always safe, needed for domain guards below.
    for i = 0x00:0xff
        f64_t[Int(i)+1] = ccall(f64_sym, Float64, (UInt8,), i)
    end

    # Phase 2: unary ops.
    for i = 0x00:0xff
        ii = Int(i) + 1
        vi = f64_t[ii]
        abs_t[ii]   = ccall(abs_sym,   UInt8, (UInt8,), i)
        next_t[ii]  = ccall(next_sym,  UInt8, (UInt8,), i)
        prev_t[ii]  = ccall(prev_sym,  UInt8, (UInt8,), i)
        isnan_t[ii] = ccall(isnan_sym, Bool,  (UInt8,), i)
        isinf_t[ii] = ccall(isinf_sym, Bool,  (UInt8,), i)

        # sqrt: Fixed-point throws on negative input; posit/cfloat/takum return NaR/NaN gracefully.
        if fixpnt && vi < 0.0
            sqrt_t[ii] = 0x00
        else
            sqrt_t[ii] = ccall(sqrt_sym, UInt8, (UInt8,), i)
        end

        # log: Fixed-point throws on non-positive input.
        if fixpnt && vi <= 0.0
            log_t[ii] = 0x00
        elseif log_sym != C_NULL
            log_t[ii] = ccall(log_sym, UInt8, (UInt8,), i)
        else
            log_t[ii] = 0x00
        end

        sin_t[ii] = sin_sym != C_NULL ? ccall(sin_sym, UInt8, (UInt8,), i) : 0x00
        cos_t[ii] = cos_sym != C_NULL ? ccall(cos_sym, UInt8, (UInt8,), i) : 0x00
        exp_t[ii] = exp_sym != C_NULL ? ccall(exp_sym, UInt8, (UInt8,), i) : 0x00
    end

    # Phase 3: binary ops.
    for i = 0x00:0xff
        ii = Int(i) + 1
        for j = 0x00:0xff
            jj = Int(j) + 1
            add_t[ii, jj] = ccall(add_sym, UInt8, (UInt8, UInt8), i, j)
            sub_t[ii, jj] = ccall(sub_sym, UInt8, (UInt8, UInt8), i, j)
            mul_t[ii, jj] = ccall(mul_sym, UInt8, (UInt8, UInt8), i, j)
            div_t[ii, jj] = ccall(div_sym, UInt8, (UInt8, UInt8), i, j)
            eq_t[ii, jj]  = ccall(eq_sym,  Bool,  (UInt8, UInt8), i, j)
            lt_t[ii, jj]  = ccall(lt_sym,  Bool,  (UInt8, UInt8), i, j)
            le_t[ii, jj]  = ccall(le_sym,  Bool,  (UInt8, UInt8), i, j)
        end
    end

    _LUT8[cprefix] = LUT8(add_t, sub_t, mul_t, div_t,
                           abs_t, sqrt_t, sin_t, cos_t, exp_t, log_t,
                           next_t, prev_t,
                           eq_t, lt_t, le_t,
                           isnan_t, isinf_t,
                           f64_t)
    nothing
end

const _LUT8_CPREFIXES = ("posit8_0", "posit8_1", "posit8_2",
                          "cfloat8_2", "cfloat8_3", "cfloat8_4", "cfloat8_5",
                          "fixed8_4", "takum8")

function _init_luts!()
    for cp in _LUT8_CPREFIXES
        _build_lut8!(cp; fixpnt = (cp == "fixed8_4"))
    end
end