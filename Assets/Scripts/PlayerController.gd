class_name Player

extends CharacterBody2D
signal player_action_activated(action: Actions)
signal player_active_action_updated(action: Actions)

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
@onready var active_action: Actions = Actions.PICKAXE
@onready var is_mouse_in_action_radius = false
@onready var materials_inventory = {
	PlayArea.CollectibleMaterials.WOOD: 0,
	PlayArea.CollectibleMaterials.STONE: 0,
	PlayArea.CollectibleMaterials.GOLD: 0,
	PlayArea.CollectibleMaterials.COAL: 0
}

@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0


func _process(delta: float) -> void:
	update_active_action()
	handle_animation_state()
	if is_mouse_in_action_radius and Input.is_action_just_pressed("action_contextual"):
		player_action_activated.emit(active_action)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func update_active_action():
	if Input.is_action_just_pressed("action_context_swap_to_support"):
		active_action = Actions.BUILD_SUPPORT
	elif Input.is_action_just_pressed("action_context_swap_to_rope"):
		active_action = Actions.BUILD_ROPE
	elif Input.is_action_just_pressed("action_context_swap_to_pickaxe"):
		active_action = Actions.PICKAXE
	
	player_active_action_updated.emit(active_action)

func handle_animation_state():
	if velocity.x != 0 and should_update_movement_animation():
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


func _on_action_radius_mouse_entered() -> void:
	is_mouse_in_action_radius = true


func _on_action_radius_mouse_exited() -> void:
	is_mouse_in_action_radius = false


func _on_cave_playable_area_resource_collected(material_collected: PlayArea.CollectibleMaterials) -> void:
	materials_inventory[material_collected] += 1
