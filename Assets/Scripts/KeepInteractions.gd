extends RigidBody2D
signal player_entered_smithy_area(player: CharacterBody2D)
signal player_exited_smithy_area
signal player_entered_king_area(player: CharacterBody2D)
signal player_exited_king_area
signal action_upgrade_dispensed(action: Player.Actions)

@onready var dig_upgrade_dispensed = false

@export var required_coal_for_mining_upgrade := 5

func _on_smithy_body_entered(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_entered_smithy_area.emit(body)
	
	# try to cash in coal
	var player := body as Player
	var current_coal_count = body.materials_inventory[PlayArea.CollectibleMaterials.COAL] 
	if current_coal_count >= required_coal_for_mining_upgrade:
		player.update_inventory(PlayArea.CollectibleMaterials.COAL, current_coal_count - required_coal_for_mining_upgrade)
		action_upgrade_dispensed.emit(Player.Actions.PICKAXE)


func _on_smithy_body_exited(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_exited_smithy_area.emit()


func _on_king_interaction_area_body_entered(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_entered_king_area.emit(body)


func _on_king_interaction_area_body_exited(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_exited_king_area.emit()
