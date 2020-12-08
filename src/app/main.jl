
"""
Fichier principal
"""

println("Precompiling packages...")

include("structs.jl")
include("dataManager.jl")

function main()
    println("testRun")

    requests = parseSimulation("simulation1")
    println(requests)
end