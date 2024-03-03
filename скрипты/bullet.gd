extends Node3D

@onready var time_start:float = Time.get_ticks_msec()
@onready var raycast = $RayCast3D
@onready var raycast2 = $RayCast3D2
@onready var trail = $MeshInstance3D

var bullet_speed:float = 270.0 # м/сек скорость пули
var max_distance:float = 350.0
var current_distance:float = 0.0

var hit = false

func _ready():
	if randi_range(0, 1):
		trail.visible = true

func _physics_process(delta):
	position.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * 0.0025
	
	current_distance += delta * bullet_speed
	
	if current_distance >= max_distance:
		self.queue_free()
	
	
	position += -get_transform().basis.z.normalized() * delta * bullet_speed
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		print(collider)
		if collider.has_method("hit"):
			hit = true
			hit_collider(collider, raycast.get_collision_point())
	
	if hit:
		return
	
	raycast2.force_raycast_update()
	if raycast2.is_colliding():
		var collider = raycast2.get_collider()
		if collider.has_method("hit"):
			hit_collider(collider, raycast2.get_collision_point())


func hit_collider(collider, point_pos):
	collider.hit()
	var node = globals.bullet_hit_effect.instantiate()
	node.position = point_pos
	node.rotation_degrees = rotation_degrees * Vector3(-1.0, -1.0, -1.0)
	
	print(node.rotation_degrees)
	globals.add_child(node)
	#print("удаление пули")
	self.queue_free()

func _on_body_entered(body):
	if body == globals.current_player:
		return
	
	print("удаление пули")
	self.queue_free()


func _on_area_entered(area):
	print(area)
