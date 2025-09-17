extends Node2D
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var camera_2d: Camera2D = $Player/Camera2D

func _ready() -> void:
	var used := tile_map_layer.get_used_rect().grow(-1)
	print(used)
	var tile_size := tile_map_layer.tile_set.tile_size
	
	# calculate the limit area for camera 2d
	# based on the tileMapLayer	
	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_bottom = used.end.y * tile_size.y
	
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.limit_right = used.end.x * tile_size.x
	
	# reset_smoothing at the beginning for the weird camera shake
	# to drag user back to the center
	camera_2d.reset_smoothing()
