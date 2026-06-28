# Test Suite

## Running the tests

**Full suite** (required before any commit):
```bash
julia --startup-file=no --project=. test/runtests.jl
```

**Single file** (faster iteration):
```bash
julia --project=. test/lns.jl
```

**One testset by name** (using the `--testset` filter):
```bash
julia --project=. -e 'using Test; @testset filter=t->occursin("NaR", t.description), test/runtests.jl'
```
Or inside a Julia session:
```julia
using UniversalNumbers, Test
include("test/runtests.jl")   # runs everything
```

## Test files

| File | Test suite | Tests | What it covers |
|---|---|---|---|
| `runtests.jl` | UniversalNumbers.jl | 788 | Full regression suite -- see below |
| `broadcasting.jl` | Broadcasting and Array Support | 10 | `rand`, `.+`, `sin.()`, in-place `.=` |
| `la.jl` | Linear Algebra -- cross-family | 45 | Cross-family matrix/vector ops and solves |
| `linalg_lu.jl` | Advanced Linear Algebra (LU) | 3 | LU decomposition and `\` for `Posit{32,2}` |
| `lns.jl` | LNS Support | 14 | Arithmetic, math functions, and `\` for `LNS{16,5}` and `LNS{32,16}` |
| `math_linalg.jl` | UniversalNumbers Parametric Interface | 55 | Parametric syntax, custom types (`Posit{19,3}`), comparisons, matrix-vector multiply |
| `posits.jl` | Posit Support | 526 | Comprehensive posit arithmetic, math, and edge cases |
| `printbits.jl` | Bit inspection (printbits / about) | 20 | Bit-level inspection for every registered type |
| `takums.jl` | Takum Support | 8 | Arithmetic and `\` for `Takum{16}` |
| **Total** | | **898** | |

### What `runtests.jl` covers

| Testset | What it verifies |
|---|---|
| Posit{16,1} arithmetic | `+`, `-`, `*`, `/`, unary `-`, `abs` |
| Posit{32,2} arithmetic & math | `sqrt`, `sin`, `cos`, `exp`, `log` |
| Posit{8,0} and Posit{19,3} | Cross-size sanity |
| Posit{19,2}, Posit{16,2} | Full arithmetic + useed reciprocal symmetry |
| CFloat{8,2}/{8,3}/{8,4}/{8,5}/{16,5} | Quarter/half precision and FP8 formats |
| FP8 aliases (E4M3, E3M4, E5M2) | Alias identity, construction, display |
| LNS{16,5}, LNS{32,16} | Log-domain arithmetic |
| Takum{8/16/32/64} | Full arithmetic + math, NaR semantics |
| Fixed{N,R} arithmetic | Basic ops, modular wrap, no NaN/Inf, nextfloat/prevfloat |
| HFloat{6,7}, HFloat{14,7} | IBM hex float arithmetic and math |
| DFloat{7,6}, DFloat{16,8} | IEEE 754-2008 decimal float arithmetic |
| BF16 | Brain float16 arithmetic, NaN/Inf, nextfloat/prevfloat |
| Comparisons | `==`, `<`, `<=` across all type families |
| NaR (Not-a-Real) | Posit NaR semantics: absorbing, total order, negation |
| CFloat NaN and Inf | IEEE exception propagation |
| CFloat subnormals | Values between zero and floatmin |
| DD (double-double) | ~106-bit arithmetic, constants, comparisons |
| AbstractFloat behavior | Promotion, `zero`/`one`, `iszero`, `show` |
| Posit symmetry | `floatmin * floatmax == 1.0` for all posit types |
| nextfloat / prevfloat | Round-trip identity and boundary values |
| zero/one bit patterns | Compile-time constants verified against ccall results |
| hash | Same value → same hash; usable as `Dict` keys |
| parse | `parse(T, s)` for all registered types |
| printbits smoke test | No crash for every registered type |
| about function | Field labels, decoded values, special values |
| LUT8 lookup tables | Table dimensions, arithmetic, Float64 conversion, Fixed{8,4} domain guard |
| Unregistered types | Informative error for out-of-registry combinations |
| LinearAlgebra | Matrix multiply and `dot` for Posit, DD, Fixed |
| Quire / fdp (fused dot product) | Exact fused dot product for posits: `fdp`, explicit `Quire`, `fma_product!`, `clear!`, `quire_bits`, accuracy vs naive, error handling |

## Adding tests

**New type or feature** -- add a testset to `runtests.jl` inside the top-level
`@testset "UniversalNumbers.jl"` block.

**Standalone scenario** (long-running, optional, or needs its own imports) -- add
a new file `test/test_<topic>.jl` and append `include("test_<topic>.jl")` at the
bottom of `runtests.jl`. Update this README with a row in the table above.

**Convention:**
- Each file starts with `using UniversalNumbers, Test` (and any extras like
  `LinearAlgebra`).
- Top-level testsets use plain descriptive names: `@testset "My Feature" begin`.
- Use `atol` tolerances proportional to the type's precision; 8-bit types need
  `atol=0.1` or wider.
- Do not use `@test_broken` to paper over real failures -- fix the root cause or
  open an issue.
