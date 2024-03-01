extends CharacterBody3D
class_name игрок_контроллер

@export_group("Объекты")
## Основная камера игрока
@export var camera:Camera3D
@export var camera_pivot:Node3D
# Post Process
@export var camera_blur:TextureRect
## Основная коллизия игрока
@export var collision:CollisionShape3D
@onready var head_raycasts:Node3D = $"CollisionShape3D/raycasts"
@export var animplayer:AnimationPlayer
@export var aim_pos:Node3D
@export var handitem:hand_item
@onready var bullets:Node3D = get_parent().get_node("bullets")

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

@export_group("Настройки оружия")
var aim_coef:float
var _aim_pos:Vector3
var gun_pos:Vector3
var gun_fire_velocity:float = 0.0
@export var gun_jump_shake:float = 1.0
@export var gun_rotate_speed:float = 30
@export var gun_move_speed:float = 0.1
@export var coef_razbrosa:float = 2.0
## Угол отклонения в две стороны при повороте камеры
@export var gun_max_angle:float = 15.0
## Скорость вскидки оружия на целик
@export var gun_aim_speed:float = 4.0

var canjump:bool = true
var isaim:bool = false
var isfire:bool = false
var issitdown:bool = false
var isrun:bool = false
var sitdown_coef:float = 0.0
var proc_delta:float


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	globals.current_player = self
	
	if handitem != null: 
		handitem.init(itemdatas.items["SMG"]) # тестовая строка выдачи оружия
	
	if handitem.is_gun: gun_pos = handitem.position
	
	_aim_pos = aim_pos.position
	camera.fov = fov
func _process(delta):
	proc_delta = delta
	process_canjump()
	process_run()
	process_gun(delta)
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
func process_gun(delta):
	if !handitem.is_gun: # если нет оружия, обработка не происходит
		return
	
	# возвращение оружия на свое место
	var gunto:Vector3 = (gun_pos - handitem.position) * 15.0 * delta
	handitem.position += gunto
	
	if !isfire:
		handitem.rotation_degrees.z += -handitem.rotation_degrees.z * delta * gun_rotate_speed / 10
		handitem.rotation_degrees.x += -handitem.rotation_degrees.x * delta * gun_rotate_speed / 10
	
	
	# прицеливание с возможность изменения fov
	var aim_local_coef = delta * gun_aim_speed
	fov_coef -= aim_local_coef
	var _gun_jump_shake = 0.0
	if Input.is_action_pressed("прицеливание") and handitem.is_gun:
		_gun_jump_shake = gun_jump_shake * 0.1
		if Input.is_action_pressed("прищуриться_на_прицеливании") or handitem.fov_coef != 1.0:
			fov_coef += aim_local_coef * 2.0
			_gun_jump_shake = gun_jump_shake * 0.05
		
		
		
		isaim = true
		aim_coef += aim_local_coef
		
	else:
		isaim = false
		aim_coef -= aim_local_coef
		_gun_jump_shake = gun_jump_shake * 0.4
	
	aim_coef = clamp(aim_coef, 0.0, 1.0)
	fov_coef = clamp(fov_coef, 0.0, 1.0)
	
	camera_blur.material.set_shader_parameter("blur_inner", clamp(1.0 - aim_coef, 0.3, 0.9))
	
	camera.fov = lerp(fov, fov * fov_shift_aim_coef * handitem.fov_coef, fov_coef) # 0.65
	aim_pos.position = lerp(_aim_pos, Vector3.ZERO, aim_coef)
	
	# отставание оружия при передвижении
	var z:Vector3 = transform.basis.z * Input.get_axis("движ_вперед", "движ_назад") *gun_move_speed
	var x:Vector3 = transform.basis.x * Input.get_axis("движ_лево", "движ_право") *gun_move_speed
	handitem.global_position += (-z + -x + Vector3(0.0, velocity.y * gun_jump_shake, 0.0)) * delta * 0.25
	
	# стрельба
	var time_ = Time.get_ticks_msec() - handitem.last_fire_time
	var delta_time = 60000.0 / handitem.fire_rate
	if Input.is_action_pressed("стрелять")  and time_ >= delta_time:
		isfire = true
		var rad = 0.001
		if time_ - delta_time < randf_range(10.0, 100.0):
			rad = (time_ - delta_time) * delta / coef_razbrosa # 5.0 коэф разброса если время между выстрелами меньше 100мсек
		
		var razbros = Vector3(randf_range(-rad, rad), randf_range(-rad, rad), 0.0)
		
		if !issitdown:
			gun_fire_velocity += randf_range(-delta, delta)
		else:
			gun_fire_velocity += randf_range(-delta/2.5, delta/2.5)
		
		handitem.position.z += (1.5 - aim_coef) * delta
		
		handitem.rotation_degrees.x += delta * gun_rotate_speed * gun_fire_velocity * 25.0
		handitem.rotation_degrees.x = clamp(handitem.rotation_degrees.x, -15.0, 15.0)
		
		handitem.last_fire_time = Time.get_ticks_msec()
		var bullet = load("res://префабы/bullet.tscn").instantiate()
		
		bullets.add_child(bullet)
		
		bullet.bullet_speed = handitem.bullet_speed
		bullet.position = handitem.model.get_node("BulletStart").global_position
		bullet.global_rotation = handitem.global_rotation + razbros
	else:
		isfire = false
	# обработка коллизии со стенами
	# TODO: Сделать чтобы оружие не входило в стенки
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
		if handitem.is_gun:
			handitem.position += Vector3(rot_y * gun_move_speed, rot_x * gun_move_speed, 0.0)
			handitem.rotation_degrees.z += rot_y * proc_delta * gun_rotate_speed * 20.0
			handitem.rotation_degrees.z = clamp(handitem.rotation_degrees.z, -gun_max_angle, gun_max_angle)
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
