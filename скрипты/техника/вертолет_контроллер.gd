extends CharacterBody3D
class_name Вертолет

var is_started:bool = false
var coef_start:float = 0.0
var delta_coef_start:float = 0.8#0.1

var main_rotor_tyaga:float = 0.0
var main_rotor_torque:float = 5.0

var угол_атаки:float = 0.0
var угол_крена:float = 0.0
var угол_рысканья:float = 0.0

var entered = false
var водитель:игрок_контроллер = null

@export var модель_главный_ротор:MeshInstance3D
@export var модель_контроллера:MeshInstance3D

@export var точка_входа_водителя:Node3D
@export var точка_выхода_водителя:Node3D

@export var black_steam_effect:GPUParticles3D

@export var hull_hp:float = 100.0
@onready var max_hull_hp:float = hull_hp

@export var max_main_rotor_rpm:float = 120.0

func _physics_process(delta):
	if is_started:
		coef_start += delta * delta_coef_start
	else:
		coef_start -= delta * delta_coef_start
	coef_start = clamp(coef_start, 0.0, 1.0)
	
	if hull_hp / max_hull_hp <= 0.5:
		black_steam_effect.emitting = true
	else:
		black_steam_effect.emitting = false
	
	модель_главный_ротор.rotation.y += delta * max_main_rotor_rpm * abs(exp((coef_start * 10.0) - 10.0))
	if модель_главный_ротор.rotation.y >= 360.0:
		модель_главный_ротор.rotation.y = 0.0
	
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	if Input.is_action_pressed("повышение_тяги_главного_ротора") and entered and водитель != null:
		main_rotor_tyaga += delta * 2.0
	else:
		main_rotor_tyaga -= delta * 0.5
	main_rotor_tyaga = clamp(main_rotor_tyaga, 0.0, 1.0)
	
	if entered and водитель != null:
		print(Input.get_axis("движ_назад", "движ_вперед"))
		угол_атаки += -Input.get_axis("движ_назад", "движ_вперед") * coef_start * delta * 0.1
		угол_крена += -Input.get_axis("движ_лево", "движ_право") * coef_start * delta * 0.1
		угол_рысканья += Input.get_axis("рысканье_лево", "рысканье_право") * coef_start * delta * 0.1
	
	rotation_degrees.x -= угол_атаки
	rotation_degrees.z -= угол_крена
	rotation_degrees.y -= угол_рысканья
	
	velocity += transform.basis.y * main_rotor_tyaga * coef_start * (ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0) * delta
	
	move_and_slide()

func _input(event):
	if Input.is_action_just_pressed("старт_двигателя_авиация") and entered and водитель != null:
		is_started = !is_started
	
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
		водитель = null
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
		водитель.show_text("Для выхода из автомобиля нажмите F")

func hit():
	hull_hp -= 1
	print("hit")
	if hull_hp <= 0:
		destroy_veh()

func destroy_veh():
	self.queue_free()

func _on_пилотarea_3d_body_entered(body):
	if not body.is_in_group("игроки"):
		return
	if not entered:
		водитель = body
	body.show_text("Для того чтобы сесть нажмите F")

func _on_пилотarea_3d_body_exited(body):
	if not body.is_in_group("игроки"):
		return
	if not entered:
		print("удаляем водилу")
		водитель = null
		body.show_text("")
