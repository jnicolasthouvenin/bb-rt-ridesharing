
function branchAndBound(L::Vector{Elt},A::Matrix{Float64})
    r = Elt(1,false,0.,"r",0.) # création de l'élément racine
    passedElts = Vector{Elt}(undef,0)
    h = length(L)
    nbElts = length(L)
    dT = 0.
    lowerBound = getLowerBound(L)

    root = newNode(passedElts,L,r,h,dT,lowerBound)

    upperBound = Inf

    println("root = ",root)

    tuple = bestNode(root,upperBound)

    println("tuple = ",tuple)

    enBas = expendNode(tuple[1],upperBound,A,nbElts)

    println("enBas = ",enBas)

    println("root = ",root)
    println("")
    println("firstChild = ",root.children[1].e.name)
    println("")
    println("secondChild = ",root.children[2].e.name)
    println("")
    println("thridChild = ",root.children[3].e.name)
    println("")

    tuple = bestNode(root,upperBound)

    println("tuple[1] = ",tuple[1].e.name)
    println("tuple[2] = ",tuple[2])

    println("             ")

    enBas = expendNode(tuple[1],upperBound,A,nbElts)

    println("enBas = ",enBas)
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
    println("bestNode[",node.e.name,"]")
    if node.h == 0 # si le noeud est une feuille de l'arbre, il est déjà sondé. On ne doit pas le reregarder
        println("On est en bas de l'arbre ce noeud n'est pas valable")
        return node,Inf
    elseif length(node.children) == 0 # si le noeuf n'a pas d'enfants alors il est candidat du meilleur noeud
        println("Ce noeud n'a pas d'enfants, on remonte")
        println("lowerBound = ",node.lowerBound)
        return node,node.lowerBound
    else # sinon c'est un noeuf déjà étudié qui possède des enfants. On va descendre dans ceux ci
        println("Ce noeud a des enfants et n'est pas tout en bas")
        # on calcule l'enfant qui possède la plus petite lowerBound
        nodeMin = 0
        min = Inf
        for indexChild in 1:length(node.children) # on itère sur les enfants
            child = node.children[indexChild] # récupération de l'enfant
            if child.lowerBound > upperBound # si l'enfant possède une borne inf plus grande que la borne sup connue
                println("L'enfant est trop nul on le supprime")
                node.children[indexChild] = emptyNode() # on le supprime
            elseif child.empty
                println("Ce noeud a été supprimé")
            else # sinon
                println("L'enfant est valide, on appelle bestNode sur lui")
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
function expendNode(node::Node, upperBound::Float64, A::Matrix{Float64}, nbElts::Int)
    println("expendNode[",node.e.name,"]")
    node.children = Vector{Node}(undef,node.h)
    newUpperBound = Inf
    for indexChild in 1:length(node.futureElts) # parcours des éléments qui vont devenir les enfants de ce noeud
        e = node.futureElts[indexChild] # élément courant
        println("child : ",e.name)
        println("isSource = ",e.isSource)
        # calcul de sa lowerBound
        d = A[node.e.id,e.id] # distance entre le noeud courant et l'enfant
        println("d = ",d)
        dT = node.dT + d # distance parcourue depuis la racine
        println("dT = ",dT)
        println("node.lowerBound = ",node.lowerBound)
        println("e.cMin = ",e.cMin)
        lowerBound = dT + node.lowerBound - e.cMin # borne inf de l'enfant
        newUpperBound = min(upperBound,lowerBound)
        println("lowerBound = ",lowerBound)
        # vérification des contraintes w et epsilon
        if !(dT < e.limit) || lowerBound > upperBound # si l'enfant est au mieux plus mauvais que la borne sup connue
            node.children[indexChild] = emptyNode()
        else # l'enfant a une chance d'être meilleur que la borne sup connue
            # construction des attributs du nouvel enfant
            nbFutureElts = node.h - 1 # nombre d'elts restants de l'enfant
            println("nbFutureElts = ",nbFutureElts)
            nbPassedElts = nbElts - 1 - nbFutureElts # nombre d'elts précédents de l'enfant
            println("nbPassedElts = ",nbPassedElts)
            passedElts = newPassedElts(node.passedElts,node.e)
            # on vérifie que l'élément est autorisé (pas de e1 avant s1 typiquement)
            authorized = isOrderRespected(node.futureElts,nbFutureElts+1,e)
            if authorized # le noeud a le droit d'être créé
                futureElts = newFutureElts(node.futureElts,nbFutureElts,indexChild) # elements suivants
                node.children[indexChild] = newNode(passedElts,futureElts,e,node.h-1,dT,lowerBound) # création de l'enfant
            else # le noeud n'a pas le droit d'être créé
                println("non autorisé")
                node.children[indexChild] = emptyNode()
            end
        end
    end
    if node.h == 1 # on est en bas
        return newUpperBound
    else
        return true
    end
end

# vérifie que les contraintes d'attente sont respectées
function areConstraintsRespected(e::Elt,dT::Float64,w::Float64,epsilon::Float64,A::Matrix{Float64})
    if e.isSource
        d = A[]
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

function newPassedElts(passedElts,e)
    list = Vector{Elt}(undef,length(passedElts)+1)
    for indexList in 1:length(passedElts)
        list[indexList] = passedElts[indexList]
    end
    list[length(passedElts)+1] = e
    return list
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
function isOrderRespected(v::Vector{Elt},lengthV::Int,e::Elt)
    if e.isSource
        return true
    end
    for indexElt in 1:lengthV # parcours des éléments
        if v[indexElt].id < e.id # si l'élément courant possède un id plus petit que l'id donné
            return false
        end
    end
    return true
end