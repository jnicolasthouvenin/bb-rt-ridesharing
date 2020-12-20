
"""
Fichier principal
"""

println("Precompiling packages...")

const MAX_CAPAVEHICLE = 20
const SPEED_VEHICLE = 20

const SafeFloat64 = Union{Missing, Float64}

@enum Etat S R E Non

#include("structs.jl")
include("dataManager.jl")
include("branchAndBound.jl")
include("tools.jl")


function formul(lat1::Float64, long1::Float64, lat2::Float64, long2::Float64)
    r = 6371008
    distAng = acos( sin(lat1 * pi/180) * sin(lat2 * pi/180) + cos(lat1 * pi/180) * cos(lat2 * pi/180) * cos((long1 - long2)*pi/180) )

    return r * distAng
end

function calculDistLatLong(stations::Vector{Station})

    nbStations = length(stations)
    distStations = Array{Float64, 2}(undef, nbStations, nbStations)

	for iter = 1:nbStations
        distStations[iter, iter] = 0.
    end

    for iter = 1:(nbStations-1)
		dist = formul(stations[iter].latitude, stations[iter].longitude, stations[iter+1].latitude, stations[iter+1].longitude)
        distStations[iter, iter+1] = dist
		distStations[iter+1, iter] = dist
    end

	for iterRow = 1:nbStations
		for iterCol = (iterRow+2):nbStations
			distStations[iterRow, iterCol] = 0.
			distStations[iterCol, iterRow] = 0.
			for iter = 1:(iterCol-iterRow)
				distStations[iterRow, iterCol] += distStations[iter, iter+1]
				distStations[iterCol, iterRow] += distStations[iter, iter+1]
			end
		end
	end
    return distStations
end

function calcLimit(elt::Elt, w::Float64, epsilon::Float64, tripDate::Array{Float64, 2}, indReq::Int, distStation::Array{Float64, 2}, dictActualStation::Dict{String, Station}, requests::Vector{Request})
	if elt.state == S
		return w - tripDate[indReq, 1] + tripDate[elt.idReq, 1]
	elseif elt.state == E && tripDate[elt.idReq, 2] != -1.
		return (1+epsilon)*distStation[dictActualStation[requests[elt.idReq].departureStation].id, dictActualStation[requests[elt.idReq].arrivalStation].id] + requests[indReq].t - tripDate[elt.idReq, 2]
	elseif elt.state == E
		return -1
	else
		error("La tu essayes de calculer la limite d'un element R")
	end		
end

function calcCMin(matTime::Array{Float64, 2}, iter::Int)
	mini = Inf
	taille = size(matTime)[1]
	for ind = 1:taille
		if ind != iter+1
			if mini > matTime[iter+1, ind]
				mini = matTime[iter+1, ind]
			end
		end
	end
	return mini
end

