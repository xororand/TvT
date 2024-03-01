extends VehicleBody3D

var entered = false
var водитель:игрок_контроллер = null

var модель_руля:Mesh # TODO: поворот руля

@export var точка_водителя:Node3D

func _ready():
	pass # Replace with function body.

func _process(delta):
	pass

func _physics_process(delta):
	if entered and водитель != null:
		print(steering)
		steering = lerp(steering, Input.get_axis("движ_право", "движ_лево") * 0.4, 1*delta)
		engine_force = Input.get_axis("движ_назад", "движ_вперед") * 100

func _input(event):
	if Input.is_action_just_pressed("использовать") and водитель != null:
		entered = true
		водитель.in_vehicle = true
		водитель.show_text("")
		водитель.reparent(точка_водителя)
		водитель.get_node("CollisionShape3D").disabled = true
		водитель.position = Vector3.ZERO
		водитель.rotation = Vector3.ZERO
		водитель.handitem.visible = false

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
