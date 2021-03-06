extends Node2D

onready var camera = $viewportcontainer/viewport/camera2d
onready var pointer = $viewportcontainer/viewport/universe/pointer
onready var starnamelabel = $gui/starname
onready var coordlabel = $gui/coords
onready var solarsystem = preload("res://scenes/solarsystem.tscn")
onready var minimapsection = get_node("/root/main/gui/minimap/minimapsection")
onready var universescene = preload("res://scenes/Universe.tscn")
var globeview
var camerafollow = 1
var title = "Game v0.1"
var debugfunctions = true
var firstrun
var currentuniverse
var universedict = {}
var numstars = 80
var starlist

func _process(delta):
	#add title and fps to window for testing
	OS.set_window_title(title + " | fps: " + str(Engine.get_frames_per_second()))

func _ready():
	#hide gui minimap - not needed yet
	$gui._universeviewmode()
	#populate universe database, generate all data for all systems
	createuniverse()
	#instance the universe view
	var newuniverse = universescene.instance()
	$viewportcontainer/viewport.add_child(newuniverse)
	newuniverse._populateuniversescene()
	currentuniverse = newuniverse
	camera.target = pointer


func _generatesolarsystem(starchoice):
	#when solar system selected, instance that scene
	$gui/minimapcentre.show()
	var systemdict = starchoice.systemdict
	$viewportcontainer/viewport.remove_child(currentuniverse)
	starnamelabel.set_text(starchoice.sunname)
	var system = solarsystem.instance()
	$viewportcontainer/viewport.add_child(system)
	system.generatesystem(systemdict)
	camerafollow = 1
	camera.target = $viewportcontainer/viewport/solarsystem/player
	camera.zoom = Vector2(2.5, 2.5)
	

func _input(event):
	#control input for universe scene, shouldbe moved out of main
	if event.is_action("zoomin") and event.is_pressed() and not event.is_echo():
		camera.zoom = Vector2(camera.zoom.x / 1.5, camera.zoom.y / 1.5)
		minimapsection.scale = Vector2(minimapsection.scale.x / 1.5, minimapsection.scale.y / 1.5)
	if event.is_action("zoomout") and event.is_pressed() and not event.is_echo():
		camera.zoom = Vector2(camera.zoom.x * 1.5, camera.zoom.y * 1.5)
		minimapsection.scale = Vector2(minimapsection.scale.x * 1.5, minimapsection.scale.y * 1.5)

func loadWords():
	#json reading helper function
    var lines = []                              #set an empty array
    var file = File.new();                      #create an instance
    file.open("res://starnames.json", File.READ); #open the file into instance
    while not file.eof_reached():               #while we're not at end of file
        lines.append(file.get_line())          #append each line to the array
    return lines                                #send the array back



