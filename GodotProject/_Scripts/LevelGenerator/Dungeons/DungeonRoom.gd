class_name DungeonRoom

var position: Vector2
var size: Vector2
var main: bool = false

func _init(pos: Vector2, size: Vector2) -> void:
	self.position = pos
	self.size = size

func getCenter() -> Vector2:
	return position + (size / 2)
	
func setCenter(v: Vector2) -> void:
	position = v - (size / 2)
	
func getEnd() -> Vector2:
	return position + size
	
func getArea() -> float:
	return size.x * size.y
	
static func compareArea(a: DungeonRoom, b: DungeonRoom) -> bool:
	#will sort the array by size, from largest to smallest
	return a.getArea() > b.getArea()

func CalculateVelocity(other: DungeonRoom) -> Vector2:
	var repelDecayCoefficient: float = 1.0
	
	var overlap = Vector2(
		min(self.getEnd().x, other.getEnd().x) - max(self.position.x, other.position.x),
		min(self.getEnd().y, other.getEnd().y) - max(self.position.y, other.position.y)
	)
	var diff: Vector2 = self.getCenter() - other.getCenter()
	
	if (overlap.x<=0) or (overlap.y<=0):
		#no collision
		return Vector2(0,0)
		
	if(diff.length_squared() <= 0):
		# rectangles overlapping
		return Vector2(0,0)
		
	var scale = repelDecayCoefficient / diff.length_squared();
	diff = diff.normalized();
	diff *= scale;
	return diff
