
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

struct request
    t::Int
    departureStation::String
    arrivalStation::String
end