extends RigidBody3D
class_name Вертолет

var is_started:bool = false
var coef_start:float = 0.0
var delta_coef_start:float = 0.8#0.1

var main_rotor_tyaga:float = 0.0
var main_rotor_torque:float = 8.5


var угол_атаки:float = 0.0
var угол_крена:float = 0.0
var угол_рысканья:float = 0.0

@onready var alt_set = self.position.y

var entered = false
var водитель:игрок_контроллер = null

@export var модель_главный_ротор:MeshInstance3D
@export var модель_задний_ротор:MeshInstance3D
@export var модель_задний_ротор_доп:MeshInstance3D
@export var модель_рычага_управления:MeshInstance3D

@export var точки_входа:Array

@export var black_steam_effect:GPUParticles3D

@export var hull_hp:float = 100.0
@onready var max_hull_hp:float = hull_hp

@export var max_main_rotor_rpm:float = 120.0

var pid_атака = PIDController.new()
var pid_крен = PIDController.new()

func _ready():
	pid_атака.set_pid(0.001,0.00001,0.01)
	pid_крен.set_pid(0.001,0.00001,0.01)
	for parent in get_children():
		if parent.is_in_group("VehEnterArea"):
			точки_входа.append(parent)

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
	
	
	anim_rotors(delta)
	
	if globals.current_player != водитель:
		return
	
	main_rotor_tyaga += Input.get_axis("понижение_тяги_главного_ротора", "повышение_тяги_главного_ротора") * delta
	main_rotor_tyaga = clamp(main_rotor_tyaga, 0.1, 1.0)
	
	угол_атаки -= угол_атаки * 0.1
	угол_крена -= угол_крена * 0.1
	main_rotor_tyaga -= main_rotor_tyaga * 0.05
	
	
	if entered:
		угол_атаки += Input.get_axis("движ_назад", "движ_вперед") * coef_start * delta 
		угол_крена += Input.get_axis("движ_лево", "движ_право") * coef_start * delta 
		#угол_рысканья += Input.get_axis("рысканье_лево", "рысканье_право") * coef_start * delta * 3.0
	
	pid_атака.setpoint = 0.0
	pid_крен.setpoint = 0.0
	if Input.get_axis("движ_назад", "движ_вперед") == 0.0 and Input.get_axis("движ_лево", "движ_право") == 0.0: 
		угол_атаки += pid_атака.step(rotation_degrees.x, delta)
		угол_крена += pid_крен.step(rotation_degrees.z, delta)
	
	#угол_атаки += 0.0 - rotation_degrees.x * delta * 0.1
	#угол_крена += 0.0 - rotation_degrees.z * delta * 0.1
	
	#rotation_degrees.x += угол_атаки
	#rotation_degrees.z += угол_крена
	
	## УГОЛ АТАКИ
	#var вектор_рычага = модель_главный_ротор.transform.origin + Vector3(5.0, 0.0, 0.0)
	apply_force(global_transform.basis.y * -угол_атаки * main_rotor_tyaga * main_rotor_torque, \
			global_transform.basis.z * 5.0)
	
	## КРЕН
	apply_force(global_transform.basis.y * угол_крена * main_rotor_tyaga * main_rotor_torque, \
			global_transform.basis.x * 5.0)
	
	## РЫСКАНЬЕ
	apply_force(модель_задний_ротор.transform.basis.x * Input.get_axis("рысканье_лево", "рысканье_право") * main_rotor_tyaga * main_rotor_torque / 5.0, \
		модель_задний_ротор.transform.origin)
	
	## СНИЖЕНИЕ/ПОДЪЕМ
	apply_force(global_transform.basis.y * main_rotor_tyaga * main_rotor_torque)
	
	## НАЧАЛЬНАЯ ПОДЪЕМНАЯ СИЛА
	var velocity = transform.basis.y * coef_start * main_rotor_torque * 1.05
	
	модель_рычага_управления.rotation.x = угол_атаки
	модель_рычага_управления.rotation.z = угол_крена
	if !entered:
		velocity = Vector3.ZERO
	#print(velocity)
	apply_force(velocity)
	

func anim_rotors(delta):
	модель_главный_ротор.rotation.y += delta * max_main_rotor_rpm * abs(exp((coef_start * 10.0) - 10.0)) # анимация ротора
	модель_задний_ротор.rotation.x += delta * max_main_rotor_rpm * abs(exp((coef_start * 10.0) - 10.0)) * 3.0
	модель_задний_ротор_доп.rotation.x += -delta * max_main_rotor_rpm * abs(exp((coef_start * 10.0) - 10.0)) * 3.0
	if модель_главный_ротор.rotation.y >= 360.0:
		модель_главный_ротор.rotation.y = 0.0
	if модель_задний_ротор.rotation.x >= 360.0:
		модель_задний_ротор.rotation.x = 0.0
	if модель_задний_ротор_доп.rotation.x >= 360.0:
		модель_задний_ротор_доп.rotation.x = 0.0

func _input(event):
	pass

func hit():
	hull_hp -= 1
	print("hit")
	if hull_hp <= 0:
		destroy_veh()

func destroy_veh():
	self.queue_free()



'''func _on_пилотarea_3d_body_entered(body):
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
		body.show_text("")'''
