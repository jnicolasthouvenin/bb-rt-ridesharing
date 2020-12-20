
function branchAndBoundBis(L::Vector{Elt},A::Matrix{Float64},epsilon;debug=Inf)
    # initialisation de l'arbre
    r = Elt(1,R,2,false,false,0.,"r",0.) # création de l'élément racine
    passedElts = Vector{Elt}(undef,0)
    passedDT = Vector{Float64}(undef,0)
    h = length(L)
    nbElts = length(L)
    dT = 0.
    lowerBound = getLowerBound(L)
    upperBound = Inf
    # Creation de la racine de l'arbre
    root = newNode(passedElts,passedDT,L,lowerBound,r,h,dT,lowerBound)
    # descente récursive dans l'arbre
    finished = false
    lastBestNode = 0
    while !finished && debug > 0
        println("while")
        debug -= 1
        println("")
        # On calcule le meilleur noeud à explorer de l'arbre. Si le noeud retourné vaux faux c'est qu'il n'y a plus de noeuds à explorer
        bestNode,lowerBound = bestNodeToExploreBis(root,upperBound)
        if bestNode == false # plus de noeuds à explorer
            finished = true # on s'arrête
        else # on va explorer le noeud et refaire un tour
            println("bestNode = ",bestNode.e.name," -> lowerBound = ",lowerBound)
            aff(root)
            exit()
            println("")
            notFloor = exploreNodeBis(bestNode,upperBound,A,nbElts,epsilon) # on explore le meilleur noeud à explorer
            # notFloor est sensé valoir true sauf si on a atteint le bas de l'arbre
            if notFloor != true # on a atteint le bas de l'arbre
                if notFloor[2] < upperBound # si la valeur du noeud en bas est meilleure que la borne sup actuelle
                    upperBound = notFloor[2]
                    lastBestNode = notFloor[1]
                    println("MEILLEUR NOEUD FINAL -> ",notFloor[1].e.name)
                end
            end
        end
    end
    aff(root)
    println("upperBound = ",upperBound)
end

function bestNodeToExploreBis(root,upperBound)
    if root.probed || root.empty # pas actif donc pas intéressant
        return root,Inf
    elseif length(root.children) == 0 && root.h > 0 # pas d'enfants, on retourne sa borne inf
        return root,root.lowerBound
    elseif length(root.children) == 0 && root.h == 0
        return root,Inf
    else # il a des enfants !
        childMin = 0
        min = Inf
        for indexChild in 1:length(root.children) # parcours des enfants de root
            child = root.children[indexChild]
            if child.lowerBound > upperBound # l'enfant est trop mauvais
                root.children[indexChild] = emptyNode() # on le supprime
            else # l'enfant a des chances de survivre
                bestNode,lowerBound = bestNodeToExplore(child,upperBound)
                if lowerBound < min
                    min = lowerBound
                    childMin = bestNode
                end
            end
        end
        if min == inf # tous les enfants sont soient supprimés soit sondés
            root.probed = true
            return root, Inf
        else # un des enfants est non sondé
            childMin,min # on retourne le meilleur noeud issue de la recherche sur cet enfant
        end
    end
end

# PRECONDITION : Ce noeud est valide est c'est le meilleur à explorer
function exploreNodeBis(root::Node, upperBound::Float64, A::Matrix{Float64}, nbElts::Int, epsilon::Float64)
    floor = false
    nbChildren = root.h
    root.children = Vector{Node}(undef,nbChildren)
    if root.h == 2
        floor = true
        newUpperBound = Inf
        newOptNode = 0
        for indexChild in 1:nbChildren
            # on construit le noeud enfant
            root.children[indexChild] = newChild(root,indexChild,A)
            # on récupère l'enfant pour construire son enfant unique
            child = root.children[indexChild]
            child.children = Vector{Node}(undef,1)
            # on construit le noeud enfant
            child.children[1] = newChild(child,1,A) # dernier noeud au sol
            lowerBoundFloor = child.children[1].lowerBound # on récupère sa lowerBound (qui est sa dT réelle)
            if lowerBoundFloor < newUpperBound # si on obtient une meilleure borne sup
                newUpperBound = lowerBoundFloor # on met à jour la borne sup
                newOptNode = child.children[1] # on met à jour le meilleur noeud
            end
        end
    end
