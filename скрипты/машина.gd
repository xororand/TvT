extends VehicleBody3D

var entered = false
var водитель:игрок_контроллер = null

@export var модель_руля:MeshInstance3D # TODO: поворот руля

@export var точка_водителя:Node3D

var max_rpm = 80
var max_torque = 800

func _physics_process(delta):
	if entered and водитель != null:
		steering = lerp(steering, Input.get_axis("движ_право", "движ_лево") * 0.4, 2*delta)
		var acceleration = Input.get_axis("движ_назад", "движ_вперед")
		
		var rpm = $BL_0.get_rpm()
		if acceleration < 0 and rpm < 0:
			acceleration *= 0.5
		print(rpm)
		$BL_0.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
		rpm = $BR_1.get_rpm()
		$BR_1.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
		
		модель_руля.rotation.z = -steering

func _input(event):
	if Input.is_action_just_pressed("использовать") and водитель != null and entered:
		pass
	if Input.is_action_just_pressed("использовать") and водитель != null and !entered:
		entered = true
		водитель.in_vehicle = true
		водитель.show_text("")
		водитель.reparent(точка_водителя)
		водитель.get_node("CollisionShape3D").disabled = true
		водитель.position = Vector3.ZERO
		водитель.rotation = Vector3.ZERO
		водитель.handitem.visible = false
	

func _on_водительarea_3d_body_entered(body):
	if not body.is_in_group("игроки"):
		return
	if not entered:
		водитель = body
	body.show_text("Для того чтобы сесть нажмите У")


func _on_водительarea_3d_body_exited(body):
	if not body.is_in_group("игроки"):
		return
	if not entered:
		водитель = null
	body.show_text("")
