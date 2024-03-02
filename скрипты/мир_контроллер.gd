extends Node3D

@export_category("Объекты")
@export var группа_игроков:Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	globals.группа_игроков = группа_игроков

