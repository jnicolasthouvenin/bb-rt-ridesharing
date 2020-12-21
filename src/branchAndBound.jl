
"""
Se charge de l'exécution du branch and bound
"""

# retourne la solution du problème, faux si le problème est impossible
function branchAndBound(L::Vector{Elt},A::Matrix{Float64},epsilon;debug=Inf, verbose = false)
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
        tuple = bestNodeToExplore(root,upperBound, verbose=verbose)
        if tuple[1] == false # plus de noeuds à explorer
            finished = true # on s'arrête
        else # on va explorer le noeud et refaire un tour
            aff(root)
            verbose && println("")
            enBas = exploreNode(tuple[1],upperBound,A,nbElts,epsilon, verbose=verbose) # on explore le meilleur noeud à explorer
            # enBas est sensé valoir true sauf si on a atteint le bas de l'arbre
            if enBas != true # on a atteint le bas de l'arbre
                if enBas[2] < upperBound # si la valeur du noeud en bas est meilleure que la borne sup actuelle
                    upperBound = enBas[2]
                    lastBestNode = enBas[1]
                    verbose && println("MEILLEUR NOEUD FINAL -> ",enBas[1].e.name)
                end
            end
        end
    end
    aff(root)
    verbose && println("upperBound = ",upperBound)
    if lastBestNode != 0
    	return lastBestNode.passedElts, lastBestNode.e
    else
    	return false, false
    end
end

# retourne le meilleur noeud à explorer ainsi que sa lowerBound, si le return vaut false,false c'est qu'aucun noeud ne reste à explorer
function bestNodeToExplore(node::Node, upperBound::Float64; str="", verbose = false)
    verbose && println("\n",str,"bestNodeToExplore[",node.e.name,"]")
    if node.h == 0 # si le noeud est une feuille de l'arbre, il est déjà sondé. On ne doit pas le reregarder
        verbose && println("On est en bas de l'arbre ce noeud n'est pas valable")
        return node,Inf
    elseif length(node.children) == 0 # si le noeuf n'a pas d'enfants alors il est candidat du meilleur noeud
        verbose && println(str,"Ce noeud n'a pas d'enfants, on remonte")
        return node,node.lowerBound
    else # sinon c'est un noeuf déjà étudié qui possède des enfants. On va descendre dans ceux ci
        verbose && println(str,"Ce noeud a des enfants et n'est pas tout en bas")
        # on calcule l'enfant qui possède la plus petite lowerBound
        nodeMin = 0
        min = Inf
        str = string(str,"      ")
        for indexChild in 1:length(node.children) # on itère sur les enfants
            child = node.children[indexChild] # récupération de l'enfant
            if child.lowerBound > upperBound # si l'enfant possède une borne inf plus grande que la borne sup connue
                verbose && println(str,"L'enfant est trop nul on le supprime")
                node.children[indexChild] = emptyNode() # on le supprime
            elseif child.empty # l'enfant est déjà supprimé
                verbose && println(str,"Ce noeud a été supprimé")
            else # si les enfants sont encore vivants
                verbose && println(str,"L'enfant est valide, on appelle bestNodeToExplore sur lui")
                tuple = bestNodeToExplore(child, upperBound,str=str, verbose=verbose) # on calcule le meilleur noeuf récursivement
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
function exploreNode(node::Node, upperBound::Float64, A::Matrix{Float64}, nbElts::Int, epsilon::Float64; verbose = false)
    verbose && println("exploreNode[",node.e.name," - (",node.dT,",",node.lowerBound,")]")
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
                            verbose && println("ON A PAS TROUVE LA SOURCE WTF CEST PAS NORMAL !!!")
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

# construit l'enfant indexChild du noeud root
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

# construit l'attribut passedDT des fils de node
function newPassedDT(node::Node)
    list = Vector{Float64}(undef,length(node.passedDT)+1)
    for indexList in 1:length(node.passedDT)
        list[indexList] = node.passedDT[indexList]
    end
    list[length(node.passedDT)+1] = node.dT
    return list
end

# retourne la somme les cMin de chaque elt
function getLowerBound(v::Vector{Elt})
    lb = 0.
    for e in v
        lb += e.cMin
    end
    return lb
end

# construit la liste des éléments passés des fils de node
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
function printTree(root::Node;str::String="", verbose = false)
    if root.probed
        verbose && println(str,"PROBED")
    elseif root.empty
        verbose && println(str,"DELETED")
    else
        verbose && println(str,"noeud [",root.e.name," - (",root.dT,",",root.lowerBound,")]")
        str = string(str,"      ")
        for child in root.children
            verbose && println("[",root.e.name,"]")
            verbose && printTree(child,str=str, verbose=verbose)
        end
    end
end

# affiche l'arbre des plannings possibles
function aff(root::Node; verbose = false)
    verbose && println("\nprintTree :")
    verbose && printTree(root, verbose=verbose)
    verbose && println("")
end