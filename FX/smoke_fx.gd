extends Node3D

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1,1,1), 0.05)
	tween.set_ease(Tween.EASE_OUT)
	tween.play()
	
	#$MeshInstance3D.get_active_material(0)
	#tween2.tween_property($MeshInstance3D.get_active_material(0), "material_override:albedo_color:a", 0.0, 0.1)
	var material = $MeshInstance3D.get_surface_override_material(0).duplicate()
	$MeshInstance3D.set_surface_override_material(0, material)
	var fade_duration = 0.2
	var time_elapsed = 0
	while time_elapsed < fade_duration:
		var time = time_elapsed / fade_duration
		var current_alpha = lerp(0.5, 0.0, time)
		material.albedo_color.a = current_alpha
		
		await get_tree().process_frame
		time_elapsed += get_process_delta_time()
	
	queue_free()
