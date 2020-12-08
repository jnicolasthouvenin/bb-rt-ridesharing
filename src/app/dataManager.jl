
"""
Gère l'accès et la manipulation des données
"""

const DATAPATH = "../data";

# retourne un Array{Station,1} d'objets Station
function getStations(fileName::String)
    f = openFile(fileName) # ouverture du fichier
    nbStations = parse(Int,readline(f)) # nombre de stations
    stations = Vector{Station}(undef,nbStations)
    for indexStation in 1:nbStations
        line = readline(f)
        splitLine = split(line," ")
        stations[indexStation] = Station(indexStation, splitLine[1],parse(Float64,splitLine[3]),parse(Float64,splitLine[2])) # construction de la station
    end
    return stations
end

# retourne la station du vecteur stations dont le nom est stationName
function getStation(stationName::String,stations::Array{Station,1})
    found = false
    indexStation = 1
    while !found && indexStation <= length(stations)
        if stations[indexStation].name == stationName # on a trouvé la station
            found = true
        end
        indexStation += 1
    end
    return stations[indexStation-1]
end

# retourne le fichier ouvert correspondant au nom donné
function openFile(fileName::String)
    actual_path = pwd()
    cd(joinpath(DATAPATH)) # déplacement dans le repertoire où sont stockés les fichiers source
    f = open(fileName)
    cd(actual_path)
    return f
end

# parse un fichier simulation et retourne les requetes
function parseSimulation(fileName::String)
    f = openFile(fileName)
    nbShuttles = parse(Int,readline(f))
    nbRequest = parse(Int,readline(f))
    for request in 1:nbRequest
        splittedLine = split(readline(f),' ')
        t = parse(Int,splittedLine[1])
        departureStation = string(splittedLine[2])
        arrivalStation = string(splittedLine[3])
        
    end
end