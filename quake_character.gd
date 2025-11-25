extends CharacterBody3D

@onready var camera: Camera3D = $FPCamera
@onready var speed_label: Label = $Control/Speed
var rocket = preload("res://rocket.tscn")

var mouse_sens: float = 0.0015
var friction: float = 8
var accel: float = 12
# 4 for quake 2/3 40 for quake 1/source
var accel_air: float = 40
var top_speed_ground: float = 15
# 15 for quake 2/3, 2.5 for quake 1/source
var top_speed_air: float = 2.5
# linearize friction below this speed value
var lin_friction_speed: float = 10
var jump_force: float = 11
var projected_speed: float = 0
var grounded_prev: bool = true
var grounded: bool = true
var wish_dir: Vector3 = Vector3.ZERO
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var added_force = false
var atk_cd_base = 0.8
var atk_cd_current = atk_cd_base + 1

var time_since_rocket = 0
var last_pos_at_rocket = Vector3()

var launcher_lockout = 1

func add_force_rocket(oirign: Vector3, knockback: float, max_distance: float) -> void:
	var player_position = global_position
	player_position.y +=2
	if (time_since_rocket < 0.1):
		print('using last pos')
		player_position = last_pos_at_rocket
	else:
		last_pos_at_rocket = player_position
	var knockback_amount = knockback - (knockback * ((player_position-oirign).length() / max_distance * 0.5))
	var knockback_vector = (player_position - oirign).normalized() * knockback_amount
	add_force(knockback_vector)
	time_since_rocket = 0

func add_force_launcher(force: Vector3, forced_velcity, ignore_crouch):
	if launcher_lockout >= 1:
		launcher_lockout = 0
		add_force(force, forced_velcity, ignore_crouch)

func add_force(force: Vector3, forced_velcity = false, ignore_crouch = false):
	if (forced_velcity):
		velocity = force
	elif (Input.is_action_pressed("crouch") and not ignore_crouch):
		velocity += force * 2
	else:
		velocity += force

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			self.rotate_y(-event.relative.x * mouse_sens)
			camera.rotate_x(-event.relative.y * mouse_sens)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(89))
	
	if event.is_action_pressed("crouch"):
		get_node("CollisionShape3D").shape.height = 1
	if event.is_action_released("crouch"):
		get_node("CollisionShape3D").shape.height = 2

func clip_velocity(normal: Vector3, overbounce: float, delta) -> void:
	var correction_amount: float = 0
	var correction_dir: Vector3 = Vector3.ZERO
	var move_vector: Vector3 = get_velocity().normalized()
	
	correction_amount = move_vector.dot(normal) * overbounce
	
	correction_dir = normal * correction_amount
	velocity -= correction_dir
	
	var cur_speed = (velocity * Vector3(1, 0, 1)).length()
	# this is only here cause I have the gravity too high by default
	# with a gravity so high, I use this to account for it and allow surfing
	if cur_speed > 10:
		if (velocity.y < -5):
			velocity.y -= correction_dir.y * (gravity/20)
		elif (velocity.y < 5):
			velocity.y -= 0 # correction_dir.y * (gravity/20)
		elif (velocity.y < 50):
			velocity.y -= correction_dir.y * (gravity/cur_speed) # potential div by 0 xd

func apply_friction(delta):
	var speed_scalar: float = 0
	var friction_curve: float = 0
	var speed_loss: float = 0
	var current_speed: float = 0
	
	# using projected velocity will lead to no friction being applied in certain scenarios
	# like if wish_dir is perpendicular
	# if wish_dir is obtuse from movement it would create negative friction and fling players
	current_speed = velocity.length()
	if(current_speed < 0.2):
		velocity.x = 0
		velocity.y = 0
		velocity.z = 0
		return
	
	friction_curve = clampf(current_speed, lin_friction_speed, INF)
	speed_loss = friction_curve * friction * delta
	speed_scalar = clampf(current_speed - speed_loss, 0, INF)
	speed_scalar /= clampf(current_speed, 1, INF)
	
	velocity *= speed_scalar

func apply_acceleration(acceleration: float, top_speed: float, delta):
	var speed_remaining: float = 0
	var accel_final: float = 0
	
	speed_remaining = (top_speed * wish_dir.length()) - projected_speed
	
	if speed_remaining <= 0:
		return
	
	accel_final = acceleration * delta * top_speed
	
	clampf(accel_final, 0, speed_remaining)
	
	velocity.x += accel_final * wish_dir.x
	velocity.z += accel_final * wish_dir.z

func air_move(delta, accel):
	apply_acceleration(accel, top_speed_air, delta)
	
	clip_velocity(get_wall_normal(), 14, delta)
	clip_velocity(get_floor_normal(), 14, delta)
	
	velocity.y -= gravity * delta

func ground_move(delta):
	floor_snap_length = 0.4
	apply_acceleration(accel, top_speed_ground, delta)
	
	if Input.is_action_pressed("jump"):
		velocity.y = jump_force
	
	if grounded == grounded_prev and velocity.y < 0.1:
		apply_friction(delta)
	
	if is_on_wall:
		clip_velocity(get_wall_normal(), 1, delta)

func _physics_process(delta):
	atk_cd_current += delta
	time_since_rocket += delta
	launcher_lockout += delta
	
	if Input.is_action_pressed("attack") and atk_cd_current >= atk_cd_base:
		get_tree().root.add_child(rocket.instantiate())
		atk_cd_current = 0
		$SFXRocketShoot.play()
	
	grounded_prev = grounded
	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	projected_speed = (velocity * Vector3(1, 0, 1)).dot(wish_dir)
	var cur_speed = (velocity * Vector3(1, 0, 1)).length() 
	speed_label.text = str(int(cur_speed))
	

	var new_accel = accel_air
	if (cur_speed < 8):
		new_accel = lerpf(2, accel_air, cur_speed/8)

	# Add the gravity.
	if not is_on_floor():
		grounded = false
		air_move(delta, new_accel)
	if is_on_floor():
		if velocity.y > 10:
			grounded = false
			#air_move(delta)
		else:
			grounded = true
			ground_move(delta)
	
	var speed_match = 1
	#if (velocity.length() > 20 and velocity.length() < 50 and velocity.y < -5):
		#speed_match = absf(35 - velocity.length()) / 15
	if (velocity.length() > 40 and velocity.length() < 70 and velocity.y > 10):
		speed_match = absf(55 - velocity.length()) / 15
	elif (velocity.length() > 30 and velocity.length() < 60 and velocity.y > -5):
		speed_match = absf(45 - velocity.length()) / 15
	else:
		speed_match = absf(35 - velocity.length()) / 15

	speed_label.add_theme_color_override("font_color", Color(speed_match,1 - speed_match,0,1))
	
	move_and_slide()
