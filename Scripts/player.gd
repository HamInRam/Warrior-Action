extends CharacterBody2D

# 物理参数
var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
const RUN_SPEED := 160.0
const JUMP_VELOCITY := -320.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.1
const AIR_ACCELERATION  := RUN_SPEED / 0.02

# 跳跃系统
const MAX_JUMP := 2
const DOUBLE_JUMP_WINDOW := 0.5
const JUMP_REQUEST_WINDOW := 0.12
const JUMP_CUTOFF := JUMP_VELOCITY / 2.0

var jumps_left := MAX_JUMP
var did_first_jump := false

# 节点引用
@onready var sprite_2d: Sprite2D          = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer          = $CoyoteTimer
@onready var double_jump_timer: Timer     = $DoubleJumpTimer
@onready var jump_request_timer: Timer    = $JumpRequestTimer
@onready var fsm: StateMachine            = $StateMachine
# debug label
@onready var state_label: Label = $StateLabel

func _ready() -> void:
	double_jump_timer.one_shot = true
	double_jump_timer.wait_time = DOUBLE_JUMP_WINDOW
	jump_request_timer.one_shot = true
	jump_request_timer.wait_time = JUMP_REQUEST_WINDOW

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_CUTOFF:
			velocity.y = JUMP_CUTOFF
	fsm._unhandled_input(event)

# 工具方法（状态里会调用）
func input_dir() -> float:
	return Input.get_axis("move_left", "move_right")

func accel_current() -> float:
	return FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION

func face_by(dir: float) -> void:
	if dir > 0.0:  sprite_2d.flip_h = false
	elif dir < 0.0: sprite_2d.flip_h = true

func move_common(delta: float) -> void:
	velocity.x = move_toward(velocity.x, input_dir() * RUN_SPEED, accel_current() * delta)
	velocity.y += gravity * delta
	face_by(input_dir())
	move_and_slide()

func want_jump() -> bool:
	return jump_request_timer.time_left > 0.0

func can_first_jump() -> bool:
	return is_on_floor() or coyote_timer.time_left > 0.0

func can_second_jump() -> bool:
	return did_first_jump and (double_jump_timer.time_left > 0.0) and (jumps_left > 0)

func do_first_jump() -> void:
	velocity.y = JUMP_VELOCITY
	jumps_left -= 1
	did_first_jump = true
	coyote_timer.stop()
	jump_request_timer.stop()
	double_jump_timer.start()

func do_second_jump() -> void:
	velocity.y = JUMP_VELOCITY
	jumps_left -= 1
	jump_request_timer.stop()
	double_jump_timer.stop()

func reset_on_ground() -> void:
	jumps_left = MAX_JUMP
	did_first_jump = false
	double_jump_timer.stop()
	coyote_timer.stop()