end

function newChild(root::Node,indexChild::Int,A::Matrix{Float64})
    e = root.futureElts[indexChild] # élement du noeud enfant
    d = A[root.e.id,e.id] # distance entre le noeud root et le noeud enfant
    dT = root.dT + d # distance du noeud enfant à la racine
    sumFutureCMin = root.sumFutureCMin - e.cMin # somme des distances min des éléments du noeud enfant
    lowerBound = dT + sumFutureCMin # borne inf du noeud enfant
    passedElts = newPassedElts(root.passedElts,root.e)
    passedDT = newPassedDT(root)
    futureElts = newFutureElts(futureElts,length(futureElts)-1,indexChild)
    # on construit le noeud enfant
    return newNode(passedElts,passedDT,futureElts,sumFutureCMin,e,root.h-1,dT,lowerBound)
end

function branchAndBound(L::Vector{Elt},A::Matrix{Float64},epsilon;debug=Inf)
    println("branchAndBound.jl")
    # initialisation de l'arbre
    r = Elt(1,R,2,false,false,0.,"r",0.) # création de l'élément racine
    passedElts = Vector{Elt}(undef,0)
    passedDT = Vector{Float64}(undef,0)
    h = length(L)
    nbElts = length(L)
    dT = 0.
    lowerBound = getLowerBound(L)
    upperBound = Inf
    # Creation de la racine de l'arbre
    root = newNode(passedElts,passedDT,L,lowerBound,r,h,dT,lowerBound)
    # descente récursive dans l'arbre
    finished = false
    lastBestNode = 0
    while !finished && debug > 0
        println("while")
        debug -= 1
        println("")
        # On calcule le meilleur noeud à explorer de l'arbre. Si le noeud retourné vaux faux c'est qu'il n'y a plus de noeuds à explorer
        tuple = bestNodeToExplore(root,upperBound)
        if tuple[1] == false # plus de noeuds à explorer
            finished = true # on s'arrête
        else # on va explorer le noeud et refaire un tour
            aff(root)
            println("")
            enBas = exploreNode(tuple[1],upperBound,A,nbElts,epsilon) # on explore le meilleur noeud à explorer
            # enBas est sensé valoir true sauf si on a atteint le bas de l'arbre
            if enBas != true # on a atteint le bas de l'arbre
                if enBas[2] < upperBound # si la valeur du noeud en bas est meilleure que la borne sup actuelle
                    upperBound = enBas[2]
                    lastBestNode = enBas[1]
                    println("MEILLEUR NOEUD FINAL -> ",enBas[1].e.name)
                end
            end
        end
    end
    aff(root)
    println("upperBound = ",upperBound)
end

function branchAndBound(L::Vector{Elt},A::Matrix{Float64},epsilon;debug=Inf)
    # initialisation de l'arbre
    r = Elt(1,R,2,false,false,0.,"r",0.) # création de l'élément racine
    passedElts = Vector{Elt}(undef,0)
    passedDT = Vector{Float64}(undef,0)
    h = length(L)
    nbElts = length(L)
    dT = 0.
    lowerBound = getLowerBound(L)
    upperBound = Inf
    # Creation de la racine de l'arbre
    root = newNode(passedElts,passedDT,L,lowerBound,r,h,dT,lowerBound)
    # descente récursive dans l'arbre
    finished = false
    lastBestNode = 0
    while !finished && debug > 0
        debug -= 1
        # On calcule le meilleur noeud à explorer de l'arbre. Si le noeud retourné vaux faux c'est qu'il n'y a plus de noeuds à explorer
        tuple = bestNodeToExplore(root,upperBound)
        if tuple[1] == false # plus de noeuds à explorer
            finished = true # on s'arrête
        else # on va explorer le noeud et refaire un tour
            aff(root)
            println("")
            enBas = exploreNode(tuple[1],upperBound,A,nbElts,epsilon) # on explore le meilleur noeud à explorer
            # enBas est sensé valoir true sauf si on a atteint le bas de l'arbre
            if enBas != true # on a atteint le bas de l'arbre
                if enBas[2] < upperBound # si la valeur du noeud en bas est meilleure que la borne sup actuelle
                    upperBound = enBas[2]
                    lastBestNode = enBas[1]
                    println("MEILLEUR NOEUD FINAL -> ",enBas[1].e.name)
                end
            end
        end
    end
    aff(root)
    println("upperBound = ",upperBound)
    if lastBestNode != 0
    	return lastBestNode.passedElts, lastBestNode.e
    else
    	return false, false
    end
