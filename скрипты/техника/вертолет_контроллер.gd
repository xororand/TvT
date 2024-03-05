extends RigidBody3D
class_name Вертолет

var is_started:bool = false
var coef_start:float = 0.0
var delta_coef_start:float = 0.1#0.8

var main_rotor_tyaga:float = 0.0
var main_rotor_torque:float = 10.0

var угол_атаки:float = 0.0
var угол_крена:float = 0.0
var угол_рысканья:float = 0.0

@onready var alt_set = self.position.y

var entered = false
var водитель:игрок_контроллер = null

@export var модель_главный_ротор:MeshInstance3D
@export var модель_задний_ротор:MeshInstance3D
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
	
	модель_главный_ротор.rotation.y += delta * max_main_rotor_rpm * abs(exp((coef_start * 10.0) - 10.0)) # анимация ротора
	
	if модель_главный_ротор.rotation.y >= 360.0:
		модель_главный_ротор.rotation.y = 0.0
	
	#velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	#if Input.is_action_pressed("повышение_тяги_главного_ротора") and entered and водитель != null:
		#main_rotor_tyaga += delta
	#if Input.is_action_pressed("понижение_тяги_главного_ротора") and entered and водитель != null:
	#	main_rotor_tyaga -= delta
	
	#main_rotor_tyaga = alt_set / self.position.y * -velocity.y
	main_rotor_tyaga += Input.get_axis("понижение_тяги_главного_ротора", "повышение_тяги_главного_ротора") * delta
	main_rotor_tyaga = clamp(main_rotor_tyaga, 0.0, 1.0)
	
	угол_атаки -= угол_атаки * 0.1
	угол_крена -= угол_крена * 0.1
	#угол_рысканья -= угол_рысканья * 0.1
	
	if entered:
		угол_атаки += -Input.get_axis("движ_назад", "движ_вперед") * coef_start * delta * 5.0
		угол_крена += -Input.get_axis("движ_лево", "движ_право") * coef_start * delta * 5.0
		#угол_рысканья += Input.get_axis("рысканье_лево", "рысканье_право") * coef_start * delta * 3.0
	
	rotation_degrees.x -= угол_атаки
	rotation_degrees.z -= угол_крена
	apply_force(модель_задний_ротор.transform.basis.x * Input.get_axis("рысканье_лево", "рысканье_право") * (main_rotor_tyaga / 3.0) * main_rotor_torque / 2.0, модель_задний_ротор.transform.origin)
	#rotation_degrees.y -= угол_рысканья
	
	rotation_degrees.x -= rotation_degrees.x * 0.05
	rotation_degrees.z -= rotation_degrees.z * 0.05
	#rotation_degrees.y -= rotation_degrees.y * 0.1
	
	var velocity = transform.basis.y * main_rotor_tyaga * coef_start * main_rotor_torque
	#velocity.x -= velocity.x * 0.05 * delta
	#velocity.z -= velocity.z * 0.05 * delta
	if abs(velocity.x) <= 0.005:
		velocity.x = 0.0
	if abs(velocity.z) <= 0.005:
		velocity.z = 0.0
	print(velocity)
	apply_force(velocity)
	#print(velocity)
	#move_and_slide()

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
