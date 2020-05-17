extends Popup

onready var player = get_node("/root/Root/Player")

func _on_menu_pressed():
	get_tree().paused = true
	player.set_process_input(false)
	popup()

func _on_Restart_button_up():
	get_tree().paused = false
	return get_tree().change_scene("res://Scenes/Main.tscn")

func _on_Quit_button_up():
	get_tree().quit()

func _on_Resume_button_up():
	hide()

func _on_MenuPopup_popup_hide():
	get_tree().paused = false
	player.set_process_input(true)
