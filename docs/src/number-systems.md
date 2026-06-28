# Number Systems

UniversalNumbers.jl exposes nine number-system families from the
[Stillwater Universal](https://github.com/stillwater-sc/universal) C++ library.
Each is a first-class Julia `AbstractFloat` subtype backed by a pre-compiled C++
template instantiation.

---

## Posit  `Posit{N, ES}`

**Standard:** Posit arithmetic standard (J. Gustafson, 2017).  
**Storage:** N-bit word (8 → `UInt8`, 16 → `UInt16`, 32 → `UInt32`, 64 → `UInt64`).

Posits replace the fixed exponent/fraction split of IEEE floats with a tapered
encoding: a variable-length *regime* field sets a coarse scale, then an exponent
and fraction refine it.  Precision is highest near ±1 and tapers toward the
extremes — the opposite of what most numerical errors require.

Key properties:
- **One zero, one NaR.** No ±∞, no −0, no signed NaN.  The single special value
  `100...0` is **NaR** (Not-a-Real); `NaR == NaR` is *true* (unlike IEEE NaN).
- **Reciprocal symmetry.** `floatmin(T) * floatmax(T) == 1.0` exactly for every
  posit type.
- **Sign symmetry.** Negation is 2's complement of the bit pattern; every value has
  an exact negative.
- **useed** = 2^(2^ES) is the base of the regime scale.

| Julia type | Bits | ES | useed | maxpos |
|---|---|---|---|---|
| `Posit{8,0}` | 8 | 0 | 2 | 64 |
| `Posit{8,1}` | 8 | 1 | 4 | 4 096 |
| `Posit{8,2}` | 8 | 2 | 16 | ≈ 1.68 × 10⁷ |
| `Posit{12,1}` | 12 (16-bit word) | 1 | 4 | ≈ 1.05 × 10⁶ |
| `Posit{16,1}` | 16 | 1 | 4 | ≈ 2.68 × 10⁸ |
| `Posit{16,2}` | 16 | 2 | 16 | ≈ 7.21 × 10¹⁶ |
| `Posit{19,2}` | 19 (32-bit word) | 2 | 16 | ≈ 2.95 × 10²⁰ |
| `Posit{19,3}` | 19 (32-bit word) | 3 | 256 | ≈ 8.71 × 10⁴⁰ |
| `Posit{32,2}` | 32 | 2 | 16 | ≈ 1.33 × 10³⁶ |
| `Posit{64,2}` | 64 | 2 | 16 | ≈ 4.52 × 10⁷⁴ |
| `Posit{64,3}` | 64 | 3 | 256 | ≈ 2.05 × 10¹⁴⁹ |

**When to use:** drop-in replacement for `Float32`/`Float64` in closed numerical
kernels (linear algebra, iterative solvers) where the inputs cluster near 1.
The tapered precision reduces rounding error in the dynamic range that matters most.

**Quire.** Posits carry an exact fused-dot-product accumulator. `fdp(a, b)` sums products
with no intermediate rounding (one final rounding), and an explicit `Quire` supports
hand-rolled exact accumulation. See the [API reference](api.md).

---

## Classic Float  `CFloat{N, ES}`

**Standard:** IEEE 754-style; Universal's `cfloat<N, ES>` template.  
**Storage:** N-bit word.

CFloat is a generalized IEEE float: N total bits, ES exponent bits, the rest
fraction.  It supports subnormals, ±∞, and NaN by default.  This makes it the
right family for FP8/FP16 ML formats that follow IEEE conventions.

| Julia type | Bits | Exponent | Fraction | Common name |
|---|---|---|---|---|
| `CFloat{8,2}` | 8 | 2 | 5 | — |
| `CFloat{8,3}` | 8 | 3 | 4 | E3M4 |
| `CFloat{8,4}` | 8 | 4 | 3 | E4M3 |
| `CFloat{8,5}` | 8 | 5 | 2 | E5M2 |
| `CFloat{24,5}` | 24 (32-bit word) | 5 | 18 | — |

**FP8 aliases** (exported directly):

```julia
E4M3 === CFloat{8,4}
E3M4 === CFloat{8,3}
E5M2 === CFloat{8,5}
```

**When to use:** ML inference and training where the hardware or model expects
IEEE-compatible semantics, especially FP8 formats (E4M3/E5M2 per OCP MX spec).

---

## Logarithmic Number System  `LNS{N, RB}`

**Standard:** LNS arithmetic (Lewis, 1975; Ismail & Landman, 1996).  
**Storage:** N-bit signed fixed-point value storing log₂(|x|).

Values are stored as their logarithm: `x` is encoded as `round(log₂(|x|))` with
`RB` fractional bits.  As a result:
- **Multiplication and division are exact** (log-domain: add/subtract the exponents).
- **Addition and subtraction** require evaluating log(1 ± 2^Δ) — expensive in
  hardware, approximated via LUT in Universal.
- The value `1.5` is *not* exactly representable (log₂(1.5) is irrational).

| Julia type | Bits | Fraction bits (RB) |
|---|---|---|
| `LNS{16,5}` | 16 | 5 |
| `LNS{32,16}` | 32 | 16 |

**When to use:** applications dominated by products and quotients (signal
processing filter banks, probability computations in log-space) where exact
multiplication matters more than exact addition.

---

## Takum  `Takum{N}`

**Standard:** Takum arithmetic standard (Posit working group, 2022).  
**Storage:** N-bit word.  The regime bit count `rbits = 3` is fixed by the standard.

Takum is a signed-regime posit variant designed to give a more uniform distribution
of representable values.  It uses a direction bit D and a signed-regime encoding to
achieve a symmetric dynamic range without the heavy taper of classical posits.

Special value: **NaR** (bit pattern `100...0`), same semantics as posit NaR.

| Julia type | Bits |
|---|---|
| `Takum{8}` | 8 |
| `Takum{16}` | 16 |
| `Takum{32}` | 32 |
| `Takum{64}` | 64 |

**When to use:** when posit-like properties (one NaR, no signed zero, closed
dynamic range) are wanted but with a more balanced distribution across the range.

---

## Fixed-Point  `Fixed{N, R}`

**Storage:** N-bit 2's-complement integer with R fractional bits.  
**Range:** `[−2^(N−R−1), 2^(N−R−1) − 2^(−R)]`.  Step size: `2^(−R)`.

Fixed-point numbers have no NaN, no Inf, and **no overflow protection** — values
wrap modulo 2^N (2's-complement modular arithmetic).

| Julia type | Bits | Frac bits | Step | Integer range |
|---|---|---|---|---|
| `Fixed{8,4}` | 8 | 4 | 1/16 | −8 to 7.9375 |
| `Fixed{16,8}` | 16 | 8 | 1/256 | −128 to 127.996 |
| `Fixed{32,16}` | 32 | 16 | 1/65536 | −32768 to 32767.999 |

**When to use:** embedded / DSP contexts where the hardware has no FPU, or when
exact rational arithmetic with a known scale is needed.  Be aware of wrap-around:
`Fixed{8,4}(7.0) + Fixed{8,4}(1.0) == Fixed{8,4}(-8.0)`.

---

## IBM Hex Float  `HFloat{ESIZE, FSIZE}`

**Standard:** IBM System/360 hexadecimal floating point (1964).  
**Storage:** 32-bit (`HFloat{6,7}`) or 64-bit (`HFloat{14,7}`).

IBM hex floats use base-16 exponents rather than base-2.  One exponent increment
multiplies the value by 16, so the significand needs only cover one factor of 16
rather than a full doubling — giving fewer effective significand bits for the same
bit width compared to IEEE.  No NaN, no ±∞.

| Julia type | Bits | Common name |
|---|---|---|
| `HFloat{6,7}` | 32 | IBM hfp32 (single) |
| `HFloat{14,7}` | 64 | IBM hfp64 (double) |

**When to use:** reading/writing legacy IBM mainframe data; studying base-16 float
behavior.

---

## Decimal Float  `DFloat{ESIZE, FSIZE}`

**Standard:** IEEE 754-2008 decimal floating-point (BID encoding).  
**Storage:** 32-bit (`DFloat{7,6}`) or 64-bit (`DFloat{16,8}`).

Decimal floats represent values as `mantissa × 10^exponent`, eliminating the
binary-to-decimal rounding that makes `0.1` non-representable in IEEE 754 binary.
They are the standard for financial and tax computations.

| Julia type | Bits | Common name |
|---|---|---|
| `DFloat{7,6}` | 32 | decimal32 |
| `DFloat{16,8}` | 64 | decimal64 |

**When to use:** financial calculations, currency arithmetic, any domain where
`0.1 + 0.2 == 0.3` must hold.

---

## Brain Float 16  `BF16`

**Origin:** Google Brain / TPU (2018), now widespread in ML accelerators.  
**Storage:** 16-bit; 1 sign + 8 exponent + 7 fraction bits.  
**Relation to IEEE:** same exponent width as `Float32` (bias 127), truncated
fraction — so `Float32 → BF16` is a simple right-shift with rounding, and the
dynamic range matches `Float32` exactly.

Supports NaN and ±∞ (same exponent encoding as `Float32`).

**When to use:** ML training and inference on hardware with native BF16 support
(TPUs, recent Intel/AMD/NVIDIA GPUs).  Preferred over `Float16` when dynamic range
matters more than precision.

---

## Double-Double  `DD`

**Storage:** two `Float64` values (hi + lo), 128 bits total.  
**Effective precision:** ~106 significand bits (≈ 31 decimal digits).

Double-double arithmetic represents a value as the exact sum of two `Float64`
values.  The hi component holds the rounded result; the lo component carries the
rounding error.  This gives roughly twice the precision of `Float64` without
requiring hardware 128-bit float support.

Unlike `Float128`, DD does not extend the exponent range — `floatmax(DD)` is close
to `floatmax(Float64)`.

**When to use:** compensated summation, ill-conditioned linear systems, any
computation that requires more than 15–17 decimal digits of accuracy but cannot
afford a full 128-bit float implementation.

---

## Choosing a number system

| Need | Suggested type |
|---|---|
| Drop-in for Float32 with better rounding near 1 | `Posit{32,2}` |
| FP8 inference (ML, OCP MX spec) | `E4M3` / `E5M2` |
| FP16 (IEEE-compatible half precision) | Julia built-in `Float16` |
| 24-bit extended cfloat | `CFloat{24,5}` |
| Exact products dominate (signal processing) | `LNS{32,16}` |
| Embedded / no FPU, known scale | `Fixed{16,8}` or `Fixed{32,16}` |
| Financial / decimal-exact | `DFloat{16,8}` |
| ML on TPU / BF16 hardware | `BF16` |
| Extended precision (31 digits) | `DD` |
| Studying posit-family alternatives | `Takum{32}` |
| Legacy IBM mainframe data | `HFloat{6,7}` / `HFloat{14,7}` |
