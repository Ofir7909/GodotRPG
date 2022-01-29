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

	if (overlap.x <= 0) or (overlap.y <= 0):
		#no collision
		return Vector2(0, 0)

	if diff.length_squared() <= 0:
		# rectangles overlapping
		return Vector2(0, 0)

	var scale = repelDecayCoefficient / diff.length_squared()
	diff = diff.normalized()
	diff *= scale
	return diff


static func CheckCollisionLineVsLine(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	var b := a2 - a1
	var d := b2 - b1
	var bDotDPerp := b.x * d.y - b.y * d.x

	# if b dot d == 0, it means the lines are parallel so have infinite intersection points
	if bDotDPerp == 0:
		return false

	var c := b1 - a1
	var t := (c.x * d.y - c.y * d.x) / bDotDPerp
	if t < 0 || t > 1:
		return false

	var u := (c.x * b.y - c.y * b.x) / bDotDPerp
	if u < 0 || u > 1:
		return false

	return true


func CheckCollisionLine(start: Vector2, end: Vector2) -> bool:
	#right side
	if CheckCollisionLineVsLine(start, end, position, position + Vector2.DOWN * size.y):
		return true
	#left side
	if CheckCollisionLineVsLine(start, end, position + size, position + Vector2.RIGHT * size.x):
		return true
	#top side
	if CheckCollisionLineVsLine(start, end, position, position + Vector2.RIGHT * size.x):
		return true
	#bottom side
	if CheckCollisionLineVsLine(start, end, position + size, position + Vector2.DOWN * size.y):
		return true
	return false
