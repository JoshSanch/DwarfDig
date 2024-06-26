class_name PlayArea
extends TileMap
signal resource_collected(material_collected: CollectibleMaterials)

enum CollectibleMaterials { WOOD, STONE, GOLD, COAL }

@onready
var falling_debris_scene: PackedScene = preload("res://Scenes/Projectiles/FallingDebris.tscn")
@onready var fall_timer: Timer = $WaveFallTimer
@onready var dirt_cursor_sprite: Sprite2D = $DirtCursor
@onready var queued_tiles_to_fall: Array[Vector2i] = []
@onready var active_rope_end_tiles: Array[Vector2i] = []
@onready var world_size := self.get_used_rect()

var cave_state_update

const NULL_TILE_SOURCE_ID = -1
const DIRT_TILE_SOURCE_ID = 2
const DIRT_TILE_SPAWN_ATLAS_COORDS = Vector2i(1, 10)
const DIRT_TILE_LAYER = 0
const MATERIAL_TILE_LAYER = 1
const SUPPORT_TILE_SOURCE_ID = 1
const STATIC_TILE_SOURCE_ID = 0
const STATIC_TILE_ATLAS_COORDS = Vector2i(1, 1)
const ROPE_SOURCE_ID = 7
const ROPE_ATLAS_INFINITE_COORD = Vector2i(0, 1)
const ROPE_ATLAS_FLOOR_COORD = Vector2i(0, 2)

const MATERIAL_ATLAS_MAP := {
	CollectibleMaterials.WOOD: 3,
	CollectibleMaterials.STONE: 4,
	CollectibleMaterials.GOLD: 5,
	CollectibleMaterials.COAL: 6
}
const BUILDINGS_SOURCE_ID_MAP := {
	Player.Actions.BUILD_ROPE: 7,
	Player.Actions.BUILD_SUPPORT: 1
}

@export var horizontal_support_weights = [0, 1, 3]
@export var vertical_support_weights = [0, 5, 3, 1]
@export var world_support_weight = 20
@export var support_factor_threshold = 16
@export var mat_spawn_threshold := 0.25
@export var materials_resources: Array[CollectableMaterial] = []
@export var noise: FastNoiseLite


func _on_wave_fall_timer_timeout() -> void:
	trigger_queued_falls()
	cave_state_update = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_terrain()

	cave_state_update = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update cave state if actions have occurred
	if cave_state_update:
		update_cave_state()
		cave_state_update = false

	draw_mouse_interaction_cursor()


func _on_falling_debris_body_entered(body: Node, debris_node: Node2D):
	if body == self:
		var tile_coord = local_to_map(to_local(debris_node.global_position))
		set_cell(
			DIRT_TILE_LAYER,
			Vector2i(tile_coord.x, tile_coord.y - 1),
			DIRT_TILE_SOURCE_ID,
			DIRT_TILE_SPAWN_ATLAS_COORDS
		)
		debris_node.queue_free()


func draw_mouse_interaction_cursor():
	var tile_pos = local_to_map(to_local(get_global_mouse_position()))

	dirt_cursor_sprite.position = map_to_local(tile_pos)


func update_cave_state():
	update_rope_bottoms()
	
	# TODO: Debug cave-ins
	#var loose_dirt_tiles = find_loose_dirt_tiles()
	#for tile_coord in loose_dirt_tiles:
#		var support_factor = calculate_support_factor(tile_coord)
#		if support_factor < support_factor_threshold:
#			print_debug(tile_coord)
#			set_cell(0, tile_coord, NULL_TILE_SOURCE_ID)
#			queued_tiles_to_fall.append(tile_coord)
#			fall_timer.start()


func update_rope_bottoms():
	var new_end_tiles: Array[Vector2i] = []
	while active_rope_end_tiles:
		var tile_coord = active_rope_end_tiles.pop_front()
		if get_cell_source_id(0, Vector2i(tile_coord.x, tile_coord.y + 1)) != NULL_TILE_SOURCE_ID:
			new_end_tiles.append(tile_coord)
			continue
			
		set_cell(0, tile_coord, ROPE_SOURCE_ID, ROPE_ATLAS_INFINITE_COORD)
		tile_coord = Vector2i(tile_coord.x, tile_coord.y + 1)
		while get_cell_source_id(0, tile_coord) == NULL_TILE_SOURCE_ID:
			var tile_atlas_coord := ROPE_ATLAS_INFINITE_COORD
			if get_cell_source_id(0, Vector2i(tile_coord.x, tile_coord.y + 1)) != NULL_TILE_SOURCE_ID:
				tile_atlas_coord = ROPE_ATLAS_FLOOR_COORD
				new_end_tiles.append(tile_coord)
			
			set_cell(0, tile_coord, ROPE_SOURCE_ID, tile_atlas_coord)
			tile_coord = Vector2i(tile_coord.x, tile_coord.y + 1)

	active_rope_end_tiles = new_end_tiles


