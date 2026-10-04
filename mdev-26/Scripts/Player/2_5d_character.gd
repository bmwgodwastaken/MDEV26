extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 6.5
@export var grab_area: Area3D
@export var grab_point: Marker3D
var COIB:RigidBody3D #Current Object In Body
var Is_Grabbing:bool
## Off = the player ignores walking, jumping and grabbing (gravity still applies), e.g. during the level-end transition.
var controls_enabled := true
var _was_on_floor := true
var _step_timer := 0.0
const STEP_TIME := 0.35 # seconds between footstep sounds while walking

func _ready() -> void:
	TimeManager.start_timer()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if controls_enabled and Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		Audio.play("jump_sfx")
	
	# The plank we were carrying was deleted (e.g. it fell out of the world): let go.
	if Is_Grabbing and not is_instance_valid(COIB):
		Is_Grabbing = false
		COIB = null

	if controls_enabled and Input.is_action_just_pressed("Pick_up"):
		if Is_Grabbing:
			Is_Grabbing = false
			COIB.freeze = false
			COIB = null
			Audio.play("interact_sfx")
		else:
			# Only something inside the grab area right now can be grabbed.
			COIB = _nearest_grabbable()
			if COIB:
				Is_Grabbing = true
				COIB.freeze = true
				Audio.play("interact_sfx")

	if Is_Grabbing:
		COIB.global_position = grab_point.global_position
		
	
	
	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down") if controls_enabled else Vector2.ZERO
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	_play_movement_sounds(delta)


## Footsteps while walking on the ground, and a landing sound when the feet touch down.
func _play_movement_sounds(delta: float) -> void:
	if is_on_floor() and not _was_on_floor:
		Audio.play("land_sfx")
	_was_on_floor = is_on_floor()
	_step_timer -= delta
	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.5 and _step_timer <= 0.0:
		Audio.play("footstep_sfx")
		_step_timer = STEP_TIME


## Closest "Grabble" body inside the grab area, or null.
func _nearest_grabbable() -> RigidBody3D:
	var nearest: RigidBody3D = null
	var nearest_distance := INF
	for body in grab_area.get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("Grabble"):
			var distance := global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest = body
				nearest_distance = distance
	return nearest
