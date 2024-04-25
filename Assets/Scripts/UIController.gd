extends Node


const highlighted_pickaxe_texture := preload("res://Assets/Textures/UI/Pickaxe Icon Highlighted.png")
const standard_pickaxe_texture := preload("res://Assets/Textures/UI/Pickaxe Icon.png")

const highlighted_hammer_texture := preload("res://Assets/Textures/UI/Hammer Icon Highlighted.png")
const standard_hammer_texture := preload("res://Assets/Textures/UI/Hammer Icon.png")


func _on_player_player_selected_action_updated(action: Player.Actions) -> void:
	if action == Player.Actions.PICKAXE:
		$Hotbar/ActionPickaxeIcon.texture = highlighted_pickaxe_texture
		$Hotbar/ActionBuildIcon.texture = standard_hammer_texture
	else:
		$Hotbar/ActionPickaxeIcon.texture = standard_pickaxe_texture
		$Hotbar/ActionBuildIcon.texture = highlighted_hammer_texture


func _on_player_inventory_updated(player: CharacterBody2D) -> void:
	update_player_inventory_count(player)


func update_player_inventory_count(player: CharacterBody2D):
	$Hotbar/WoodIcon/RichTextLabel.text = str(player.materials_inventory[PlayArea.CollectibleMaterials.WOOD])
	$Hotbar/StoneIcon/RichTextLabel.text = str(player.materials_inventory[PlayArea.CollectibleMaterials.STONE])
	$Hotbar/CoalIcon/RichTextLabel.text = str(player.materials_inventory[PlayArea.CollectibleMaterials.COAL])
	$Hotbar/GoldIcon/RichTextLabel.text = str(player.materials_inventory[PlayArea.CollectibleMaterials.GOLD])


