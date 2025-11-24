extends CharacterBody3D

var max_distance = 7
var knockback_base = 16
var speed = 45
var time_alive = 0

var explosion = preload("res://FX/explode_fx.tscn")
var smoke = preload("res://FX/smoke_fx.tscn")

func _physics_process(delta):
	#velocity = -transform.basis.z * 1600 * delta
	#move_and_slide()
	if (time_alive > 0.04):
		visible = true
	if (time_alive > 0.05 and int(time_alive * 100) % 15 == 0):
		var smoke_fx = smoke.instantiate()
		smoke_fx.position = global_position
		get_tree().root.add_child(smoke_fx)
	time_alive += delta
	var collision = move_and_collide(-transform.basis.z * speed * delta)
	if collision != null:
		var player = get_parent().get_child(0).get_node("quake-character")
		var player_position = player.global_position
		player_position.y += 2
		var distance = (player_position - global_position).length()
		if (distance <= max_distance):
			#var knockback_amount = knockback_base - (knockback_base * (distance / max_distance * 0.5))
			#var knockback_vector = (player_position - global_position).normalized() * knockback_amount
			#player.add_force(knockback_vector)
			player.add_force_rocket(global_position, knockback_base, max_distance)
		else:
			print("too far from player")
		var explode_fx = explosion.instantiate()
		explode_fx.position = global_position
		get_tree().root.add_child(explode_fx)
		queue_free()
	if (position.length() > 10000):
		print("too large, deleting")
		queue_free()

func _ready():
	rotation = get_parent().get_child(0).get_node("quake-character").get_node('FPCamera').global_rotation
	position = get_parent().get_child(0).get_node("quake-character").position
	position.y += 2
	$SFXTrail.play()
	visible = false