end

# retourne le meilleur noeud à explorer ainsi que sa lowerBound, si le return vaut false,false c'est qu'aucun noeud ne reste à explorer
function bestNodeToExplore(node::Node, upperBound::Float64; str="")
    println("\n",str,"bestNodeToExplore[",node.e.name,"]")
    if node.h == 0 # si le noeud est une feuille de l'arbre, il est déjà sondé. On ne doit pas le reregarder
        println("On est en bas de l'arbre ce noeud n'est pas valable")
        return node,Inf
    elseif length(node.children) == 0 # si le noeuf n'a pas d'enfants alors il est candidat du meilleur noeud
        println(str,"Ce noeud n'a pas d'enfants, on remonte")
        return node,node.lowerBound
    else # sinon c'est un noeuf déjà étudié qui possède des enfants. On va descendre dans ceux ci
        println(str,"Ce noeud a des enfants et n'est pas tout en bas")
        # on calcule l'enfant qui possède la plus petite lowerBound
        nodeMin = 0
        min = Inf
        str = string(str,"      ")
        for indexChild in 1:length(node.children) # on itère sur les enfants
            child = node.children[indexChild] # récupération de l'enfant
            if child.lowerBound > upperBound # si l'enfant possède une borne inf plus grande que la borne sup connue
                println(str,"L'enfant est trop nul on le supprime")
                node.children[indexChild] = emptyNode() # on le supprime
            elseif child.empty # l'enfant est déjà supprimé
                println(str,"Ce noeud a été supprimé")
            else # si les enfants sont encore vivants
                println(str,"L'enfant est valide, on appelle bestNodeToExplore sur lui")
                tuple = bestNodeToExplore(child, upperBound,str=str) # on calcule le meilleur noeuf récursivement
                if tuple[2] < min # si le noeud a une meilleure borne inf que celle connue
                    nodeMin = tuple[1]
                    min = tuple[2]
                end
            end
        end
        if nodeMin == 0 # on n'a trouvé aucun noeud potentiel. On retourne faux faux.
            return false,false
        else
            return nodeMin,min
        end
    end
end

