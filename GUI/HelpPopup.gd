extends Popup

onready var player = get_node("/root/Root/Player")

func _on_help_pressed():
	get_tree().paused = true
	player.set_process_input(false)
	popup()

func _on_HelpPopup_popup_hide():
	get_tree().paused = false
	player.set_process_input(true)
