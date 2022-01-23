extends Node2D

#variables
export var seedNumber : int = 0
export var initialRoomCount : int = 80
export var initialDistributionDistance: float = 10
export var minRoomSize := Vector2(2,2)
export var maxRoomSize := Vector2(8,8)
export var mainRoomRatio :float = 0.2

var rand := RandomNumberGenerator.new()
var rooms := Array()
var graph := Graph.new()
#var verts := PoolVector2Array()
#var links := PoolIntArray()

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
	update() #update draw

func GenerateRooms():
	for i in range(initialRoomCount):
		var sizeX = int(round(lerp(minRoomSize.x, maxRoomSize.x, clamp(rand.randfn(0.5,0.5), 0, 1))))
		var sizeY = int(round(lerp(minRoomSize.y, maxRoomSize.y, clamp(rand.randfn(0.5,0.5), 0, 1))))
		var size := Vector2(sizeX, sizeY)
		var pos = Vector2(rand.randf_range(-1,1), rand.randf_range(-1,1)) * initialDistributionDistance
		pos = (pos-(size / 2)).round()
		var newRoom = DungeonRoom.new(pos,size)
		rooms.append(newRoom)
		
	# choose main rooms
	var sorted_rooms = rooms.duplicate()
	sorted_rooms.sort_custom(DungeonRoom, "compareArea")
	for i in range(initialRoomCount * mainRoomRatio):
		sorted_rooms[i].main = true

func SeperateRoomsSteering() -> bool:
	var resolved: bool = true #assume resovled
	for i in range(initialRoomCount):
		#calculate velocity
		var velocity = Vector2()
		for j in range(initialRoomCount):
			if(j == i): 
				continue
			velocity += rooms[i].CalculateVelocity(rooms[j])
		
		# move by 1 in direction of velocity, including diagonals
		if(velocity.length_squared() > 0):
			resolved = false
			velocity = velocity.normalized();
			rooms[i].position.x += 0 if abs(velocity.x) < 0.5 else (1 if velocity.x > 0 else -1)
			rooms[i].position.y += 0 if abs(velocity.y) < 0.5 else (1 if velocity.y > 0 else -1)
	return resolved

func SeperateRoomsPhysics():
	# Generate Colliders for every room
	var bodies = Array()
	var parent = Node2D.new()
	self.add_child(parent)
	
	for i in range(initialRoomCount):
		var rb = RigidBody2D.new()
		rb.set_position(rooms[i].getCenter())
		rb.gravity_scale = 0
		rb.mode = RigidBody2D.MODE_CHARACTER
		rb.can_sleep = true
		
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.set_extents(rooms[i].size / 2)
		col.set_shape(shape)
		
		rb.add_child(col)
		parent.add_child(rb)
		bodies.append(rb)
	
	yield(WaitForColisionResolve(bodies), "completed")
	#snap to grid
	for i in range(initialRoomCount):
		rooms[i].setCenter(bodies[i].position.round())
	
func WaitForColisionResolve(rigidbodiesArray: Array) -> void:
	#wait for the rigidbodies to approximetly be static, uses round()
	#would be better to use physics.simulate() to simulate inside the function
	#insted of waiting fot the game physics
	
	#store previous positions
	var positions = PoolVector2Array()
	for rb in rigidbodiesArray:
		positions.append(rb.position)
		
	var resolved = false
	while !resolved:
		yield(get_tree().create_timer(0.5), "timeout")
		resolved = true #assume resolved unless we find an object who moved.		
		for i in range(rigidbodiesArray.size()):
			if positions[i] != rigidbodiesArray[i].position.round():
				positions[i] = rigidbodiesArray[i].position.round()
				resolved = false
	yield(get_tree().create_timer(1), "timeout")

func GenerateGraph():
	# Get Verticies
	for i in range(initialRoomCount):
		if(rooms[i].main):
			graph.AddVertex(rooms[i].getCenter())
			#verts.append(rooms[i].getCenter())
	
	# triangulate
	var triangles = Geometry.triangulate_delaunay_2d(graph.vertices)
	for i in range(0, triangles.size(), 3):
		graph.ConnectPoints(triangles[i], triangles[i+1])
		graph.ConnectPoints(triangles[i+1], triangles[i+2])
		graph.ConnectPoints(triangles[i+2], triangles[i])
	
	# minimum spanning tree
	graph = graph.MinimumSpanningTree()

func _draw() -> void:
	DrawRooms()

func DrawRooms():
	for r in rooms:
		var color = Color(1,0,0) if r.main else Color(rand.randf(), rand.randf(),rand.randf())
		var rect = Rect2(r.position, r.size)
		rect.position *= 16
		rect.size *= 16
		draw_rect(rect, color, true)
		
	for e in graph.edges:
		var color = Color(0,1,0)
		var start = graph.vertices[e.a] * 16
		var end = graph.vertices[e.b] * 16
		draw_line(start, end, color)
