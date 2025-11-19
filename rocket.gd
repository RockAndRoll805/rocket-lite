extends CharacterBody3D

var max_distance = 5
var knockback_base = 16
var speed = 45

func _physics_process(delta):
	#velocity = -transform.basis.z * 1600 * delta
	#move_and_slide()
	var collision = move_and_collide(-transform.basis.z * speed * delta)
	if collision != null:
		print('collision')
		var player = get_parent().get_child(0).get_node("quake-character")
		var player_position = player.global_position
		player_position.y += 2
		var distance = (player_position - global_position).length()
		if (distance <= max_distance):
			var knockback_amount = knockback_base - (knockback_base * (distance / max_distance * 0.5))
			var knockback_vector = (player_position - global_position).normalized() * knockback_amount
			#knockback_vector.x *= 0.7
			#knockback_vector.z *= 0.7
			player.add_force(knockback_vector)
		else:
			print("too far from player")
		queue_free()
	if (position.length() > 10000):
		print("too large, deleting")
		queue_free()

func _ready():
	rotation = get_parent().get_child(0).get_node("quake-character").get_node('FPCamera').global_rotation
	position = get_parent().get_child(0).get_node("quake-character").position
	position.y += 2