# construit les enfants du noeud passé en paramètres
function exploreNode(node::Node, upperBound::Float64, A::Matrix{Float64}, nbElts::Int, epsilon::Float64)
    println("exploreNode[",node.e.name," - (",node.dT,",",node.lowerBound,")]")
    node.children = Vector{Node}(undef,node.h) # on alloue le vecteur des enfants de ce noeud
    newUpperBound = Inf
    newOptNode = 0
    for indexChild in 1:length(node.futureElts) # parcours des éléments qui vont devenir les enfants de ce noeud
        e = node.futureElts[indexChild] # élément courant
        # calcul de sa lowerBound
        d = A[node.e.id,e.id] # distance entre le noeud courant et l'enfant
        dT = node.dT + d # distance parcourue depuis la racine
        sumFutureCMin = node.sumFutureCMin - e.cMin
        lowerBound = dT + sumFutureCMin # borne inf de l'enfant
        # vérification des contraintes w et epsilon
        if ((dT > e.limit) && (e.limit != -1.)) || lowerBound > upperBound # si l'enfant est au mieux plus mauvais que la borne sup connue
            node.children[indexChild] = emptyNode()
        else # l'enfant a une chance d'être meilleur que la borne sup connue
            # construction des attributs du nouvel enfant
            nbFutureElts = node.h - 1 # nombre d'elts restants de l'enfant
            nbPassedElts = nbElts - 1 - nbFutureElts # nombre d'elts précédents de l'enfant
            passedElts = newPassedElts(node.passedElts,node.e)
            # on vérifie que l'élément est autorisé (pas de e1 avant s1 typiquement)
            authorized = isOrderRespected(node.futureElts,nbFutureElts+1,e)
            if authorized # le noeud a le droit d'être créé
                timeOK = true
                if e.state == E && e.sourceRemaining
                    distance = 0
                    source = 0
                    if node.e.state == S && node.e.idReq == e.idReq # la source que l'on cherche est juste au dessus de notre noeud
                        source = node.e
                        distance = A[node.e.id,e.id]
                    else # source est contenue dans la liste des elts passés de node
                        sourceFound = false
                        indexElt = 1
                        while !sourceFound && indexElt <= length(node.passedElts) # on parcours la liste des noeuds placés
                            eltBuffer = node.passedElts[indexElt]
                            dTBuffer = node.passedDT[indexElt]
                            if eltBuffer.state == S && eltBuffer.idReq == e.idReq # c'est la source !
                                distance = node.dT + A[node.e.id,e.id] - dTBuffer
                                sourceFound = true
                                source = eltBuffer
                            end
                            indexElt += 1
                        end
                        if !sourceFound
                            println("ON A PAS TROUVE LA SOURCE WTF CEST PAS NORMAL !!!")
                            exit()
                        end
                    end
                    if distance > (1+epsilon)*A[source.id,e.id] # la contrainte de trajet est respectée
                        timeOK = false
                    end
                end
                if timeOK
                    futureElts = newFutureElts(node.futureElts,nbFutureElts,indexChild) # elements suivants
                    passedDT = newPassedDT(node)
                    node.children[indexChild] = newNode(passedElts,passedDT,futureElts,sumFutureCMin,e,node.h-1,dT,lowerBound) # création de l'enfant
                    if node.h == 1
                        if lowerBound < upperBound
                            newUpperBound = lowerBound
                            newOptNode = node.children[indexChild]
                        end
                    end
                else
                    node.children[indexChild] = emptyNode()
                end
            else # le noeud n'a pas le droit d'être créé
                node.children[indexChild] = emptyNode()
            end
        end
    end
    if node.h == 1 # on est en bas
        return newOptNode,newUpperBound
    else
        return true
    end
end

function newPassedDT(node::Node)
    list = Vector{Float64}(undef,length(node.passedDT)+1)
    for indexList in 1:length(node.passedDT)
        list[indexList] = node.passedDT[indexList]
    end
    list[length(node.passedDT)+1] = node.dT
    return list
end

function getLowerBound(v::Vector{Elt})
    lb = 0.
    for e in v
        lb += e.cMin
    end
    return lb
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
    for indexV in 1:lengthV
        if indexV < indexChild
            list[indexV] = v[indexV]
        else
            list[indexV] = v[indexV+1]
        end
    end
    return list
end

# vérifie que l'ordre des éléments dans le trajet est logique (pas de e1 avant s1)
function isOrderRespected(v::Vector{Elt},lengthV::Int,e::Elt)
    if e.state == S
        return true
    elseif e.state == E
        for indexElt in 1:lengthV # parcours des éléments
            otherE = v[indexElt]
            if otherE.state == S && otherE.idReq == e.idReq
                return false
            end
        end
        return true
    end
end

# fonction d'affichage de l'arbre
function printTree(root::Node;str::String="")
    if root.probed
        println(str,"PROBED")
    elseif root.empty
        println(str,"DELETED")
    else
        println(str,"noeud [",root.e.name," - (",root.dT,",",root.lowerBound,")]")
        str = string(str,"      ")
        for child in root.children
            println("[",root.e.name,"]")
            printTree(child,str=str)
        end
    end
end

function aff(root::Node)
    println("\nprintTree :")
    printTree(root)
    println("")
end

function affElts(v::Vector{Elt})
    print("[")
    for indexElt in 1:length(v)
        try
            e = v[indexElt]
            print(e.name)
        catch
            print("undef")
        end
        print(",")
    end
    println("]")
