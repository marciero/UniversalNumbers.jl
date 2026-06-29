# Lorenz Attractor Visualization
#
# Requires Plots.jl (one-time install):
#   julia --project=examples -e 'using Pkg; Pkg.instantiate()'
#
# Run from the project root:
#   julia --project=examples examples/lorenz.jl
#
# The attractor is solved entirely in type T.
# Low-precision types (Posit{8,0}, Posit{16,1}) will show how limited
# arithmetic distorts or collapses the trajectory - instructive to compare.
#
# Example taken from Stillwater Universal. 


using UniversalNumbers
using Plots
using LinearAlgebra

# Select number type here
T = Posit{12,1}
# Registered posit options:
#   Posit{8,0}   Posit{8,1}  Posit{8,2}  
#   Posit{16,1}  Posit{16,2}
#   Posit{19,2}  Posit{19,3}
#   Posit{32,2}  Posit{64,2}  Posit{64,3}
# Also works with: Takums, Float64, Float32, BF16, DD, ... 

# Lorenz parameters -- all cast to T so every operation stays in T
const sigma = T(10)
const rho   = T(28)
const beta  = T(8) / T(3)
const DT    = T(0.01)

"""
    lorenz_step(x, y, z)

Advance the Lorenz system by one explicit Euler step using the global parameters
`sigma`, `rho`, `beta`, and timestep `DT`. All arithmetic is performed in the
type `S` of the arguments.
"""
function lorenz_step(x::S, y::S, z::S) where {S}
    dx = sigma * (y - x)
    dy = x * (rho - z) - y
    dz = x * y - beta * z
    x + dx * DT, y + dy * DT, z + dz * DT
end

"""
    simulate(x0, y0, z0; nsteps)

Integrate the Lorenz system from initial point `(x0, y0, z0)` for `nsteps` Euler
steps, casting all state to the global type `T`. Returns three `Float64` vectors
for plotting. Stops early if the trajectory produces NaR or NaN, which is common
at very low precision.
"""
function simulate(x0, y0, z0; nsteps::Int)
    x, y, z = T(x0), T(y0), T(z0)
    xs = Vector{Float64}(undef, nsteps)
    ys = Vector{Float64}(undef, nsteps)
    zs = Vector{Float64}(undef, nsteps)
    last = nsteps
    for i in 1:nsteps
        x, y, z = lorenz_step(x, y, z)
        if isnan(x)
            last = i - 1
            break
        end
        xs[i] = Float64(x)
        ys[i] = Float64(y)
        zs[i] = Float64(z)
    end
    xs[1:last], ys[1:last], zs[1:last]
end

# Simulation
n_attractors = 10
nsteps       = 10_000

println("Lorenz attractor  T = $T")
println("  sigma = $(Float64(sigma))  rho = $(Float64(rho))  beta = $(round(Float64(beta), digits=5))")
println("  dt = $(Float64(DT))  steps = $nsteps  trajectories = $n_attractors")
println()

# Plot
gr()
plt = plot3d(
    title            = "Lorenz Attractor   [T = $T]",
    xlabel           = "x",
    ylabel           = "y",
    zlabel           = "z",
    background_color = :black,
    foreground_color = :white,
    legend           = false,
    linewidth        = 0.6,
    size             = (1200, 800),
);

clrs = palette(:plasma, n_attractors);

for i in 1:n_attractors
    init = 0.1 * i + 1.0
    xs, ys, zs = simulate(init, init, init; nsteps)
    if length(xs) < 2
        @warn "Trajectory $i collapsed after $(length(xs)) step(s) -- precision too low?"
        continue
    end
    plot3d!(plt, xs, ys, zs;
            linecolor = clrs[i],
            linewidth = 0.6,
            alpha     = 0.75)
end

# uncomment if you want to save the figure instead of displaying it
# outfile = "lorenz.png"
# savefig(plt, outfile)
# println("Saved to $outfile")
display(plt)
