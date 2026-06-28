# API Reference

## Types

All types are subtypes of `UniversalNumber <: AbstractFloat`.

### Posit

```julia
Posit{N, ES}
```

N-bit posit with ES exponent bits. Registered combinations:
`Posit{8,0}`, `Posit{8,1}`, `Posit{8,2}`, `Posit{12,1}`,
`Posit{16,1}`, `Posit{16,2}`, `Posit{19,2}`, `Posit{19,3}`,
`Posit{32,2}`, `Posit{64,2}`, `Posit{64,3}`.

### CFloat

```julia
CFloat{N, ES}
```

N-bit classic (IEEE-style) float with ES exponent bits. Registered combinations:
`CFloat{8,2}`, `CFloat{8,3}`, `CFloat{8,4}`, `CFloat{8,5}`, `CFloat{24,5}`.

### FP8 aliases

```julia
const E4M3 = CFloat{8,4}   # 4 exponent bits, 3 mantissa bits
const E3M4 = CFloat{8,3}   # 3 exponent bits, 4 mantissa bits
const E5M2 = CFloat{8,5}   # 5 exponent bits, 2 mantissa bits
```

### LNS

```julia
LNS{N, RB}
```

N-bit logarithmic number system with RB fractional bits. Registered combinations:
`LNS{16,5}`, `LNS{32,16}`.

### Takum

```julia
Takum{N}
```

N-bit takum (rbits = 3 fixed by standard). Registered combinations:
`Takum{8}`, `Takum{16}`, `Takum{32}`, `Takum{64}`.

### Fixed

```julia
Fixed{N, R}
```

N-bit signed fixed-point with R fractional bits. Registered combinations:
`Fixed{8,4}`, `Fixed{16,8}`, `Fixed{32,16}`.

### HFloat

```julia
HFloat{ESIZE, FSIZE}
```

IBM hexadecimal float. Registered combinations: `HFloat{6,7}` (hfp32), `HFloat{14,7}` (hfp64).

### DFloat

```julia
DFloat{ESIZE, FSIZE}
```

IEEE 754-2008 decimal float (BID encoding). Registered combinations:
`DFloat{7,6}` (decimal32), `DFloat{16,8}` (decimal64).

### BF16

```julia
BF16
```

Google Brain float16. 1 sign + 8 exponent + 7 fraction bits.

### DD

```julia
DD
```

Double-double: exact sum of two `Float64` values (~106 significand bits).

---

## Construction and conversion

```julia
T(x::Real)          # construct from any real number
Float64(x)          # convert to Float64
Float32(x)          # convert to Float32
parse(T, s)         # parse a decimal string, e.g. parse(Posit{16,1}, "1.5")
```

---

## Arithmetic

All standard `Base` operators are overloaded:

```julia
a + b               # addition
a - b               # subtraction
a * b               # multiplication
a / b               # division
-a                  # negation
abs(a)              # absolute value
```

Mixed-type expressions (`p + 2.5`, `2 * p`) promote the standard number
into the universal type before computing.

---

## Math functions

**Native** (computed by Universal's C++ mathlib; rounding determined by the type):
```julia
sqrt(x)
sin(x)
cos(x)
exp(x)
log(x)
```

**Float64 fallbacks** (convert to Float64, compute, convert back):
```julia
atan(x)             # also atan(y, x) two-argument form
asin(x);  acos(x)
sinh(x);  cosh(x);  tanh(x)
asinh(x); acosh(x); atanh(x)
hypot(x, y)
floor(x); ceil(x); trunc(x)
round(x, RoundingMode)
signbit(x)
copysign(x, y)
ldexp(x, n)
frexp(x)            # returns (mantissa::T, exponent::Int)
```

**Linear algebra fallbacks** (convert matrix to Float64, return standard decomposition):
```julia
eigen(A)            # returns Eigen{Float64}
svd(A)              # returns SVD{Float64}
cholesky(A)         # returns Cholesky{Float64}
```

---

## Quire — exact fused dot product

Posits provide a **quire**, a wide fixed-point accumulator that sums products with no
intermediate rounding; the fused dot product rounds only once, at the end.

```julia
fdp(a, b)                  # exact fused dot product of two Posit{N,ES} vectors
quire_dot(a, b)            # alias for fdp
quire_bits(Posit{N,ES})    # width of the quire accumulator, in bits
```

For hand-rolled accumulation:

```julia
q = Quire(Posit{32,2})     # zeroed accumulator
fma_product!(q, a, b)      # q += a*b, exactly (no rounding)
clear!(q)                  # reset to zero
Posit{32,2}(q)             # round once back to a posit
```

The quire is posit-only and opt-in — ordinary arithmetic and dot products are unchanged.

---

## Comparisons

```julia
a == b
a < b
a <= b
a != b
a > b
a >= b
```

For posit and takum types, `NaR == NaR` returns `true` (posit standard),
unlike IEEE NaN which is never equal to itself.

---

## Predicates and constants

```julia
iszero(x)
isnan(x)
isinf(x)

zero(T)             # additive identity
one(T)              # multiplicative identity
eps(T)              # machine epsilon
floatmin(T)         # smallest positive normal value
floatmax(T)         # largest finite value
```

---

## Adjacent values

```julia
nextfloat(x)        # next representable value toward +∞
prevfloat(x)        # previous representable value toward -∞
```

---

## Random generation

```julia
rand(T)             # single random value in [0, 1)
rand(T, n)          # Vector{T} of length n
rand(T, m, n)       # Matrix{T} of size m × n
```

---

## Bit inspection

```julia
printbits(x)        # print colored bit-field breakdown to stdout
about(x)            # same, with decoded field values
about(x, io)        # write to a custom IO (useful in tests)
x.data              # raw bits as the underlying unsigned integer
```

---

## Unregistered types

Attempting to construct an unregistered `(N, ES)` combination raises an
informative error:

```julia
julia> Posit{24,1}(1.0)
ERROR: Posit{24, 1} is not instantiated in the registry.
Please add it to UniversalNumbers.TYPE_REGISTRY and rebuild.
```

See [Building](building.md) for instructions on adding a new type.
