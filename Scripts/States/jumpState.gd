extends State

func enter(from: State) -> void:
	player.animation_player.play("jump")
	if not player.did_first_jump and player.jumps_left > 0 and player.can_first_jump():
		player.do_first_jump()
		return
	
	# From other state to check double jump
	if player.want_jump() and player.can_second_jump():
		player.do_second_jump()
		return

func physics(delta: float) -> void:
	# In jump state to check double jump
	if player.want_jump() and player.can_second_jump():
		player.do_second_jump()

	if player.velocity.y >= 0.0:
		machine.change_to_name("FallState")
		return

	player.move_common(delta)
