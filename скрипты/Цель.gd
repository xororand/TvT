extends Node3D

@onready var animplayer = $AnimationPlayer

func _physics_process(delta):
	pass

func hit():
	print("hit")
	animplayer.play("hitten")

