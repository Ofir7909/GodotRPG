tool
extends Node2D
class_name LevelTemplate

#variables
export var update = false setget do_update


func do_update(update = null):
	update()


func _draw() -> void:
	DrawLineBetweenChildren(self, false, true)


func DrawLineBetweenChildren(node: Node2D, includeParent: bool, recursive: bool) -> void:
	var children := node.get_children()
	var pointsArray = PoolVector2Array()

	if includeParent:
		pointsArray.append(node.get_global_position())

	for i in range(0, children.size()):
		pointsArray.append(children[i].get_global_position())
		if recursive:
			DrawLineBetweenChildren(children[i], true, true)

	if pointsArray.size() < 2:
		return
	draw_polyline(pointsArray, Color(1, 0, 0))
