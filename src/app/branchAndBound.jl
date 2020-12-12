
function branchAndBound(r::Elt, L::Array{Elt,1})
    root = Node()
end

function bestNode(node::Node, upperBound::Float64)
    if node.h == 0 # si le noeud est une feuille de l'arbre, il est déjà sondé. On ne doit pas le reregarder
        return node,Inf
    else if length(node.children) == 0 # si le noeuf n'a pas d'enfants alors il est candidat du meilleur noeud
        return node,node.lowerBound
    else # sinon c'est un noeuf déjà étudié qui possède des enfants. On va descendre dans ceux ci
        # on calcule l'enfant qui possède la plus petite lowerBound
        nodeMin = 0
        min = Inf
        for indexChild in 1:length(node.children) # on itère sur les enfants
            child = node.children[indexChild] # récupération de l'enfant
            if child.lowerBound > upperBound # si l'enfant possède une borne inf plus grande que la borne sup connue
                node.children[indexChild] = Node() # on le supprime
            else # sinon
                tuple = bestNode(child, upperBound) # on calcule le meilleur noeuf récursivement
                if tuple[2] < min # si le noeud a une meilleure borne inf que celle connue
                    nodeMin = tuple[1]
                    min = tuple[2]
                end
            end
        end
        return nodeMin,min
    end
end

function expendNode(node::Node, A::Array{Int,2})
    
end