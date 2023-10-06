extends Node3D

var camera_position:Vector3
var camera_rotation:Vector3
var camera_x:float
var camera_z:float
var camera_y:float
var initial_camera_rotation:Vector3

var hold_rotate:bool

@onready var camera = $Camera

func _ready():
	
	camera_rotation = rotation_degrees # Initial rotation
	initial_camera_rotation = rotation_degrees
	camera_x = 1.7
	camera_z = 1.7
	camera_y = 0
	camera_position = Vector3(camera_x, camera_y, camera_z)
	pass

func _process(delta):
	
	# Set position and rotation to targets
	
	position = position.lerp(camera_position, delta * 8)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
	
	# handle_input(delta)


func _input(event):
	
	# Rotate camera using mouse (hold 'middle' mouse button)
	if hold_rotate:
		return
	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("camera_rotate"):
			camera_rotation += Vector3(0, -event.relative.x / 10, 0)



func _on_city_screen_layer_changed(new_layer):
	camera_y = new_layer * 1.2
	camera_position = Vector3(camera_x, camera_y, camera_z)

func _on_start_slots_button_pressed():
	camera_x = 5
	camera_z = -1.6
	camera_position = Vector3(camera_x, camera_y, camera_z)
	camera_rotation = initial_camera_rotation
	hold_rotate = true


func _on_slots_screen_slots_over():
	camera_x = 1.7
	camera_z = 1.7
	camera_position = Vector3(camera_x, camera_y, camera_z)
	hold_rotate = false
