extends Control


func _on_start_button_pressed() -> void:
	await RenderingServer.frame_post_draw
	get_tree().change_scene_to_file("res://scenes/game_board.tscn")