func createsystem(namechoice):
	randomize()
	#create data for each system, sunsize, type, planetsize, type, temp etc
	var sunname = namechoice
	var sunsize = 0
	var sizechoice = randi()%5+1
	if sizechoice < 3:
		sunsize = 1
	elif sizechoice < 5:
		sunsize = 2
	else:
		sunsize = 3
	var suntype = randi()% 99 + 1
	if suntype < 30:
		suntype = 1
	elif suntype < 55:
		suntype = 2
	elif suntype < 75:
		suntype = 3
	elif suntype < 85:
		suntype = 4
	elif suntype < 95:
		suntype = 5
	else:
		suntype = 6
	var suntemperature = (suntype * 700) * sunsize
	var numplanets = 0
	var planetnumrange = randi()%99 + 1
	if planetnumrange < 10:
		numplanets = 1
	elif planetnumrange < 20:
		numplanets = 2
	elif planetnumrange < 30:
		numplanets = 2
	elif planetnumrange < 43:
		numplanets = 3
	elif planetnumrange < 58:
		numplanets = 4
	elif planetnumrange < 72:
		numplanets = 5
	elif planetnumrange < 82:
		numplanets = 6
	elif planetnumrange < 92:
		numplanets = 7
	elif planetnumrange < 97:
		numplanets = 8
	elif planetnumrange < 100:
		numplanets = 9
	var backgroundchoice = randi()%20+1
	var sunpositionx = randi()%499+1
	var sunpositiony = randi()%499+1
	var system_dict = {
		"suntype" : suntype,
		"sunsize" : sunsize,
		"sunname" : sunname,
		"suntemperature" : suntemperature,
		"numplanets" : numplanets,
		"backgroundchoice" : backgroundchoice,
		"sunpositionx" : sunpositionx,
		"sunpositiony" : sunpositiony,
	}
	var acceptableradiuslist = []
	var minradius = sunsize * 170
	#acceptable radius list - cant be too big or too small, to fit graphically on system view
	for i in range(200 + minradius, 6000, 200):
		acceptableradiuslist.append(i)
	var curatedradiuslist = []
	#make a new list that has space around each radius so planets arent too close together
	for i in range(1, numplanets, 1):
		var curatedradiuschoiceindex = randi() % acceptableradiuslist.size()
		curatedradiuslist.append(acceptableradiuslist[curatedradiuschoiceindex])
		acceptableradiuslist.remove(curatedradiuschoiceindex)
	curatedradiuslist.sort()
	var planetlist = []
	for i in range(1, numplanets, 1):
		var planetname = sunname + romannumerals(i)
		var orbitradius = curatedradiuslist[i - 1]
		var planettemperature = suntemperature / pow((orbitradius / 250),2)
		var rockyorgassy = randi()%3 + 1
		var planetradius = 0
		if rockyorgassy == 2 or rockyorgassy == 1:
			rockyorgassy = "rocky"
			planetradius = randf()*0.3 + 0.2
		elif rockyorgassy == 3:
			rockyorgassy = "gassy"
			planetradius = randf()*0.475 + 0.4
		var planethabitable = false
		if rockyorgassy == "rocky":
			if planettemperature > 240:
				if planettemperature < 333:
					var ishabitable = randi()%2
					if ishabitable == 1:
						planethabitable = true
		var seed1 = randi()%5000
		var period = randi()%156 + 99
		var persistence = randf()*0.5 + 0.49
		var lacunarity = randf()*3.4 + 0.59
		var resourceheatmultiplier = planettemperature / 273
		var resourcesizemultiplier = resourceheatmultiplier
		var totalresources = resourcesizemultiplier * (randi()%200)
		var resourcepilesize = 0
		var resourcelocationxlist = []
		var resourcelocationylist = []
		var resourcetypelist = []
		var resourcesizelist = []
		if rockyorgassy == "rocky":
			while totalresources > 0:
				var sizegrouping = randi()%2 + 1
				if sizegrouping == 1:
					resourcepilesize = randi()% 9 + 1
				elif sizegrouping == 2:
					resourcepilesize = randi()% 40 + 10
				elif sizegrouping == 3:
					resourcepilesize = randi()% 25 + 50
				var resourcetype = randi()% 5 + 1
				var resourcelocation = Vector2(randi()%1098 + 1, randi()%698 + 1)
				resourcelocationxlist.append(resourcelocation.x)
				resourcelocationylist.append(resourcelocation.y)
				resourcetypelist.append(resourcetype)
				resourcesizelist.append(resourcepilesize)
				totalresources -= resourcepilesize
		elif rockyorgassy == "gassy":
			resourcelocationxlist = null
			resourcelocationylist = null
			resourcetypelist = null
			resourcesizelist = null
		var colorchoiceR = randf()*0.8 + 0.2
		var colorchoiceG = randf()*0.8 + 0.2
		var colorchoiceB = randf()*0.8 + 0.2
		var sealevel = 0.35
		var innerR = randf()*1.0 + 0.05
		var innerG = randf()*1.0 + 0.05
		var innerB = randf()*1.0 + 0.3
		var outerR = randf()*1.0 + 0.1
		var outerG = randf()*1.0 + 0.1
		var outerB = randf()*1.0 + 0.2
		var planetgravity = planetradius * 500
		system_dict[planetname + "planetgravity"] = planetgravity
		system_dict[planetname + "planettemperature"] = planettemperature
		system_dict[planetname + "planethabitable"] = planethabitable
		system_dict[planetname + "orbitradius"] = orbitradius
		system_dict[planetname + "rockyorgassy"] = rockyorgassy
		system_dict[planetname + "planetradius"] = planetradius
		system_dict[planetname + "seed1"] = seed1
		system_dict[planetname + "period"] = period
		system_dict[planetname + "persistence"] = persistence
		system_dict[planetname + "lacunarity"] = lacunarity
		system_dict[planetname + "colorchoiceR"] = colorchoiceR
		system_dict[planetname + "colorchoiceG"] = colorchoiceG
		system_dict[planetname + "colorchoiceB"] = colorchoiceB
		system_dict[planetname + "resourcelocationxlist"] = resourcelocationxlist
		system_dict[planetname + "resourcelocationylist"] = resourcelocationylist
		system_dict[planetname + "resourcetypelist"] = resourcetypelist
		system_dict[planetname + "resourcesizelist"] = resourcesizelist
		system_dict[planetname + "sealevel"] = sealevel
		system_dict[planetname + "innerR"] = innerR
		system_dict[planetname + "innerG"] = innerG
		system_dict[planetname + "innerB"] = innerB
		system_dict[planetname + "outerR"] = outerR
		system_dict[planetname + "outerG"] = outerG
		system_dict[planetname + "outerB"] = outerB
	return system_dict

func createuniverse():
	#create universe database
	var namelist = loadWords()
	var universefile = File.new()
	universefile.open("res://systemdata/universe.json", File.WRITE)
	#number of stars in universe
	var count = numstars
	#create dictionary to hold data
	var systemdict = {}
	while count > 0:
		#iterate through and pick random names from text file of random names
		var namechoice = namelist[randi() % namelist.size()]
		#for each star, create system data
		systemdict = createsystem(namechoice)
		universefile.store_line(to_json(systemdict))
		#remove chosen name from active list
		namelist.erase(namechoice)
		count -= 1
	universefile.close()

func romannumerals(number):
	#planet naming helper function
	if number == 1:
		return "I"
	elif number == 2:
		return "II"
	elif number == 3:
		return "III"
	elif number == 4:
		return "IV"
	elif number == 5:
		return "V"
	elif number == 6:
		return "VI"
	elif number == 7:
		return "VII"
	elif number == 8:
		return "VIII"
	elif number == 9:
		return "IX"
	else:
		pass
