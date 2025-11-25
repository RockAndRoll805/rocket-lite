extends Node3D

@export var launch_force: float = 1
@export var force_movement: bool = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body.name == "quake-character"):
		$AudioStreamPlayer3D.play()
		# this might be one of the dumber lines of code I have ever written but it works
		body.add_force_launcher(($cone.global_position - position).normalized() * launch_force, force_movement, true)
