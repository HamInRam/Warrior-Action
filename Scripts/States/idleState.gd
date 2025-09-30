extends State

func enter(_from: State) -> void:
	player.animation_player.play("idle")
	player.reset_on_ground()

func physics(delta: float) -> void:
	if player.want_jump() and (not player.did_first_jump) and (player.jumps_left > 0) and player.can_first_jump():
		machine.change_to_name("JumpState")
		return

	if not player.is_on_floor():
		machine.change_to_name("FallState")
		return

	if not ((player.input_dir() == 0.0) and is_zero_approx(player.velocity.x)):
		machine.change_to_name("RunningState")
		return

	player.move_common(delta)
