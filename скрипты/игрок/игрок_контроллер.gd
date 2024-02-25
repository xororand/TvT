extends CharacterBody3D
class_name игрок_контроллер

@export_group("Объекты")
## Основная камера игрока
@export var camera:Camera3D
@export var camera_pivot:Node3D
## Основная коллизия игрока
@export var collision:CollisionShape3D
@onready var head_raycasts:Node3D = $"CollisionShape3D/raycasts"
@export var animplayer:AnimationPlayer
@export var aim:Node3D
#@export var handitem:hand_item
#@onready var bullets:Node3D = get_parent().get_node("bullets")

@export_group("Настройки камеры")
@export var fov:float = 90.0
var fov_coef:float = 0.0
## коэффициент FOV при прицеливание и SHIFT
@export var fov_shift_aim_coef:float = 0.8
## Ограничение углов поворота камеры по вертикали
@export var max_angle_x:Vector2 = Vector2(-80, 80)
## Чувствительность оси X
@export var c_rot_x:float = 0.1
## Чувствительность оси Y
@export var c_rot_y:float = 0.1

@export_group("Настройки физики")
## Скорость игрока
@export var speed:float = 350.0
var speed_coef:float = 1.0
## Сила отталкивания предметов при столкновении
@export var push_force:float = 0.1
@export var cam_to_sitdown:Vector3 = Vector3(0, 1.2, 0)
@export var cam_to_situp:Vector3 = Vector3(0, 1.8, 0)
@export var col_h_sitdown:float = 1.4
@export var col_h_situp:float = 2.0
@export var jump_float:float = 1.0
@export var jump_loss:float = 3.3
@export var jump_force:float = 1.0

var canjump:bool = true
var isaim:bool = false
var isfire:bool = false
var issitdown:bool = false
var isrun:bool = false
var sitdown_coef:float = 0.0
var proc_delta:float


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#Globals.current_player = self
	
	#if handitem != null: handitem.init(Data.items[0]) # тестовая строка выдачи оружия
	
	#if handitem.is_gun: gun_pos = handitem.position
	#aim_pos = aim.position
	camera.fov = fov
func _process(delta):
	proc_delta = delta
	process_canjump()
	process_run()
	process_sitdown(delta)
func _physics_process(delta):
	process_gravity(delta)

func _input(event):
	process_camera(event)

func process_gravity(delta):
	var vel_move:Vector3 = Vector3(0,0,0)
	
	if jump_float != 1.0:
		jump_float += delta * jump_loss
	
	jump_float = clamp(jump_float, -jump_loss, 1.0)
	
	# уменьшение скорости передвижения при прицеливании
	var _speed_coef = speed_coef
	if isaim: _speed_coef *= 0.6
	if isrun: _speed_coef *= 1.2
	
	
	var z:Vector3 = transform.basis.z * -Input.get_axis("движ_назад", "движ_вперед") 
	var x:Vector3 = transform.basis.x * Input.get_axis("движ_лево", "движ_право")
	
	vel_move += (z + x).normalized() * delta * lerp(speed * _speed_coef, speed * 0.4 * _speed_coef, sitdown_coef)
	
	if is_on_floor() and Input.is_action_pressed("прыжок") and canjump: # отрыв во время прыжка
		jump_float = -jump_force
		vel_move.y += ProjectSettings.get_setting("physics/3d/default_gravity") * jump_float
	
	if !is_on_floor(): # гравитация
		for i in get_slide_collision_count():
			var c = get_slide_collision(i)
			if c.get_normal().y < 0.0 and !is_on_wall() or velocity.y == 0:
				jump_float = delta * 2
		vel_move.y += ProjectSettings.get_setting("physics/3d/default_gravity") * jump_float
	
	vel_move *= Vector3(1.0, ProjectSettings.get_setting("physics/3d/default_gravity_vector").y, 1.0)
	
	
	velocity = vel_move
	
	move_and_slide()
func process_canjump():
	canjump = true
	for raycast in head_raycasts.get_children():
		if(raycast.is_colliding()):
			canjump = false
func process_run():
	if Input.is_action_pressed("бег") and !isaim:
		isrun = true
	else:
		isrun = false
func process_camera(event):
	if event is InputEventMouseMotion:
		# обработка поворотов камеры
		var rot_x:float = event.relative.y * -c_rot_x * proc_delta
		var rot_y:float = event.relative.x * -c_rot_y * proc_delta
		camera_pivot.rotate_x(rot_x)
		rotate_y(rot_y)
		
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, max_angle_x.x, max_angle_x.y) # ограничение по вертикали
		
		# сглаженные повороты оружием при повороте вокруг себя (ось Y)
		#if handitem.is_gun:
		#	handitem.position += Vector3(rot_y * 0.15, rot_x * 0.15, 0.0)
		#	handitem.rotation_degrees.z += rot_y * proc_delta * gun_rotate_speed * 20.0
		#	handitem.rotation_degrees.z = clamp(handitem.rotation_degrees.z, -gun_max_angle, gun_max_angle)
func process_sitdown(delta):
	issitdown = false
	if Input.is_action_pressed("присесть"): #and is_on_floor(): - убирает в прыжке возможность приседать
		issitdown = true
		sitdown_coef += delta*5
	else:
		for raycast in head_raycasts.get_children():
			if(raycast.is_colliding()):
				#print(raycast.get_collider())
				return
		
		sitdown_coef -= delta*5
	
	
	sitdown_coef = clamp(sitdown_coef, 0.0, 1.0)
	
	# перемещаем камеру
	camera_pivot.position = lerp(cam_to_situp, cam_to_sitdown, sitdown_coef)
	# уменьшаем/увеличиваем коллизию
	var height:float = lerp(col_h_situp, col_h_sitdown, sitdown_coef)
	collision.shape.height = height
