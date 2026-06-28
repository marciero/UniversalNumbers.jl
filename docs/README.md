# docs/

Documentation sources for UniversalNumbers.jl, built with [Documenter.jl](https://documenter.juliadocs.org/).

## Building locally

```bash
# From the repo root — the shared library must already be built (cmake)
julia --project=docs docs/make.jl
```

Generated HTML is written to `docs/build/`. Open `docs/build/index.html` in a browser to preview.

## Directory layout

Only the documentation **sources** are committed. The generated site (`build/`), the
internal design notes (`dev/`), and `Manifest.toml` are git-ignored and not pushed.

| Path | Purpose | Committed |
|---|---|---|
| `make.jl` | Documenter build script (`makedocs` + `deploydocs`) | yes |
| `Project.toml` | Docs-only Julia project; depends on Documenter and UniversalNumbers (local `[sources]` path) | yes |
| `Manifest.toml` | Auto-generated lock file — do not edit by hand | no (git-ignored) |
| `src/index.md` | Home page: quick start, supported types table, AbstractFloat interface | yes |
| `src/number-systems.md` | Deep dive into all nine number families with math, tables, and when-to-use guidance | yes |
| `src/api.md` | Manual API reference: types, construction, arithmetic, math, quire, comparisons, bit inspection | yes |
| `src/building.md` | Build instructions: CMake setup, adding new types, updating vendored headers, LUT8 | yes |
| `build/` | Generated HTML site (`make.jl` output) | no (git-ignored) |
| `dev/parametric-types.md` | Internal design note (two-parameter UnionAll vs three-parameter concrete type) | no (git-ignored) |

## Deployment

Docs are deployed to GitHub Pages via the `docs` job in `.github/workflows/ci.yml`.
Every push to `main` triggers a build and pushes the result to the `gh-pages` branch.

One-time setup (run once per repo):

```julia
using DocumenterTools
DocumenterTools.genkeys(user="jamesquinlan", repo="UniversalNumbers.jl")
```

This prints:
- A **public key** — add as a Deploy Key with write access (repo Settings → Deploy keys)
- A **private key** — add as `DOCUMENTER_KEY` (repo Settings → Secrets → Actions)

## Adding pages

1. Write a new `.md` file in `docs/src/`
2. Add it to the `pages` vector in `make.jl`
3. Run `julia --project=docs docs/make.jl` to verify locally before pushing
