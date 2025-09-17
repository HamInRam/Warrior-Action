extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
}

var gravity := ProjectSettings.get_setting('physics/2d/default_gravity') as float

# 状态分组
const GROUND_STATE := [State.IDLE, State.RUNNING]
const AIR_STATE    := [State.JUMP, State.FALL]

const RUN_SPEED := 160.0
const JUMP_VELOCITY := -320.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.1
const AIR_ACCELERATION  := RUN_SPEED / 0.02

# Double Jump
const MAX_JUMP := 2
const DOUBLE_JUMP_WINDOW := 0.5
var jumps_left := MAX_JUMP
var did_first_jump := false

# Jump Buffer
const JUMP_REQUEST_WINDOW := 0.12

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var double_jump_timer: Timer = $DoubleJumpTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

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
		# 可变跳高（短跳）
		if velocity.y < JUMP_VELOCITY / 2.0:
			velocity.y = JUMP_VELOCITY / 2.0

# ---------------- FSM Hooks ----------------
func tick_physics(state: State, delta: float) -> void:
	# --- 二段跳：仅在空中态内触发（动作点） ---
	if state in AIR_STATE:
		var want_second := jump_request_timer.time_left > 0.0
		var can_second := did_first_jump and (double_jump_timer.time_left > 0.0) and (jumps_left > 0)
		if want_second and can_second:
			# 施加二段跳脉冲
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
			jump_request_timer.stop()
			double_jump_timer.stop()

	match state:
		State.IDLE, State.RUNNING, State.JUMP, State.FALL:
			move(delta)

func move(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION

	# Move with slide
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta

	# Flip the player
	if direction > 0:
		sprite_2d.flip_h = false
	elif direction < 0:
		sprite_2d.flip_h = true
	
	move_and_slide()

func get_next_state(state: State) -> State:
	var direction := Input.get_axis("move_left", "move_right")
	var is_still := (direction == 0) and is_zero_approx(velocity.x)

	# 跳跃相关判定
	var canFirstJump := is_on_floor() or coyote_timer.time_left > 0
	var wantJump := jump_request_timer.time_left > 0
	var canSecondJump := did_first_jump and (double_jump_timer.time_left > 0.0) and (jumps_left > 0)

	# 首跳：进入 JUMP（首跳脉冲在 transition_state 里施加）
	var shouldFirstJump := wantJump and (not did_first_jump) and (jumps_left > 0) and canFirstJump
	if shouldFirstJump:
		return State.JUMP
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			if not is_still:
				return State.RUNNING
			
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if is_still:
				return State.IDLE
			
		State.JUMP:
			if wantJump and canSecondJump:
				return State.JUMP
			# 上升到顶点后进入下落
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			# ★ 关键：在 FALL 时若满足二段跳条件 → 切到 JUMP（仅为切动画，不施加首跳）
			if wantJump and canSecondJump:
				return State.JUMP
			# 落地
			if is_on_floor():
				return State.IDLE if is_still else State.RUNNING
			
	return state

func transition_state(from: State, to: State) -> void:
	var wantJump := jump_request_timer.time_left > 0
	
	# 落地重置（空→地）
	if from in AIR_STATE and to in GROUND_STATE:
		jumps_left = MAX_JUMP
		did_first_jump = false
		double_jump_timer.stop()
		coyote_timer.stop()
		
	match to:
		State.IDLE:
			animation_player.play("idle")
			
		State.RUNNING:
			animation_player.play("running")
			
		State.JUMP:
			animation_player.play("jump")
			# 仅施加“首跳”；二段跳在 tick_physics 空中触发
			if not did_first_jump and jumps_left > 0 and (is_on_floor() or coyote_timer.time_left > 0.0):
				velocity.y = JUMP_VELOCITY
				jumps_left -= 1
				coyote_timer.stop()
				jump_request_timer.stop()
				
				# 记录一段跳结束，启动二段跳timer窗口
				did_first_jump = true
				double_jump_timer.start()
			
		State.FALL:
			animation_player.play("fall")
			# 从地面掉落且没有当前跳请求 → 开启土狼时间
			if from in GROUND_STATE and not wantJump:
				coyote_timer.start()
