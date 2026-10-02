extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 6.5
@export var grab_area: Area3D
@export var grab_point: Marker3D
var COIB:RigidBody3D #Current Object In Body
var Is_Grabbing:bool


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("Pick_up") and COIB:
		if Is_Grabbing:
			Is_Grabbing = false
			COIB.freeze = false
		else:
			Is_Grabbing = true
			COIB.freeze = true
	
	
	if Is_Grabbing and COIB:
		COIB.global_position = grab_point.global_position
	
	
	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _on_grab_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Grabble"):
		COIB = body

#func _on_grab_area_body_exited(body: Node3D) -> void:
	#if body.is_in_group("Grabble"):
		#COIB = null
