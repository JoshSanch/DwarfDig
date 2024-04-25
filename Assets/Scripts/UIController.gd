extends Node
var resource_counts := {
	PlayArea.CollectibleMaterials.WOOD: 0,
	PlayArea.CollectibleMaterials.STONE: 0,
	PlayArea.CollectibleMaterials.COAL: 0,
	PlayArea.CollectibleMaterials.GOLD: 0,
}


const highlighted_pickaxe_texture := preload("res://Assets/Textures/UI/Pickaxe Icon Highlighted.png")
const standard_pickaxe_texture := preload("res://Assets/Textures/UI/Pickaxe Icon.png")

const highlighted_hammer_texture := preload("res://Assets/Textures/UI/Hammer Icon Highlighted.png")
const standard_hammer_texture := preload("res://Assets/Textures/UI/Hammer Icon.png")


func _on_cave_playable_area_resource_collected(material_collected: PlayArea.CollectibleMaterials) -> void:
	resource_counts[material_collected] += 1
	$Hotbar/WoodIcon/RichTextLabel.text = str(resource_counts[PlayArea.CollectibleMaterials.WOOD])
	$Hotbar/StoneIcon/RichTextLabel.text = str(resource_counts[PlayArea.CollectibleMaterials.STONE])
	$Hotbar/CoalIcon/RichTextLabel.text = str(resource_counts[PlayArea.CollectibleMaterials.COAL])
	$Hotbar/GoldIcon/RichTextLabel.text = str(resource_counts[PlayArea.CollectibleMaterials.GOLD])


func _on_player_player_selected_action_updated(action: Player.Actions) -> void:
	if action == Player.Actions.PICKAXE:
		$Hotbar/ActionPickaxeIcon.texture = highlighted_pickaxe_texture
		$Hotbar/ActionBuildIcon.texture = standard_hammer_texture
	else:
		$Hotbar/ActionPickaxeIcon.texture = standard_pickaxe_texture
		$Hotbar/ActionBuildIcon.texture = highlighted_hammer_texture