func find_loose_dirt_tiles() -> Array[Vector2i]:
	var loose_dirt_tiles: Array[Vector2i] = []
	for tile_coords: Vector2i in self.get_used_cells(0):
		if is_loose_dirt_tile(tile_coords):
			loose_dirt_tiles.append(tile_coords)

	return loose_dirt_tiles


func is_loose_dirt_tile(tile_coords: Vector2i):
	var neighbor_cells = get_surrounding_cells(tile_coords)
	var bottom_neighbor_coords = neighbor_cells[1]
	return (
		get_cell_source_id(0, tile_coords) == DIRT_TILE_SOURCE_ID
		and (
			get_cell_source_id(0, bottom_neighbor_coords)
			not in [DIRT_TILE_SOURCE_ID, STATIC_TILE_SOURCE_ID]
		)
		and get_cell_atlas_coords(0, tile_coords) != STATIC_TILE_ATLAS_COORDS
	)


func trigger_queued_falls():
	for tile_coords in queued_tiles_to_fall:
		# set_cell(0, tile_coords, 0, Vector2i(3, 0))
		var falling_sprite_node: RigidBody2D = falling_debris_scene.instantiate() as RigidBody2D
		falling_sprite_node.global_position = to_global(map_to_local(tile_coords))
		falling_sprite_node.process_mode = Node.PROCESS_MODE_ALWAYS
		falling_sprite_node.visible = true
		add_child(falling_sprite_node)
		falling_sprite_node.get_node("Area2D").body_entered.connect(
			_on_falling_debris_body_entered.bind(falling_sprite_node)
		)

	queued_tiles_to_fall = []


func calculate_support_factor(tile_coords: Vector2i):
	# Support factor is defined as:
	# - Support provided by nearby horizontal tiles, weighted more the further from the current tile dirt exists
	# - Support from above tiles, weighted less the further from the current tile dirt exists
	# - Support from under the tile from a non-dirt entity
	var base_support_factor = (
		world_support_weight
		* int(
			(
				get_cell_source_id(0, Vector2i(tile_coords.x, tile_coords.y + 1))
				== SUPPORT_TILE_SOURCE_ID
			)
		)
	)
	return (
		base_support_factor
		+ calculate_horizontal_support_factor(tile_coords)
		+ calculate_vertical_support_factor(tile_coords)
	)


func calculate_horizontal_support_factor(tile_coords):
	var max_distance_from_tile = len(horizontal_support_weights) - 1

	var left_boundary_index = tile_coords.x - max_distance_from_tile
	var right_boundary_index = tile_coords.x + max_distance_from_tile

	var horizontal_support_factor = 0
	for horizontal_index in range(left_boundary_index, right_boundary_index + 1, 1):
		if get_cell_source_id(0, Vector2i(horizontal_index, tile_coords.y)) == DIRT_TILE_SOURCE_ID:
			horizontal_support_factor += horizontal_support_weights[abs(
				horizontal_index - tile_coords.x
			)]

	return horizontal_support_factor


func calculate_vertical_support_factor(tile_coords):
	var max_distance_from_tile = len(horizontal_support_weights) - 1

	var left_boundary_index = tile_coords.x - max_distance_from_tile
	var right_boundary_index = tile_coords.x + max_distance_from_tile

	var horizontal_support_factor = 0
	for horizontal_index in range(left_boundary_index, right_boundary_index + 1, 1):
		if get_cell_source_id(0, Vector2i(horizontal_index, tile_coords.y)) == DIRT_TILE_SOURCE_ID:
			horizontal_support_factor += horizontal_support_weights[abs(
				horizontal_index - tile_coords.x
			)]

	return horizontal_support_factor


func draw_debug_coordinates():
	for tile_coords in get_used_cells(0):
		var debug_coordinate_node := RichTextLabel.new()
		debug_coordinate_node.position = to_global(map_to_local(tile_coords))
		debug_coordinate_node.text = str(tile_coords)
		debug_coordinate_node.visible = true
		debug_coordinate_node.z_index = 99
		debug_coordinate_node.fit_content = true
		debug_coordinate_node.theme = preload("res://Assets/Themes/debug_text.tres")
		debug_coordinate_node.autowrap_mode = TextServer.AUTOWRAP_OFF
		add_child(debug_coordinate_node)


func _on_player_player_action_activated(action: Player.Actions) -> void:
	match action:
		Player.Actions.PICKAXE:
			handle_action_dig()
		Player.Actions.BUILD_SUPPORT, Player.Actions.BUILD_ROPE:
			handle_action_build(action)


