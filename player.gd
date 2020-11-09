extends KinematicBody

var velocity = Vector3()
var _mouse_motion = Vector2()

var jump_strength = 0
var sprint_strength = 1
var slide_dist = 0
var slide_stop = Vector3()
var sliding = false
var point_jumping = false

var head_rotation_x = 0
var head_rotation_y = 0
var head_rotation_z = 0

var SPRINT_STRENGTH = 5
var JUMP_STRENGTH = 3
var WALK_SPEED = 5
var CROUCH_SPEED = 2
var SLIDE_SPEED = 8
var FALLING_MOVE_SPEED = 1
var CROUCH_SLIDE_DECAY = .95
var SPRINT_DECAY = .1
var HEAD_ROTATE_SPEED = 0.05
var HEAD_SLIDE_ROTATION = -0.2
var HEAD_TILT_SPEED = -0.0008

onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

onready var head = $head
onready var raycast = $head/RayCast

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	transform.basis = Basis(Vector3(0, _mouse_motion.x * -0.001, 0))
	head.transform.basis = Basis(Vector3(head_rotation_x, head_rotation_y, head_rotation_z))

func _physics_process(delta):
	_move_player(delta)

func _input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_mouse_motion += event.relative
	
func _move_player(delta):
	var movement
		
	head_rotation_x = _mouse_motion.y * -0.001
	
	if is_on_floor():
		_set_jump_strength(JUMP_STRENGTH)
		_set_sprint_strength(SPRINT_STRENGTH)
		movement = _ground_movement(WALK_SPEED, delta)
	else: movement = _calculate_movement(FALLING_MOVE_SPEED)
	
	# Calculate and apply total velocity based on movement 
	# speed, current inputs and gravity
	_calculate_velocity(movement, delta)

func _ground_movement(move_speed, delta):
	if Input.is_action_pressed("crouch"):
		return _crouch_movement(delta)
	else:
		return _standing_movement(move_speed)

func _crouch_movement(delta):
	head.transform.origin = Vector3(0, 1, 0)
	
	# Sliding happens when crouching immediately after
	# sprinting
	if sliding: 
		return _slide_movement()
	elif not sliding and sprint_strength > 3:
		return _start_slide()
	
	# Not doing any sliding, rotate head back to 0 and crouch
	# walk normally
	else:
		print("normal crouch")
		_mouse_motion.y = clamp(_mouse_motion.y, -1550, 1550)
		head_rotation_z = min(head_rotation_z + HEAD_ROTATE_SPEED, 0)
	return _calculate_movement(2)
	
func _standing_movement(move_speed):
	head.transform.origin = Vector3(0, 1.6, 0)
	
	_mouse_motion.y = clamp(_mouse_motion.y, -1550, 1550)
	head_rotation_y = 0
	head_rotation_z = 0
	
	return _calculate_movement(move_speed)
	
func _start_slide():
	# Begin sliding
	sliding = true
	# Sliding boost
	velocity *= 2
	slide_stop = velocity / 5
	return velocity
	
func _slide_movement():
#		head_rotation_x = 0
#		head_rotation_y = 0
		
		# Direction you aim should be direction you face and loosely slide toward
		
		if Input.is_action_pressed("fire"):
			return _launch()
		if velocity.length() > slide_stop.length() and slide_stop.length() > 0:
			#print("sliding %s" % String(velocity))
			head_rotation_z = max(head_rotation_z - HEAD_ROTATE_SPEED, HEAD_SLIDE_ROTATION)
			
			if Input.is_action_pressed("aim"):
				_slide_aim()
				return _calculate_movement(SLIDE_SPEED)
		else:
			sliding = false
		return velocity * CROUCH_SLIDE_DECAY
		
func _calculate_movement(move_speed):
	return transform.basis.xform(Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)).normalized() * move_speed * sprint_strength
	
func _calculate_velocity(movement, delta):
	velocity.y -= gravity * delta * 1.6
	velocity = move_and_slide(Vector3(movement.x, velocity.y, movement.z), 
		Vector3.UP)
		
# While sliding, rotate head on Z axis. Also need to enable sliding toward faced
# direction
func _slide_aim():
	head_rotation_z = clamp(
		lerp(head_rotation_z, _mouse_motion.x * HEAD_TILT_SPEED, 1),
		-.8, .8)
		
	#print("Z after: %f" % head_rotation_z)
	
func _launch():
	var position = raycast.get_collision_point()
	print("velocity after: %s" % String((position - velocity).normalized()))
	print("raycast: %s" % String(position))
	velocity.x *= 5
	
func _set_sprint_strength(strength):
	if Input.is_action_pressed("sprint") and Input.is_action_pressed("move_forward"):
		sprint_strength = strength
	else:
		sprint_strength = max(sprint_strength - SPRINT_DECAY, 1)

func _set_jump_strength(added_strength):
	if Input.is_action_pressed("jump"):
		jump_strength += added_strength
	elif Input.is_action_just_released("jump"):
		velocity.y = jump_strength
		jump_strength = 0