function main(nameSimul::String = "simulation2.dat", nameFirstStation::String = "Gare", w::Float64 = 15*60., epsilon::Float64 = 0.5)
	# On récupère toutes les données relatives au problème
    allStation = getStations("stations.dat")
    distStation = calculDistLatLong(allStation) / SPEED_VEHICLE
    
    # Landreau, Cousteau, Perray, ZI1Garde, Lycee, Carquefou-Gare et Carquefou-Centre
    indActualStation = [1, 2, 3 ,4 ,7, 9, 12]
    
    actualStation = allStation[indActualStation]									# Les stations utilisées
    dictActualStation = Dict(station.name => station for station in actualStation) 	# Dictionnaire pour avoir les stations depuis leur nom					
    actualDistance = distStation[indActualStation, indActualStation]				# La distance entre ces stations
    requests, nbShuttles = parseRequests(nameSimul)									# On récupère la liste des requètes
    nbRequests = length(requests)													# Calcul du nombre de requete
    
    tripDate = Array{Float64, 2}(undef, nbRequests, 3)								# Matrice qui retiendra le temps de reception d'une demande, de la
    for iter = 1:nbRequests*3    													# récupération et de l'amenage du client
    	tripDate[iter] = -1.
    end
    etatToInt = Dict{Etat, Int}(R => 1, S => 2, E => 3)
    
    actualTime = requests[1].t		
    tripDate[1, 1] = actualTime														# Temps réel de la navette
    iterTrip = 2																	# Indice du premier élement non effectué
    
    #= Pour une navette pour le moment =#
    iterFinTrip = 3
    trip = Vector{Elt}(undef, 3*nbRequests) 										# Liste du trip pour une navette
    trip[1] = Elt(1, R, 1, false, false, 0., "r1", 0.)								# On fixe la première demande au début du trip de la première navette
    trip[2] = Elt(2, S, 1, true, false, 0., "s1", 0.) 									
    trip[3] = Elt(3, E, 1, false, true, 0., "e1", 0.)
    #First request assigned to the first shuttle
    
    tripDate[1] = requests[1].t
    indTimeStation = dictActualStation[nameFirstStation].id
    stopStation = (-1, -1)
    trajTime = 0
    
    indReq = 2
    for indReq in 2:nbRequests
    
    	if trip[iterTrip].state == S
    		indNextStation = dictActualStation[requests[trip[iterTrip].idReq].departureStation].id
    	elseif trip[iterTrip].state == E
    		indNextStation = dictActualStation[requests[trip[iterTrip].idReq].arrivalStation].id
    	else
    		error("Tu essayes d'aller sur un sommet R ?!")
    	end
    	
    	if length(indTimeStation) == 1
			if  indTimeStation > indNextStation
				trajTime = distStation[indTimeStation, (indTimeStation-1)]
				stopStation = (indTimeStation, indTimeStation-1)
			elseif indTimeStation < indNextStation
				trajTime = distStation[indTimeStation, (indTimeStation+1)]
				stopStation = (indTimeStation, indTimeStation+1)
			else
				trajTime = 0
			end
    	end
    	
    	while actualTime + trajTime < requests[indReq].t && iterTrip <= iterFinTrip
    	
    		if length(indTimeStation) > 1
    			actualTime += trajTime
    			indTimeStation = indTimeStation[1]
    			
    			if  indTimeStation > indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation-1)]
					stopStation = (indTimeStation, indTimeStation-1)
				elseif indTimeStation < indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation+1)]
					stopStation = (indTimeStation, indTimeStation+1)
				else
					trajTime = 0
				end
    			
    		end
    		
			while actualTime + trajTime < requests[indReq].t && iterTrip <= iterFinTrip && indTimeStation != indNextStation
				
				actualTime += trajTime
				
				if indTimeStation > indNextStation
					indTimeStation -= 1
				else
					indTimeStation += 1
				end
				
				if indTimeStation > indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation-1)]
					stopStation = (indTimeStation, indTimeStation-1)
				elseif indTimeStation < indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation+1)]
					stopStation = (indTimeStation, indTimeStation+1)
				else
					trajTime = 0
				end
			
			end
			
			if indTimeStation == indNextStation
				tripDate[trip[iterTrip].idReq, etatToInt[trip[iterTrip].state]] = actualTime
			
				iterTrip += 1
				
				if iterTrip <= iterFinTrip
					if trip[iterTrip].state == S
						indNextStation = dictActualStation[requests[trip[iterTrip].idReq].departureStation].id
					elseif trip[iterTrip].state == E
						indNextStation = dictActualStation[requests[trip[iterTrip].idReq].arrivalStation].id
					else
						error("Tu essayes d'aller sur un sommet R ?!")
					end
					
					if  indTimeStation > indNextStation
						trajTime = distStation[indTimeStation, (indTimeStation-1)]
						stopStation = (indTimeStation, indTimeStation-1)
					elseif indTimeStation < indNextStation
						trajTime = distStation[indTimeStation, (indTimeStation+1)]
						stopStation = (indTimeStation, indTimeStation+1)
					else
						trajTime = 0
					end
				end
			end
		end
		
		if iterTrip > iterFinTrip
			actualTime = requests[indReq].t
			trajTime = 0
			stopStation = (indTimeStation, indTimeStation)
			iterTrip = iterFinTrip
		end
		tripDate[indReq, 1] = requests[indReq].t
		
		
		
		
		iterFinTrip += 1
		trip[iterFinTrip] = Elt(iterFinTrip, S, indReq, true, false, 0., "s$indReq", 0.)
		iterFinTrip += 1
		trip[iterFinTrip] = Elt(iterFinTrip, E, indReq, false, true, 0., "e$indReq", 0.)
		
		listEltTri = sort(trip[iterTrip:iterFinTrip], lt = myIsLess)
		
		listIndEltPasFini = [dictActualStation[nameStat].id for nameStat in [elt.state == S ? requests[elt.idReq].departureStation : requests[elt.idReq].arrivalStation for elt in listEltTri]]
		
		matTime = Array{Float64, 2}(undef, iterFinTrip-iterTrip+2, iterFinTrip-iterTrip+2)
		firstDest = Vector{Int}(undef, iterFinTrip-iterTrip+1)
		timeNextStatR = Vector{Float64}(undef, iterFinTrip-iterTrip+1)
		listeVal1 = Vector{Float64}(undef, iterFinTrip-iterTrip+1) 
		listeVal2 = Vector{Float64}(undef, iterFinTrip-iterTrip+1)
		listeChoix = Vector{String}(undef, iterFinTrip-iterTrip+1)
		ecartTemps1 = 0
		
		matTime[2:end, 2:end] = distStation[listIndEltPasFini, listIndEltPasFini]
		
		if length(indTimeStation) == 1		
			ecartTemps1 = (requests[indReq].t - actualTime)
			for iter =  2:(iterFinTrip-iterTrip+2)
				iterStat = listIndEltPasFini[iter-1]
				val1 = (requests[indReq].t - actualTime) + distStation[stopStation[1], iterStat]
				val2 = trajTime + distStation[stopStation[2], iterStat] - (requests[indReq].t - actualTime)
				
				listeVal1[iter-1] = val1
				listeVal2[iter-1] = val2
				if val1 < val2
					matTime[iter, 1] = val1
					matTime[1, iter] = val1
					firstDest[iter-1] = stopStation[1]
					timeNextStatR[iter-1] = (requests[indReq].t - actualTime)
					listeChoix[iter-1] = "val1"
				else
					matTime[iter, 1] = val2
					matTime[1, iter] = val2
					firstDest[iter-1] = stopStation[2]
					timeNextStatR[iter-1] = trajTime - (requests[indReq].t - actualTime)
					listeChoix[iter-1] = "val2"
				end
			end
		else
			listeVal1Prec, listeVal2Prec, listeChoixPrec, firstDestPrec = indTimeStation[2:end]
			diffTemps = requests[indReq].t - actualTime
			for iter =  2:(length(listeChoixPrec)+1)
				iterStat = listIndEltPasFini[iter-1]
			
				val1, val2 = 0, 0
				
				if listeChoixPrec[iter-1] == "val1"
					val1 = listeVal1Prec[iter-1] - diffTemps
					val2 = listeVal2Prec[iter-1] + diffTemps
				elseif listeChoixPrec[iter-1] == "val2"
					val1 = listeVal1Prec[iter-1] + diffTemps
					val2 = listeVal2Prec[iter-1] - diffTemps
				else
					error("Nom non accapté dans la liste listeChoix !")
				end
				
				listeVal1[iter-1] = val1
				listeVal2[iter-1] = val2
				if val1 < val2
					matTime[iter, 1] = val1
					matTime[1, iter] = val1
					timeNextStatR[iter-1] = val1 - distStation[firstDestPrec[iter-1], iterStat]
					firstDest[iter-1] = stopStation[1]
					listeChoix[iter-1] = "val1"
				else
					matTime[iter, 1] = val2
					matTime[1, iter] = val2
					timeNextStatR[iter-1] = val2 - distStation[firstDestPrec[iter-1], iterStat]
					firstDest[iter-1] = stopStation[2]
					listeChoix[iter-1] = "val2"
				end
			end
			for iter = (length(listeChoixPrec)+2):(iterFinTrip-iterTrip+2)
				iterStat = listIndEltPasFini[iter-1]
				val1 = trajTime - (requests[indReq].t - actualTime) + distStation[stopStation[1], iterStat]
				val2 = distStation[stopStation[1], stopStation[2]] - trajTime + (requests[indReq].t - actualTime) + distStation[stopStation[2], iterStat]
				
				listeVal1[iter-1] = val1
				listeVal2[iter-1] = val2
				if val1 < val2
					matTime[iter, 1] = val1
					matTime[1, iter] = val1
					firstDest[iter-1] = stopStation[1]
					timeNextStatR[iter-1] = (requests[indReq].t - actualTime)
					listeChoix[iter-1] = "val1"
				else
					matTime[iter, 1] = val2
					matTime[1, iter] = val2
					firstDest[iter-1] = stopStation[2]
					timeNextStatR[iter-1] = trajTime - (requests[indReq].t - actualTime)
					listeChoix[iter-1] = "val2"
				end
			end			
		end
					
			
		matTime[1, 1] = 0.
		
		listElt = Vector{Elt}(undef, iterFinTrip-iterTrip+1)
		for iter = 1:(iterFinTrip-iterTrip+1)
			elt = listEltTri[iter]
			listElt[iter] = Elt(iter+1, elt.state, elt.idReq, elt.isSource, (elt.state == E && tripDate[elt.idReq, 2] == -1), calcLimit(elt, w, epsilon, tripDate, indReq, distStation, dictActualStation, requests), elt.name, calcCMin(matTime, iter))
		end
		
		listNextElt, lastElt = branchAndBound(listElt, matTime, epsilon)
		
		if (listNextElt, lastElt) != (false, false)
		
			trajTime = timeNextStatR[listNextElt[2].id-1] 
			indTimeStation = (firstDest[listNextElt[2].id-1], listeVal1, listeVal2, listeChoix, firstDest)
			
			trip[iterTrip] = Elt(iterFinTrip, R, indReq, false, false, 0., "r$indReq", 0.)
			for iter = 1:(iterFinTrip-iterTrip)
				elt = listNextElt[iter+1]
				trip[iter + iterTrip] = Elt(iter+ iterTrip - 1, elt.state, elt.idReq, elt.isSource, false, 0., elt.name, 0.)
			end
			trip[iterFinTrip+1] = Elt(iterFinTrip+1, lastElt.state, lastElt.idReq, lastElt.isSource, false, 0., lastElt.name, 0.)
			
			iterTrip += 1
		else
			println("Impossible d'accepter le client $indReq")
		end
		println(trip)
		actualTime = requests[indReq].t
		# Recup Next Station
		# Se mettre au bon temps grace à matTime
		# Et on recommence en les ajoutant au Trip
	end	
	
	#=while iterTrip <= iterFinTrip
		debStat = nothing
	end=#
	return trip, tripDate
end

function jules()
    e1 = Elt(2,E,1,false,false,10.,"e1",2)
    s2 = Elt(3,S,2,true,false,10.,"s2",1)
    e2 = Elt(4,E,2,false,true,10.,"e2",1)
    
    L = [e1,s2,e2]

    A = [
        0. 3. 4. 5.;
        3. 0. 7. 2.;
        4. 7. 0. 1.;
        5. 2. 1. 0.
    ]

    # s3 = Elt(5,S,3,true,false,1000.,"s3",1)
    # e3 = Elt(6,E,3,false,true,1000.,"e3",1)

    # L = [e1,s2,e2,s3,e3]

    # A = [
    #     0. 3. 4. 5. 3. 7.;
    #     3. 0. 7. 2. 6. 1.;
    #     4. 7. 0. 1. 2. 5.;
    #     5. 2. 1. 0. 4. 3.;
    #     3. 6. 2. 4. 0. 2.;
    #     7. 1. 5. 0. 2. 0.
    # ]

   branchAndBound(L,A, 0.5)
   #branchAndBoundBis(L,A,100.)

    println("end")
end

