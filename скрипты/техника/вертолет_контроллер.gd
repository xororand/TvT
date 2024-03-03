extends Node3D
class_name Вертолет

var entered = false
var водитель:игрок_контроллер = null

@export var модель_главный_ротор:MeshInstance3D
@export var модель_контроллера:MeshInstance3D

@export var black_steam_effect:GPUParticles3D

@export var hull_hp:float = 100.0
@onready var max_hull_hp:float = hull_hp

@export var max_main_rotor_rpm:float = 120.0

func _physics_process(delta):
	if hull_hp / max_hull_hp <= 0.5:
		black_steam_effect.emitting = true
	else:
		black_steam_effect.emitting = false
	
	##модель_главный_ротор.rotation.y += delta * max_main_rotor_rpm
	if модель_главный_ротор.rotation.y >= 360.0:
		модель_главный_ротор.rotation.y = 0.0
	#модель_главный_ротор.rotation.y = clamp(модель_главный_ротор.rotation.y, 0.0, 1.0)

func hit():
	hull_hp -= 1
	print("hit")
	if hull_hp <= 0:
		destroy_veh()

func destroy_veh():
	self.queue_free()
