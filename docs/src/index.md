# UniversalNumbers.jl

Julia bindings for the [Stillwater Universal](https://github.com/stillwater-sc/universal)
C++ number-systems library. Exposes **posits**, **classic floats (cfloat)**,
**logarithmic number systems (LNS)**, **takum**, **fixed-point**, **IBM hex float**,
**decimal float**, **BF16**, and **double-double** as first-class Julia numbers that
implement `AbstractFloat` and compose with the standard library.

## Quick start

```julia
using UniversalNumbers

# Posit arithmetic
a = Posit{16,1}(1.5)
b = Posit{16,1}(2.5)
a + b                        # Posit{16,1}(4.0)
sqrt(Posit{32,2}(2.0))      # Posit{32,2}(1.4142135623842478)
a + 2.5                      # promotes 2.5 → Posit{16,1}: Posit{16,1}(4.0)

# FP8 (ML formats)
E4M3(1.5) + E4M3(0.5)       # CFloat{8,4}(2.0)

# Linear algebra works automatically
using LinearAlgebra
A = [Posit{32,2}(4) Posit{32,2}(1); Posit{32,2}(1) Posit{32,2}(3)]
b = [Posit{32,2}(1), Posit{32,2}(2)]
A \ b                        # solve Ax = b in posit arithmetic
```

## Supported types

| Julia type | Family | Bits | Notes |
|---|---|---|---|
| `Posit{8,0}`, `Posit{16,1}`, `Posit{32,2}`, `Posit{64,2}`, … | Posit | 8–64 | NaR instead of NaN/Inf |
| `CFloat{8,2}`, `CFloat{8,3}`, `CFloat{8,4}`, `CFloat{8,5}`, `CFloat{24,5}` | Classic float | 8–24 | IEEE-style with NaN/Inf |
| `E4M3`, `E3M4`, `E5M2` | FP8 aliases | 8 | OCP MX spec names |
| `LNS{16,5}`, `LNS{32,16}` | Log number system | 16–32 | Exact products |
| `Takum{8}`, `Takum{16}`, `Takum{32}`, `Takum{64}` | Takum | 8–64 | NaR, uniform range |
| `Fixed{8,4}`, `Fixed{16,8}`, `Fixed{32,16}` | Fixed-point | 8–32 | Modular, no NaN |
| `HFloat{6,7}`, `HFloat{14,7}` | IBM hex float | 32–64 | Legacy mainframe |
| `DFloat{7,6}`, `DFloat{16,8}` | Decimal float | 32–64 | IEEE 754-2008 decimal |
| `BF16` | Brain float 16 | 16 | Same exponent as Float32 |
| `DD` | Double-double | 128 | ~106 significand bits |

See [Number Systems](number-systems.md) for a full description of each family.

## AbstractFloat interface

All types implement:

- **Construction** from any `Real`: `Posit{16,1}(1.5)`, `CFloat{8,2}(2)`, `LNS{16,5}(pi)`
- **Conversion**: `Float64(x)`, `Float32(x)`
- **Arithmetic**: `+`, `-`, `*`, `/`, unary `-`, `abs`
- **Math**: `sqrt`, `sin`, `cos`, `exp`, `log`, `atan`, `asin`, `acos`, `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`, `hypot`, `floor`, `ceil`, `trunc`, `round`, `signbit`, `copysign`, `ldexp`, `frexp`
- **Comparisons**: `==`, `<`, `<=`
- **Promotion**: `p + 2.5` converts the standard number into the universal type
- **Constants**: `zero`, `one`, `eps`, `floatmin`, `floatmax`
- **Predicates**: `iszero`, `isnan`, `isinf`
- **Adjacent values**: `nextfloat`, `prevfloat`
- **Random generation**: `rand(Posit{16,1}, 4, 4)`
- **Broadcasting**: `sin.(A)`, `A .+ 1.0`
- **Bit inspection**: `printbits(x)`, `about(x)`
- **Exact fused dot product** (posits): `fdp(a, b)` accumulates products in the quire with a single final rounding

The raw bit encoding is always accessible as `x.data`.

## Installation

Until the package is registered in the Julia General Registry, install from source:

```julia
import Pkg
Pkg.add(url = "https://github.com/jamesquinlan/UniversalNumbers.jl")
```

After registration:
```julia
pkg> add UniversalNumbers
```

Requires Julia ≥ 1.10 and a C++20 compiler (for building from source).
See [Building](building.md) for full instructions.

## Citing

If you use Universal in research, please cite the JOSS paper:

```bibtex
@article{omtzigt2023universal,
  title   = {Universal Numbers Library: Multi-format Variable Precision Arithmetic Library},
  author  = {Omtzigt, E Theodore L and Quinlan, James},
  journal = {Journal of Open Source Software},
  volume  = {8},
  number  = {83},
  pages   = {5072},
  year    = {2023}
}
```


