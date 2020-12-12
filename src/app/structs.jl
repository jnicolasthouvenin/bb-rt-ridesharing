
"""
structs.jl déclare les nouveaux types utilisés dans ce projet.
"""

import Base.show

# objet Station modélisant une station de navette
struct Station
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

##############################

mutable struct Node
    passedElts::Array{Elt,1}
    futureElts::Array{Elt,1}
    e::Elt
    h::Int
    dT::Float64
    lowerBound::Float64
    children::Array{Node,1}
end

struct Elt
    id::Int
    name::String
    cMin::Float64
end

Base.show(io::IO, n::Node) = print(io, n.nom," -> ",n.children)
function Base.show(io::IO, t::Array{Node,1})
    print(io, "(")
    for i in 1:length(t)
        try
            Base.show(io, t[i])
        catch
        end
    end
    print(io, ")")
end