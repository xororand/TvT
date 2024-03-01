class_name hand_item
extends Node3D

var is_gun:bool = false
var bullet_speed = 0.0
var last_fire_time = Time.get_ticks_msec()
var fire_rate:float
var fov_coef:float

var model:Node

func init(data):
	is_gun = data["is_gun"]
	bullet_speed = data["bullet_speed"]
	fire_rate = data["fire_rate"]
	fov_coef = data["fov_coef"]
	model = load(data["model_res"]).instantiate()
	
	add_child(model)
