
"""
Fichier principal
"""

println("Precompiling packages...")

const MAX_CAPAVEHICLE = 20
const SPEED_VEHICLE = 20

@enum Etat S R E Non

include("structs.jl")
include("dataManager.jl")
include("branchAndBound.jl")

function formul(lat1::Float64, long1::Float64, lat2::Float64, long2::Float64)
    r = 6371008
    distAng = acos( sin(lat1 * pi/180) * sin(lat2 * pi/180) + cos(lat1 * pi/180) * cos(lat2 * pi/180) * cos((long1 - long2)*pi/180) )

    return r * distAng
end

function calculDistLatLong(stations::Vector{Station})

    nbStations = length(stations)
    distStations = Array{Float64, 2}(undef, nbStations, nbStations)

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
#=
function main(nameFirstStation::String = "Carquefou-Gare", w::Float64 = 15*60., epsilon::Float64 = 0.5)
    allStation = getStations("stations.dat")
    distStation = calculDistLatLong(allStations) / SPEED_VEHICLE
    
    # Landreau, Cousteau, Perray, ZI1Garde, Lycee, Carquefou-Gare et Carquefou-Centre
    indActualStation = [1, 2, 3 ,4 ,7, 9, 12]
    
    actualStation = allStation[indActualStation]									# Les stations utilisées
    dictActualStation = Dict(station.name => station for station in actualStation) 	# Dictionnaire pour avoir les stations depuis leur nom					
    actualDistance = distStation[indActualStation, indActualStation]				# La distance entre ces stations
    requests, nbShuttles = parseRequests("simulation1.dat")							# On récupère la liste des requètes
    nbRequests = length(requests)													# Calcul du nombre de requete
    
    tripDate = Array{Float64, 2}(undef, nbRequests, 3)								# Matrice qui retiendra le temps de reception d'une demande, de la
    for iter = 1:nbRequests*3    													# récupération et de l'amenage du client
    	tripDate[iter] = -1
    end
    
    actualTime = requests[1].t														# Temps réel de la navette
    iterTrip = 2																	# Indice du premier élement non effectué
    
    #= Pour une navette pour le moment =#
    
    trip = Vector{Elt}(undef, 3*nbRequests) 										# Liste du trip pour une navette
    trip[1] = Elt(1, R, 1, false, "r1", 0.)											# On fixe la première demande au début du trip de la première navette
    trip[2] = Elt(2, S, 1, false, "s1", 0.) 									
    trip[3] = Elt(3, E, 1, false, "e1", 0.)
    #First request assigned to the first shuttle
    
    tripDate[1] = requests[1].t
    indTimeStation = dictActualStation[nameFirstStation].id
    
    for indReq in 2:nbRequests
    
    	if trip[iterTrip].state == S
    		indNextStation = dictActualStation[requests[trip[iterTrip].idReq].departureStation].id
    	elseif trip[iterTrip].state == E
    		indNextStation = dictActualStation[requests[trip[iterTrip].idReq].arrivalStation].id
    	else
    		error("Tu essayes d'aller sur un sommet R ?!")
    	end
    	
    	    	
    	trajTime = 0
    	if  indTimeStation > indNextStation
    		trajTime = distStation[indTimeStation, (indTimeStation-1)]
    	elseif indTimeStation < indNextStation
    		trajTime = distStation[indTimeStation, (indTimeStation+1)]
    	else
    		trajTime = 0
    	end
    	
    	while actualTime + trajTime < requests[indReq].t
    	
			while actualTime + trajTime < requests[indReq].t && indTimeStation != indNextStation
				
				actualTime += trajTime
				indTimeStation = eval( quote (indTimeStation > indNextStation ? :+ : :-)(indTimeStation, 1) end)
				
				if indTimeStation > indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation-1)]
				elseif indTimeStation < indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation+1)]
				else
					trajTime = 0
				end
			
			end
			
			if indTimeStation == indNextStation
				iterTrip += 1
				
				if trip[iterTrip].state == S
					indNextStation = dictActualStation[requests[trip[iterTrip].idReq].departureStation].id
				elseif trip[iterTrip].state == E
					indNextStation = dictActualStation[requests[trip[iterTrip].idReq].arrivalStation].id
				else
					error("Tu essayes d'aller sur un sommet R ?!")
				end
				
				if  indTimeStation > indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation-1)]
				elseif indTimeStation < indNextStation
					trajTime = distStation[indTimeStation, (indTimeStation+1)]
				else
					trajTime = 0
				end
			end
		end
		timeLeft = requests[indReq].t - (actualTime + trajTime)
	end
end
=#
function jules()
    e1 = Elt(2,false,20.,"e1",2)
    s2 = Elt(3,true,20.,"s2",1)
    e2 = Elt(4,false,20.,"e2",1)
    
    L = [e1,s2,e2]

    A = [
        0. 3. 4. 5.;
        3. 0. 7. 2.;
        4. 7. 0. 1.;
        5. 2. 1. 0.
    ]

    branchAndBound(L,A)

    println("end")
end
