extends RigidBody2D
signal player_entered_smithy_area(player: CharacterBody2D)
signal player_exited_smithy_area
signal player_entered_king_area(player: CharacterBody2D)
signal player_exited_king_area


func _on_smithy_body_entered(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_entered_smithy_area.emit(body)


func _on_smithy_body_exited(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_exited_smithy_area.emit()


func _on_king_interaction_area_body_entered(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_entered_king_area.emit(body)


func _on_king_interaction_area_body_exited(body: Node2D) -> void:
	if body.get_class() == "CharacterBody2D":
		player_exited_king_area.emit()
