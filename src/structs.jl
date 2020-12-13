
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

struct R
    station::String
end

struct S
    station::String
end

struct E
    station::String
end

struct TripRequest
    s::S
    e::E
    w::Int
    epsilon::Int
end

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
    limit::Float64 # si elt est un s alors limit dépend de w et r, si elt est un e alors limit dépend de s et epsilon et e (1+epsilon)d(s,e)
    name::String
    cMin::Float64
end

mutable struct Node
    empty::Bool
    passedElts::Vector{Elt}
    futureElts::Vector{Elt}
    sumFutureCMin::Float64
    e::Elt
    h::Int
    dT::Float64
    lowerBound::Float64
    children::Vector{Node}
end

function emptyElt()
    return Elt(0, Non, 0, true, 0., "", 0.)
end

function emptyNode()
    passedElts = Vector{Elt}(undef,0)
    futureElts = Vector{Elt}(undef,0)
    children= Vector{Node}(undef,0)
    return Node(true,passedElts,futureElts,0.,emptyElt(),0,0.,0.,children)
end

function newNode(passedElts::Vector{Elt},futureElts::Vector{Elt},sumFutureCMin::Float64,e::Elt,h::Int,dT::Float64,lowerBound::Float64)
    children = Vector{Node}(undef,0)
    return Node(false,passedElts,futureElts,sumFutureCMin,e,h,dT,lowerBound,children)
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