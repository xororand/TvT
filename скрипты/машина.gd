extends VehicleBody3D

var entered = false
var водитель:игрок_контроллер = null

@export var модель_руля:MeshInstance3D # TODO: поворот руля

@export var точка_входа_водителя:Node3D
@export var точка_выхода_водителя:Node3D

@export var black_steam_effect:GPUParticles3D

@export var hull_hp:float = 100
@onready var max_hull_hp:float = hull_hp

var max_rpm = 120
var max_torque = 1000


var break_on = false

func _physics_process(delta):
	if hull_hp / max_hull_hp <= 0.5:
		black_steam_effect.emitting = true
	else:
		black_steam_effect.emitting = false
	
	var acceleration = 0.0
	if entered and водитель != null:
		break_on = false
		steering = lerp(steering, Input.get_axis("движ_право", "движ_лево") * 0.5, 1*delta)
		acceleration = Input.get_axis("движ_назад", "движ_вперед")
		модель_руля.rotation.z = -steering
	if not entered:
		steering = 0.0
		acceleration = 0.0
		break_on = true
	
	var rpm = $BL_0.get_rpm()
	var _max_rpm = max_rpm
	if acceleration < 0 and rpm < 0:
		acceleration *= 0.3
		_max_rpm = -max_rpm * 0.5
	
	if break_on:
		$BL_0.brake = float(mass * 2 / 100)
		$BR_1.brake = float(mass * 2 / 100)
	
	$BL_0.engine_force = acceleration * max_torque * (1 - rpm / _max_rpm)
	rpm = $BR_1.get_rpm()
	$BR_1.engine_force = acceleration * max_torque * (1 - rpm / _max_rpm)

func _input(event):
	if Input.is_action_just_pressed("использовать") and водитель != null and entered: # выход из машины
		водитель.can_fire = true
		водитель.can_sitdown = true
		водитель.bypass_sitdown_raycasts = false
		entered = false
		водитель.in_vehicle = false
		водитель.show_text("")
		водитель.get_node("CollisionShape3D").disabled = false
		водитель.reparent(точка_выхода_водителя)
		водитель.position = Vector3.ZERO
		водитель.handitem.visible = true
		водитель.reparent(globals.группа_игроков)
		водитель.rotation = Vector3.ZERO
		водитель.rotate_y(135)
		return
	
	if Input.is_action_just_pressed("использовать") and водитель != null and !entered: # вход в машину
		водитель.can_fire = false
		водитель.can_sitdown = false
		водитель.issitdown = false
		водитель.bypass_sitdown_raycasts = true
		entered = true
		водитель.in_vehicle = true
		водитель.reparent(точка_входа_водителя)
		водитель.get_node("CollisionShape3D").disabled = true
		водитель.position = Vector3.ZERO
		водитель.rotation = Vector3.ZERO
		водитель.handitem.visible = false
		водитель.show_text("Для выхода из автомобиля нажмите У")

func hit():
	hull_hp -= 1
	print("hit")
	if hull_hp <= 0:
		destroy_car()

func destroy_car():
	self.queue_free()

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
