extends Resource
class_name Graph

class Edge:
	var a: int
	var b: int
	
	func _init(a: int, b: int) -> void:
		self.a = a
		self.b = b
		
	func Equal(other: Edge, bidirectional: bool = true):
		if(self == other):
			return true
		if(bidirectional and self == Edge.new(other.b, other.a)):
			return true
		return false

var vertices := PoolVector2Array()
var edges : Array = []

func AddVertex(v: Vector2):
	vertices.append(v)
	
func ConnectPoints(a: int, b: int):
	self.AddEdge(Edge.new(a,b))
	
func AddEdge(e: Edge):
	for i in range(edges.size()):
		if(e.Equal(edges[i])):
			return
	edges.append(e)
	
func GetClosestPoint(p: Vector2) -> int:
	var min_dist = INF
	var min_dist_idx := 0
	for i in range(vertices.size()):
		var dist = p.distance_to(vertices[i])
		if(dist < min_dist):
			min_dist = dist
			min_dist_idx = i
	return min_dist_idx
	
func MinimumSpanningTree() -> Graph:
	#Prim's Algorithm
	# Initialize the Graph and add the first point
	var nodes := Array(vertices) # Create a copy
	var path = get_script().new()
	path.AddVertex(nodes.pop_front())

	# Repeat until no more nodes remain
	while nodes:
		var min_dist = INF  # Minimum distance found so far
		var min_p = null  # Position of that node
		var p = null  # Current position
		# Loop through the points in the path
		for p1 in path.vertices:
			# Loop through the remaining nodes in the given array
			for p2 in nodes:
				# If the node is closer, make it the closest
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		# Insert the resulting node into the path and add
		# its connection
		var n = path.vertices.size()
		path.AddVertex(min_p)
		path.ConnectPoints(path.GetClosestPoint(p), n)
		# Remove the node from the array so it isn't visited again
		nodes.erase(min_p)
	return path
