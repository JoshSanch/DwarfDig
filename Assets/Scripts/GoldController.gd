extends Node

@onready var gold_deposited := 0

@export var gold_required := 3


func _ready() -> void:
	$HBoxContainer/Label.text = "0/%s" % gold_required


func _on_dwarven_keep_player_entered_king_area(player: CharacterBody2D) -> void:
	var gold_in_inventory: int = player.materials_inventory[PlayArea.CollectibleMaterials.GOLD]
	gold_deposited += gold_in_inventory
	$HBoxContainer/Label.text = "%s/%s" % [gold_deposited, gold_required]
	player.update_inventory(PlayArea.CollectibleMaterials.GOLD, 0)
	if gold_deposited >= gold_required:
		trigger_game_end()


func trigger_game_end():
	pass
