
"""
structs.jl déclare les nouveaux types utilisés dans ce projet.
"""

import Base.show

# objet Station modélisant une station de navette
struct Station
    id::Int
    name::String
    latitude::Float64
    longitude::Float64
end

Base.show(io::IO, x::Station) = print(io, x.name)

abstract type element end

#=struct TripRequest
    s::S
    e::E
    w::Int
    epsilon::Int
end=#

struct Request
    t::Int
    departureStation::String
    arrivalStation::String
end

struct Elt
    id::Int
    state::Etat
    idReq::Int
    isSource::Bool
    sourceRemaining::Bool
    limit::Float64 # si elt est un s alors limit dépend de w et r, si elt est un e alors limit dépend de s et epsilon et e (1+epsilon)d(s,e)
    name::String
    cMin::Float64
end

mutable struct Node
    empty::Bool # si le noeud est supprimé
    probed::Bool # si le noeud est sondé (que tous ses enfants sont sondés ou qu'il ne peut plus posséder d'enfants)
    passedElts::Vector{Elt} # éléments passés triés dans l'ordre de parcours
    passedDT::Vector{Float64} # dT passés correspondant aux temps des éléments passés
    futureElts::Vector{Elt} # éléments futures non triés
    sumFutureCMin::Float64 # somme des CMin des éléments futures
    e::Elt # élément du noeud
    h::Int # hauteur du noeud
    dT::Float64 # distance du noeud à la racine
    lowerBound::Float64 # plus petite distance trouvée en développant ce noeud
    children::Vector{Node} # noeuds enfants de ce noeud
end

function emptyElt()
    return Elt(0, Non, 0, true,false, 0., "", 0.)
end

function emptyNode()
    passedElts = Vector{Elt}(undef,0)
    children= Vector{Node}(undef,0)
    return Node(true,true,passedElts,Vector{Float64}(undef,0),passedElts,0.,emptyElt(),0,0.,0.,children)
end

function newNode(passedElts::Vector{Elt},passedDT::Vector{Float64},futureElts::Vector{Elt},sumFutureCMin::Float64,e::Elt,h::Int,dT::Float64,lowerBound::Float64)
    children = Vector{Node}(undef,0)
    return Node(false,false,passedElts,passedDT,futureElts,sumFutureCMin,e,h,dT,lowerBound,children)
end

#=Base.show(io::IO, n::Node) = print(io, n.nom," -> ",n.children)
function Base.show(io::IO, t::Array{Node,1})
    print(io, "(")
    for i in 1:length(t)
        try
            Base.show(io, t[i])
        catch
        end
    end
    print(io, ")")
end=#