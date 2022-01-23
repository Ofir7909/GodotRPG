tool
extends Node2D
class_name LevelTemplateNode

# public variables
export var radius: float = 0 setget set_radius

func set_radius(value: float) -> void:
	radius = value
	update()

func _draw() -> void:
	draw_circle(Vector2(), radius, Color(0,0,1, 0.2))
