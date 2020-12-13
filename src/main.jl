
"""
Fichier principal
"""

println("Precompiling packages...")

include("structs.jl")
include("dataManager.jl")
include("branchAndBound.jl")

const MAX_CAPAVEHICLE = 20
const SPEED_VEHICLE = 20

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

function main()
    allStation = getStations("stations.dat")
    distStation = calculDistLatLong(allStations)
    
    # Landreau, Cousteau, Perray, ZI1Garde, Lycee, Gare et Centre
    indActualStation = [1, 2, 3 ,4 ,7, 9, 12]
    
    actualStation = allStation[indActualStation]
    actualDistance = distStation[indActualStation, indActualStation]
    
    requests = parseRequests("simulation1.dat")
    
    actualTime = 0
end

function jules()
    e1 = Elt(2,false,10.,"e1",2)
    s2 = Elt(3,true,10.,"s2",1)
    e2 = Elt(4,false,10.,"e2",1)
    
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
