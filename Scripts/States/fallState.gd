extends State

func enter(from: State) -> void:
	player.animation_player.play("fall")
	print(from)
	print(from.name_id)
	if (from and from.name_id in ["IdleState", "RunningState"]) and not player.want_jump():
		player.coyote_timer.start()

func physics(delta: float) -> void:
	# ① 首跳（利用土狼时间）
	if player.want_jump() \
	and (not player.did_first_jump) \
	and (player.jumps_left > 0) \
	and player.can_first_jump():             # 这里会利用 coyote_timer.time_left > 0
		player.do_first_jump()
		player.animation_player.play("jump")
		machine.change_to_name("JumpState")
		return

	# ② 二段跳
	if player.want_jump() and player.can_second_jump():
		player.do_second_jump()
		player.animation_player.play("jump")
		machine.change_to_name("JumpState")
		return

	# ③ 落地
	if player.is_on_floor():
		if (player.input_dir() == 0.0) and is_zero_approx(player.velocity.x):
			machine.change_to_name("IdleState")
		else:
			machine.change_to_name("RunningState")
		return

	player.move_common(delta)
