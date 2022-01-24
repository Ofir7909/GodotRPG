extends Resource
class_name Graph

class Edge:
	var a: int
	var b: int
	
	func _init(_a: int, _b: int) -> void:
		self.a = _a
		self.b = _b
		
	func Equal(other: Edge, bidirectional: bool = true):
		if(self == other):
			return true
		if(bidirectional and self == Edge.new(other.b, other.a)):
			return true
		return false

var vertices := {} # {int: Vector2}
var edges : Array = []

var _lastFreeId : int = 0

## Returns index not in use.
func GetAvailableVertexIndex() -> int :
	while _lastFreeId in vertices:
		_lastFreeId += 1
		
	return _lastFreeId

## Adds Vetex to the graph.
## id must be 0 or greater.
## if id is taken, ovverides the value
## Return: index of the added vertex.
func AddVertex(id: int, v: Vector2):
	vertices[id] = v
	return vertices.size() - 1

func ConnectPoints(a: int, b: int):
	return self.AddEdge(Edge.new(a,b))

## Adds Edge to the graph, If the edge is not already in the graph
## Return: index of the added edge. or -1 if already exist.
func AddEdge(e: Edge):
	for i in range(edges.size()):
		if(e.Equal(edges[i], true)):
			return -1
	edges.append(e)
	return edges.size() - 1
	
func ArePointsConnected(a: int, b: int):
	var edge := Edge.new(a,b)
	for e in edges:
		if edge.Equal(e):
			return true
	return false
	
func GetClosestPoint(p: Vector2) -> int:
	var min_dist = INF
	var min_dist_idx := 0
	for i in vertices:
		var dist = p.distance_to(vertices[i])
		if(dist < min_dist):
			min_dist = dist
			min_dist_idx = i
	return min_dist_idx

## Returns a new graph with same verticies(not same order),
## and only the edges needed for the shortest path connecting all the verticies
func MinimumSpanningTree() -> Graph:
	#Prim's Algorithm
	# Initialize the Graph
	var nodes := vertices.duplicate()
	var graph = get_script().new()
	
	if nodes.size() == 0:
		return graph
	# Add the first point
	var first_key = nodes.keys()[0]
	graph.AddVertex(first_key, nodes[first_key])
	nodes.erase(first_key)

	# Repeat until no more nodes remain
	while nodes:
		var min_dist = INF  # Minimum distance found so far
		var min_p = null  # Position of that node
		var p = null  # Current position
		# Loop through the points in the graph
		for p1 in graph.vertices:
			# Loop through the remaining nodes in the given array
			for p2 in nodes:
				# If the node is closer, make it the closest
				if vertices[p1].distance_to(vertices[p2]) < min_dist:
					min_dist = vertices[p1].distance_to(vertices[p2])
					min_p = p2
					p = p1
		# Insert the resulting node into the graph and add
		# its connection
		#var n = graph.vertices.size()
		
		graph.AddVertex(min_p, nodes[min_p])
		nodes.erase(min_p)
		
		graph.ConnectPoints(graph.GetClosestPoint(vertices[p]), min_p)
	
	return graph
