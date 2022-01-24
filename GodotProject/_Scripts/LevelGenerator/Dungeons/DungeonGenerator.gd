extends Node2D

#variables
export var seedNumber: int = 0
export var initialRoomCount: int = 80
export var initialDistributionDistance: float = 10
export var minRoomSize := Vector2(2, 2)
export var maxRoomSize := Vector2(8, 8)
export(float, 0, 1, 0.01) var mainRoomRatio: float = 0.2
export(float, 0, 1, 0.01) var loopingRatio: float = 0.1

var rand := RandomNumberGenerator.new()
var rooms := Array()
var graph := Graph.new()


# Functions
func _ready() -> void:
	if seedNumber != 0:
		rand.set_seed(seedNumber)
	else:
		rand.randomize()

	GenerateRooms()

	var resolved = false
	while !resolved:
		resolved = SeperateRoomsSteering()
	GenerateGraph()
	update()  #update draw


func GenerateRooms() -> void:
	for i in range(initialRoomCount):
		var sizeX = int(
			round(lerp(minRoomSize.x, maxRoomSize.x, clamp(rand.randfn(0.5, 0.5), 0, 1)))
		)
		var sizeY = int(
			round(lerp(minRoomSize.y, maxRoomSize.y, clamp(rand.randfn(0.5, 0.5), 0, 1)))
		)
		var size := Vector2(sizeX, sizeY)
		var pos = (
			Vector2(rand.randf_range(-1, 1), rand.randf_range(-1, 1))
			* initialDistributionDistance
		)
		pos = (pos - (size / 2)).round()
		var newRoom = DungeonRoom.new(pos, size)
		rooms.append(newRoom)

	# choose main rooms
	var sorted_rooms = rooms.duplicate()
	sorted_rooms.sort_custom(DungeonRoom, "compareArea")
	for i in range(initialRoomCount * mainRoomRatio):
		sorted_rooms[i].main = true


func SeperateRoomsSteering() -> bool:
	var resolved: bool = true  #assume resovled
	for i in range(initialRoomCount):
		#calculate velocity
		var velocity = Vector2()
		for j in range(initialRoomCount):
			if j == i:
				continue
			velocity += rooms[i].CalculateVelocity(rooms[j])

		# move by 1 in direction of velocity, including diagonals
		if velocity.length_squared() > 0:
			resolved = false
			velocity = velocity.normalized()
			rooms[i].position.x += 0 if abs(velocity.x) < 0.5 else (1 if velocity.x > 0 else -1)
			rooms[i].position.y += 0 if abs(velocity.y) < 0.5 else (1 if velocity.y > 0 else -1)
	return resolved


func GenerateGraph() -> void:
	# Get Verticies
	var delaunay := Graph.new()
	for i in range(initialRoomCount):
		if rooms[i].main:
			delaunay.AddVertex(delaunay.GetAvailableVertexIndex(), rooms[i].getCenter())

	# triangulate
	var triangles = Geometry.triangulate_delaunay_2d(delaunay.vertices.values())
	for i in range(0, triangles.size(), 3):
		delaunay.ConnectPoints(triangles[i], triangles[i + 1])
		delaunay.ConnectPoints(triangles[i + 1], triangles[i + 2])
		delaunay.ConnectPoints(triangles[i + 2], triangles[i])

	# Minimum spanning tree
	graph = delaunay.MinimumSpanningTree()

	# Looping
	var edgesToAdd := int((delaunay.edges.size() - graph.edges.size()) * loopingRatio)
	var shuffled := delaunay.edges.duplicate()
	shuffled.shuffle()
	var i = 0

	while edgesToAdd > 0 && i < shuffled.size():
		var edge = shuffled[i]
		if not graph.ArePointsConnected(edge.a, edge.b):
			graph.AddEdge(edge)
			edgesToAdd -= 1
		i += 1


func _draw() -> void:
	DrawRooms()


func DrawRooms() -> void:
	#Draw Rooms
	for r in rooms:
		var color = Color(1, 0, 0) if r.main else Color(rand.randf(), rand.randf(), rand.randf())
		var rect = Rect2(r.position, r.size)
		rect.position *= 16
		rect.size *= 16
		draw_rect(rect, color, true)

	#Draw Connections
	for e in graph.edges:
		var color = Color(0, 1, 0)
		var start = graph.vertices[e.a] * 16
		var end = graph.vertices[e.b] * 16
		draw_line(start, end, color)
