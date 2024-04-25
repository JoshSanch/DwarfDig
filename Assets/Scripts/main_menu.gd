extends Control

@export var gameroot : PackedScene

@onready var setting_menu = %SettingsContainer

func _on_play_button_pressed():
	var new_game = gameroot.instantiate()
	get_tree().change_scene_to_packed(gameroot)


func _on_settings_button_pressed():
	setting_menu.show()


func _on_quit_button_pressed():
	get_tree().quit()


#Settings menu button
func _on_close_button_pressed():
	setting_menu.hide()
