@tool
extends Marker2D

@export var tilemap: TileMapLayer

@export var golden_feather: Node2D:
	set(value):
		golden_feather = value
		_last_feather_pos = Vector2.INF

var _last_feather_pos: Vector2 = Vector2.INF

@export var editor_icon: Texture2D

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if editor_icon:
		var size := editor_icon.get_size()
		
		draw_texture_rect(
			editor_icon,
			Rect2(Vector2(-size.x * 0.5, -size.y + 4), editor_icon.get_size()),
			false,
			Color(1, 1, 1, 0.4))
		

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not golden_feather:
		return

	queue_redraw()

	if golden_feather.global_position != _last_feather_pos:
		_last_feather_pos = golden_feather.global_position
		snap_to_tilemap()

func snap_to_tilemap() -> void:
	if !is_instance_valid(golden_feather) or not tilemap:
		return

	var local = tilemap.to_local(golden_feather.global_position)
	var cell = tilemap.local_to_map(local)

	while tilemap.get_cell_source_id(cell) == -1:
		cell.y += 1

	var tile_local = tilemap.map_to_local(cell)

	tile_local.y -= tilemap.tile_set.tile_size.y * 0.5
	global_position = tilemap.to_global(tile_local)
	global_position.x = golden_feather.global_position.x
