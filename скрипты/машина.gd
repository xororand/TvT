extends VehicleBody3D

var entered = false
var водитель:игрок_контроллер = null

@export var модель_руля:MeshInstance3D # TODO: поворот руля

@export var точка_входа_водителя:Node3D
@export var точка_выхода_водителя:Node3D

var max_rpm = 120
var max_torque = 800

func _physics_process(delta):
	if entered and водитель != null:
		steering = lerp(steering, Input.get_axis("движ_право", "движ_лево") * 0.4, 1*delta)
		var acceleration = Input.get_axis("движ_назад", "движ_вперед")
		
		var rpm = $BL_0.get_rpm()
		var _max_rpm = max_rpm
		if acceleration < 0 and rpm < 0:
			acceleration *= 0.3
			_max_rpm = -max_rpm * 0.4
		print(_max_rpm)
		$BL_0.engine_force = acceleration * max_torque * (1 - rpm / _max_rpm)
		rpm = $BR_1.get_rpm()
		$BR_1.engine_force = acceleration * max_torque * (1 - rpm / _max_rpm)
		
		модель_руля.rotation.z = -steering

func _input(event):
	if Input.is_action_just_pressed("использовать") and водитель != null and entered:
		водитель.can_fire = true
		entered = false
		водитель.in_vehicle = false
		водитель.show_text("")
		водитель.get_node("CollisionShape3D").disabled = false
		водитель.reparent(точка_выхода_водителя)
		водитель.position = Vector3.ZERO
		водитель.rotation = Vector3.ZERO
		водитель.handitem.visible = true
		водитель.reparent(globals.группа_игроков)
		return
	
	if Input.is_action_just_pressed("использовать") and водитель != null and !entered:
		водитель.can_fire = false
		entered = true
		водитель.in_vehicle = true
		водитель.reparent(точка_входа_водителя)
		водитель.get_node("CollisionShape3D").disabled = true
		водитель.position = Vector3.ZERO
		водитель.rotation = Vector3.ZERO
		водитель.handitem.visible = false
		водитель.show_text("Для выхода из автомобиля нажмите У")
	

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
