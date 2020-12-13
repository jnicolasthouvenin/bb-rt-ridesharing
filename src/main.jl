
"""
Fichier principal
"""

println("Precompiling packages...")

include("structs.jl")
include("dataManager.jl")
include("branchAndBound.jl")

function main()
    println("main")

    requests = parseRequests("simulation1")
    println(requests)

    r = Node("r2",Vector{Node}(undef,3))

    r.children[1] = Node("e1",Vector{Node}(undef,2))
    r.children[1].children[1] = Node("e2",Vector{Node}(undef,1))
    r.children[1].children[1].children[1] = Node("s2",Vector{Node}(undef,0))
    r.children[1].children[2] = Node("s2",Vector{Node}(undef,1))

    r.children[2] = Node("e2",Vector{Node}(undef,2))
    r.children[3] = Node("s2",Vector{Node}(undef,2))

    println("r = ",r)
    println("")

    r.children[1].children[1] = Node("null",Vector{Node}(undef,0))

    println("r = ",r)
end

function aff(n::Node)
    println(n.nom," ")
end