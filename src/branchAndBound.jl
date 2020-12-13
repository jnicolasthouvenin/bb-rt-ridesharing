
function branchAndBound(L::Vector{Elt})
    r = Elt(0,false,"r",0.) # création de l'élément racine
    empty::Bool
    passedElts = Vector{Elt}(undef,0)
    h = length(L)
    dT = 0.
    lowerBound = getLowerBound(L)
    children = Vector{Node}(undef,h)

    root = Node(false,passedElts,L,r,h,dT,lowerBound,children)
end

function getLowerBound(v::Vector{Elt})
    lb = 0.
    for e in v
        lb += e.cMin
    end
    return lb
end

# retourne le meilleur noeud ainsi que sa lowerBound de l'arbre
function bestNode(node::Node, upperBound::Float64)
    if node.h == 0 # si le noeud est une feuille de l'arbre, il est déjà sondé. On ne doit pas le reregarder
        return node,Inf
    elseif length(node.children) == 0 # si le noeuf n'a pas d'enfants alors il est candidat du meilleur noeud
        return node,node.lowerBound
    else # sinon c'est un noeuf déjà étudié qui possède des enfants. On va descendre dans ceux ci
        # on calcule l'enfant qui possède la plus petite lowerBound
        nodeMin = 0
        min = Inf
        for indexChild in 1:length(node.children) # on itère sur les enfants
            child = node.children[indexChild] # récupération de l'enfant
            if child.lowerBound > upperBound # si l'enfant possède une borne inf plus grande que la borne sup connue
                node.children[indexChild] = emptyNode() # on le supprime
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

# construit les enfants du noeud passé en paramètres
function expendNode(node::Node, upperBound::Float64, A::Array{Int,2}, nbElts::Int, w::Float64, epsilon::Float64)
    for indexChild in 1:length(node.futureElts) # parcours des éléments qui vont devenir les enfants de ce noeud
        e = node.futureElts[indexChild] # élément courant
        # calcul de sa lowerBound
        d = A[node.e.id,e.id] # distance entre le noeud courant et l'enfant
        dT = node.dT + d # distance parcourue depuis la racine
        lowerBound = dT + node.lowerBound - e.cMin # borne inf de l'enfant
        # vérification des contraintes w et epsilon
        respectedConstraints = areConstraintsRespected(e,dT,w,epsilon)
        if !respectedConstraints || lowerBound > upperBound # si l'enfant est au mieux plus mauvais que la borne sup connue
            node.children[indexChild] = emptyNode()
        else # l'enfant a une chance d'être meilleur que la borne sup connue
            # construction des attributs du nouvel enfant
            nbFutureElts = node.h - 1 # nombre d'elts restants de l'enfant
            nbPassedElts = nbElts - 1 - nbFutureElts # nombre d'elts précédents de l'enfant
            passedElts[nbPassedElts] = node.e # elements précédents
            # on vérifie que l'élément est autorisé (pas de e1 avant s1 typiquement)
            authorized = isOrderRespected(node.futureElts,nbFutureElts+1,e.id)
            if authorized # le noeud a le droit d'être créé
                futureElts = newFutureElts(futureElts,nbFutureElts,indexChild) # elements suivants
                children = Vector{Node}(undef,nbFutureElts)
                node.children[indexChild] = Node(false,passedElts,futureElts,e,h,dT,lowerBound,children) # création de l'enfant
            else # le noeud n'a pas le droit d'être créé
                node.children[indexChild] = emptyNode()
            end
        end
    end
end

# vérifie que les contraintes d'attente sont respectées
function areConstraintsRespected(e::Elt,dT::Float64,w::Float64,epsilon::Float64)
    if e.isSource
        if dT > w
            return false
        else
            return true
        end
    else
        if dT > epsilon
            return false
        else
            return true
        end
    end
end

# construit la nouvelle liste des éléments restants en supprimant l'élément qui vient d'être utilisé dans le noeud
function newFutureElts(v::Vector{Elt},lengthV::Int,indexChild::Int) # lengthV est la longueur du nouveau tableau attention !
    list = Vector{Elt}(undef,lengthV)
    for indexV in indexChild:lengthV
        list[indexV] = v[indexV+1]
    end
    return list
end

# vérifie que l'ordre des éléments dans le trajet est logique (pas de e1 avant s1)
function isOrderRespected(v::Vector{Elt},lengthV::Int,idElt::Int)
    for indexElt in 1:lengthV # parcours des éléments
        if v[indexElt].id < idElt # si l'élément courant possède un id plus petit que l'id donné
            return false
        end
    end
    return true
end