end

#=

function branchAndBound(L::Vector{Elt},A::Matrix{Float64})
    r = Elt(1,R,2,false,0.,"r",0.) # création de l'élément racine
    passedElts = Vector{Elt}(undef,0)
    h = length(L)
    nbElts = length(L)
    dT = 0.
    lowerBound = getLowerBound(L)

    root = newNode(passedElts,L,lowerBound,r,h,dT,lowerBound)

    upperBound = Inf

    println("root = ",root)

    println("")
    tuple = bestNodeToExplore(root,upperBound)
    lastBestNode = tuple[1]
    println("lastBestNode = ",lastBestNode.e.name)

    println("tuple = ",tuple)

    println("-------------------------------------------------------------")

    aff(root)

    println("")
    enBas = exploreNode(tuple[1],upperBound,A,nbElts)
    if enBas != true # on a atteint le bas de l'arbre
        if enBas[2] < upperBound
            upperBound = enBas[2]
            println("MEILLEUR NOEUD FINAL -> ",enBas[1].e.name)
        end
    end
    println("\n################")
    println("enBas = ",enBas)
    println("upperBound = ",upperBound)
    println("################\n")

    println("root = ",root)
    println("")
    println("firstChild = ",root.children[1].e.name)
    println("")
    println("secondChild = ",root.children[2].e.name)
    println("")
    println("thridChild = ",root.children[3].e.name)
    println("")

    println("")
    tuple = bestNodeToExplore(root,upperBound)
    lastBestNode = tuple[1]
    println("lastBestNode = ",lastBestNode.e.name)

    println("tuple[1] = ",tuple[1].e.name)
    println("tuple[2] = ",tuple[2])

    println("-------------------------------------------------------------")

    aff(root)

    println("")
    enBas = exploreNode(tuple[1],upperBound,A,nbElts)
    if enBas != true # on a atteint le bas de l'arbre
        if enBas[2] < upperBound
            upperBound = enBas[2]
            println("MEILLEUR NOEUD FINAL -> ",enBas[1].e.name)
        end
    end
    println("\n################")
    println("enBas = ",enBas)
    println("upperBound = ",upperBound)
    println("################\n")

    println("")
    tuple = bestNodeToExplore(root,upperBound)
    lastBestNode = tuple[1]
    println("lastBestNode = ",lastBestNode.e.name)

    println("tuple[1] = ",tuple[1].e.name)
    println("tuple[2] = ",tuple[2])

    println("-------------------------------------------------------------")

    aff(root)

    println("")
    enBas = exploreNode(tuple[1],upperBound,A,nbElts)
    if enBas != true # on a atteint le bas de l'arbre
        if enBas[2] < upperBound
            upperBound = enBas[2]
            println("MEILLEUR NOEUD FINAL -> ",enBas[1].e.name)
        end
    end
    println("\n################")
    println("enBas = ",enBas)
    println("upperBound = ",upperBound)
    println("################\n")

    println("")
    tuple = bestNodeToExplore(root,upperBound)
    lastBestNode = tuple[1]
    println("lastBestNode = ",lastBestNode.e.name)

    println("tuple[1] = ",tuple[1].e.name)
    println("tuple[2] = ",tuple[2])

    println("-------------------------------------------------------------")

    aff(root)

    println("")
    enBas = exploreNode(tuple[1],upperBound,A,nbElts)
    if enBas != true # on a atteint le bas de l'arbre
        if enBas[2] < upperBound
            upperBound = enBas[2]
            println("MEILLEUR NOEUD FINAL -> ",enBas[1].e.name)
        end
    end
    println("\n################")
    println("enBas = ",enBas)
    println("upperBound = ",upperBound)
    println("################\n")

    println("")
    tuple = bestNodeToExplore(root,upperBound)
    if tuple[1] == false
        println("FINI")
        println("lastBestNode = ",lastBestNode.e.name)
    else
        println("tuple[1] = ",tuple[1].e.name)
        println("tuple[2] = ",tuple[2])
    end

    println("-------------------------------------------------------------")

    aff(root)
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

=#
