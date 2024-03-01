extends Node3D

var hitten:bool = false


func _physics_process(delta):
	if hitten:
		rotation.z -= delta
	else:
		rotation.z += delta
	
	rotation.z = clamp(rotation.z, -90.0, 0.0)
	
	if hitten and rotation.z > -80.0:
		hitten = false

func hit():
	print("hit")
	hitten = true