func handle_action_dig():
	# Digging changes the world, enable updates again
	cave_state_update = true

	var selected_tile_pos = local_to_map(to_local(get_global_mouse_position()))
	if get_cell_source_id(0, selected_tile_pos) != ROPE_SOURCE_ID:
		set_cell(0, selected_tile_pos, NULL_TILE_SOURCE_ID)

		# Collect materials present at tile position
		var mined_material_tile_source_id = get_cell_source_id(1, selected_tile_pos)
		if mined_material_tile_source_id != NULL_TILE_SOURCE_ID:
			var mined_material: CollectibleMaterials
			for collectible_material in MATERIAL_ATLAS_MAP:
				if MATERIAL_ATLAS_MAP[collectible_material] == mined_material_tile_source_id:
					mined_material = collectible_material

			resource_collected.emit(mined_material)
			set_cell(1, selected_tile_pos, NULL_TILE_SOURCE_ID)


func handle_action_build(action: Player.Actions):
	var selected_tile_pos = local_to_map(to_local(get_global_mouse_position()))
	if get_cell_source_id(0, selected_tile_pos) != NULL_TILE_SOURCE_ID:
		return  # Can't build on non-empty tiles

	if (can_build(action, selected_tile_pos)):
		place_building(action, selected_tile_pos)


func can_build(action: Player.Actions, base_build_pos: Vector2i):
	if action == Player.Actions.BUILD_SUPPORT:
		var support_tiles := tile_set.get_source(SUPPORT_TILE_SOURCE_ID) as TileSetAtlasSource
		var support_atlas_grid_size = support_tiles.get_atlas_grid_size()
		for x_offset in range(support_atlas_grid_size.x):
			for y_offset in range(support_atlas_grid_size.y):
				# Build starts from bottom left of atlas
				var offset_coords := Vector2i(base_build_pos.x + x_offset, base_build_pos.y - y_offset)
				if get_cell_source_id(0, offset_coords) != NULL_TILE_SOURCE_ID:
					print_debug("Cannot build support, blocked at %s" % offset_coords)
					return false
	elif action == Player.Actions.BUILD_ROPE:
		if get_cell_source_id(0, Vector2i(base_build_pos.x, base_build_pos.y + 1)) != NULL_TILE_SOURCE_ID:
			print_debug("Cannot build rope at %s" % base_build_pos)
			return false

	return true


func place_building(action: Player.Actions, base_build_pos: Vector2i):
	if action == Player.Actions.BUILD_SUPPORT:
		var support_tiles := tile_set.get_source(SUPPORT_TILE_SOURCE_ID) as TileSetAtlasSource
		var support_atlas_grid_size = support_tiles.get_atlas_grid_size()
		
		# This math is so ugly I'm sorry, but it works :(
		for x_offset in range(support_atlas_grid_size.x):
			for y_offset in range(support_atlas_grid_size.y - 1, -1, -1):
				# Build starts from bottom left of atlas
				var offset_coords := Vector2i(base_build_pos.x + x_offset, base_build_pos.y + y_offset - 1)
				set_cell(0, offset_coords, SUPPORT_TILE_SOURCE_ID, Vector2i(x_offset, y_offset))
	elif action == Player.Actions.BUILD_ROPE:
		var current_cell := base_build_pos
		set_cell(0, current_cell, ROPE_SOURCE_ID, Vector2i(0,0))
		
		current_cell = Vector2i(current_cell.x, current_cell.y + 1)
		while get_cell_source_id(0, current_cell) == NULL_TILE_SOURCE_ID:
			var tile_atlas_coord := ROPE_ATLAS_INFINITE_COORD
			if get_cell_source_id(0, Vector2i(current_cell.x, current_cell.y + 1)) != NULL_TILE_SOURCE_ID:
				tile_atlas_coord = ROPE_ATLAS_FLOOR_COORD
				active_rope_end_tiles.append(current_cell)
			
			set_cell(0, current_cell, ROPE_SOURCE_ID, tile_atlas_coord)
			current_cell = Vector2i(current_cell.x, current_cell.y + 1)


func generate_terrain():
	noise.seed = randi()
	var cave_size := get_used_rect().size
	for y in cave_size.y:
		for x in cave_size.x:
			if get_cell_source_id(0, Vector2i(x, y)) != DIRT_TILE_SOURCE_ID:
				continue

			if noise.get_noise_2d(x, y) + 1 >= mat_spawn_threshold:
				place_collectable_material(x, y)


func place_collectable_material(cell_col, cell_row):
	# Iterate through minerals, from the rarest to least rare.
	var i := CollectibleMaterials.COAL as int
	while i >= CollectibleMaterials.WOOD:
		if _check_set(i, cell_col, cell_row):
			return
		i -= 1


func _check_set(collectible_material: CollectibleMaterials, x: int, y: int) -> bool:
	var cave_size := get_used_rect().size
	if materials_resources[collectible_material].can_spawn(y, cave_size.y):
		if materials_resources[collectible_material].randomize_rotation:
			set_cell(1, Vector2i(x, y), MATERIAL_ATLAS_MAP[collectible_material], Vector2i(0, 0))
			# TODO: ROTATE!
		else:
			set_cell(1, Vector2i(x, y), MATERIAL_ATLAS_MAP[collectible_material], Vector2i(0, 0))
		return true
	return false
