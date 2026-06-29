# Template for new experiments with UniversalNumbers.jl.
#
# Usage:
#   1. Copy this file and rename it
#   2. Add your code below (Lines 13 - 15+)
#   3. Run from the projecrt root: julia --project=. examples/my_experiment.jl

using UniversalNumbers

function run_experiment()
    println("Starting experiment...")

     a = Posit{16,2}(1.5)
     b = Posit{16,2}(2.5)
     println("1.5 + 2.5 = ", Float64(a + b))

    println("Experiment finished.")
end

run_experiment()
