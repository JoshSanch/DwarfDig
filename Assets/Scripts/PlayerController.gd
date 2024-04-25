class_name Player

extends CharacterBody2D
signal player_action_activated(action: Actions)
signal player_selected_action_updated(action: Actions)
signal inventory_updated(player: CharacterBody2D)

enum Actions {
	PICKAXE,
	BUILD_SUPPORT,
	BUILD_ROPE
}

const action_animations = {
	"PickaxeSwing": null,
	"HammerSwing": null
}

@onready var sprite_node: AnimatedSprite2D = $AnimatedSprite2D
@onready var selected_action: Actions = Actions.PICKAXE
@onready var active_action = null
@onready var upgraded_actions := []
@onready var is_mouse_in_action_radius = false
@onready var materials_inventory = {
	PlayArea.CollectibleMaterials.WOOD: 0,
	PlayArea.CollectibleMaterials.STONE: 0,
	PlayArea.CollectibleMaterials.GOLD: 0,
	PlayArea.CollectibleMaterials.COAL: 0
}
@onready var on_climbable_surface := false

@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var CLIMB_SPEED = 200
@export var crafting_requirements = {
	Actions.BUILD_ROPE: [PlayArea.CollectibleMaterials.WOOD, 2]
}


func _ready() -> void:
	inventory_updated.emit(self)


func _process(delta: float) -> void:
	update_selected_action()
	if is_mouse_in_action_radius and Input.is_action_pressed("action_contextual"):
		handle_actions(selected_action)
	
	handle_animation_state()

func _physics_process(delta: float) -> void:
	if on_climbable_surface:
		var climb_direction := Input.get_axis("movement_climb_up", "movement_climb_down")
		velocity.y = climb_direction * CLIMB_SPEED
	else:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("movement_jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func handle_actions(selected_action: Actions):
	match selected_action:
		Actions.BUILD_ROPE:
			if active_action == null:
				var requirements = crafting_requirements[selected_action]
				var required_material = requirements[0]
				var required_quantity = requirements[1]
				
				if materials_inventory[required_material] < required_quantity:
					return
				
				materials_inventory[required_material] -= required_quantity
				inventory_updated.emit(self)
				
				player_action_activated.emit(selected_action)
				active_action = selected_action
				return
		Actions.BUILD_SUPPORT:
			if active_action == null:
				player_action_activated.emit(selected_action)
				active_action = selected_action
				return
		Actions.PICKAXE:
			if selected_action in upgraded_actions:
				player_action_activated.emit(selected_action)
				active_action = selected_action
			elif active_action == null:
				player_action_activated.emit(selected_action)
				active_action = selected_action
			return


func update_selected_action():
	if Input.is_action_just_pressed("action_context_swap_to_support"):
		selected_action = Actions.BUILD_SUPPORT
	elif Input.is_action_just_pressed("action_context_swap_to_rope"):
		selected_action = Actions.BUILD_ROPE
	elif Input.is_action_just_pressed("action_context_swap_to_pickaxe"):
		selected_action = Actions.PICKAXE
	
	player_selected_action_updated.emit(selected_action)


func handle_animation_state():
	if active_action != null and sprite_node.animation not in action_animations:
		var animation_name := "PickaxeSwing" if active_action == Actions.PICKAXE else "HammerSwing"
		sprite_node.play(animation_name)

	if should_update_movement_animation():
		if velocity.x != 0:
			sprite_node.play("Run")
		else:
			sprite_node.play("Idle")

	# Determine sprite orientation for drawing
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		$AnimatedSprite2D.flip_h = true if direction < 0 else false


func should_update_movement_animation():
	return (
		not sprite_node.is_playing()
		or sprite_node.animation not in action_animations
	)


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite_node.animation in action_animations:
		if velocity.x != 0:
			sprite_node.play("Run")
		else:
			sprite_node.play("Idle")
		
		active_action = null


func _on_action_radius_mouse_entered() -> void:
	is_mouse_in_action_radius = true


func _on_action_radius_mouse_exited() -> void:
	is_mouse_in_action_radius = false


func _on_cave_playable_area_resource_collected(material_collected: PlayArea.CollectibleMaterials) -> void:
	materials_inventory[material_collected] += 1
	inventory_updated.emit(self)


func _on_ladder_radius_body_entered(body: Node2D) -> void:
	on_climbable_surface = true


func _on_ladder_radius_body_exited(body: Node2D) -> void:
	on_climbable_surface = false


func update_inventory(material: PlayArea.CollectibleMaterials, count: int):
	materials_inventory[material] = count
	inventory_updated.emit(self)


func _on_dwarven_keep_action_upgrade_dispensed(action: Player.Actions) -> void:
	upgraded_actions.append(action)
