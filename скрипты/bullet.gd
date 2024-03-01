extends Node3D

@onready var time_start:float = Time.get_ticks_msec()
@onready var raycast = $RayCast3D
@onready var raycast2 = $RayCast3D2

var bullet_speed:float = 270.0 # м/сек скорость пули
var max_distance:float = 350.0
var current_distance:float = 0.0

var hit = false

func _ready():
	visible = false

func _process(delta):
	visible = true
	
	current_distance += delta * bullet_speed
	
	if current_distance >= max_distance:
		self.queue_free()
	
	
	position += -get_transform().basis.z.normalized() * delta * bullet_speed
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.has_method("hit"):
			hit = true
			collider.hit()
	
	if hit:
		return
	
	if raycast2.is_colliding():
		var collider = raycast2.get_collider()
		if collider.has_method("hit"):
			collider.hit()

func _on_body_entered(body):
	if body == globals.current_player:
		return
	
	self.queue_free()


func _on_area_entered(area):
	print(area)
