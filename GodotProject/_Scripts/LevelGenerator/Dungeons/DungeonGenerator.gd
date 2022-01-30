extends Node2D

#variables
export var seedNumber: int = 0
export var tileSet: TileSet

export var initialRoomCount: int = 50
export var initialDistributionDistance: float = 10
export var minRoomSize := Vector2(6, 6)
export var maxRoomSize := Vector2(12, 12)
enum BORDER { no, small, large }
export(BORDER) var roomsBorder = BORDER.small
export(float, 0, 1, 0.01) var mainRoomRatio: float = 0.2
export(float, 0, 1, 0.01) var loopingRatio: float = 0.1
export var CorridorWidth: int = 2

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
	CreateTilemap()
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
	var msp := delaunay.MinimumSpanningTree()

	# Looping
	var edgesToAdd := int((delaunay.edges.size() - msp.edges.size()) * loopingRatio)
	var shuffled := delaunay.edges.duplicate()
	shuffled.shuffle()
	var i = 0

	while edgesToAdd > 0 && i < shuffled.size():
		var edge = shuffled[i]
		if not msp.ArePointsConnected(edge.a, edge.b):
			msp.AddEdge(edge)
			edgesToAdd -= 1
		i += 1

	graph = msp


func CreateTilemap() -> void:
	#Create the tilemap node
	var dungeonTilemap = TileMap.new()
	add_child(dungeonTilemap)
	dungeonTilemap.mode = TileMap.MODE_SQUARE
	dungeonTilemap.tile_set = tileSet
	dungeonTilemap.cell_size = tileSet.autotile_get_size(0)

	# Add rooms to the tilemap
	for r in rooms:
		var collide := false
		for e in graph.edges:
			var e_start: Vector2 = graph.vertices[e.a]
			var e_end: Vector2 = graph.vertices[e.b]
			var e_delta: Vector2 = e_end - e_start
			var e_mid: Vector2 = e_start + e_delta.x * Vector2.RIGHT
			# split to make a 90 degree line
			if r.CheckCollisionLine(e_start, e_mid):
				collide = true
			if r.CheckCollisionLine(e_mid, e_end):
				collide = true

		if collide:
			var border = 1 if roomsBorder == BORDER.large else 0.5 if roomsBorder == BORDER.small else 0
			for x in range(r.position.x + border, r.position.x + r.size.x - border):
				for y in range(r.position.y + border, r.position.y + r.size.y - border):
					dungeonTilemap.set_cell(x, y, 0)

	#Corridors
	for e in graph.edges:
		CarvePath(dungeonTilemap, graph.vertices[e.a], graph.vertices[e.b], CorridorWidth)

	#update the tilemap
	dungeonTilemap.update_bitmask_region()


func CarvePath(tilemap: TileMap, start: Vector2, end: Vector2, width: int = 1) -> void:
	var delta := end - start
	var delta_x_dir := sign(delta.x)
	var delta_y_dir := sign(delta.y)
	
	var radius : int = round(float(width)/2)	
	start = start.round()
	end = end.round()
	
	
	for x in range(start.x - radius * delta_x_dir, end.x + radius * delta_x_dir, delta_x_dir):
		for y_offset in range(-radius, width - radius, 1):
			tilemap.set_cell(x, start.y + y_offset, 0)
	for y in range(start.y - radius * delta_y_dir, end.y + radius * delta_y_dir, delta_y_dir):
		for x_offset in range(-radius, width - radius, 1):
			tilemap.set_cell(end.x + x_offset, y, 0)

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
		var e_start: Vector2 = graph.vertices[e.a]
		var e_end: Vector2 = graph.vertices[e.b]
		var e_delta: Vector2 = e_end - e_start
		var e_mid: Vector2 = e_start + e_delta.x * Vector2.RIGHT

		draw_line(e_start * 16, e_mid * 16, Color(0, 1, 0))
		draw_line(e_mid * 16, e_end * 16, Color(0, 1, 0))

		var start = graph.vertices[e.a] * 16
		var end = graph.vertices[e.b] * 16
		draw_line(start, end, Color(0, 0, 1))
