
function newFutureElts(v::Vector{Elt},indexLimit::Int)
    list = Vector{Elt}(undef,indexLimit)
    for indexV in 1:indexLimit
        list[indexV] = v[indexV+1]
    end
    return list
end