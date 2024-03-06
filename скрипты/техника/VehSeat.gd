extends Area3D
class_name seat

enum type {
	DRIVER,
	DRIVER_HELPER,
	PASSENGER
}

@export var TYPE:type = type.PASSENGER
@export var max_view:Vector2 = Vector2(-110, 110)

func get_seat_type():
	return TYPE
