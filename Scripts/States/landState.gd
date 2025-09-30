extends State

func enter(from: State) -> void:
	player.animation_player.play("landing")
	return

func physics(delta: float) -> void:
	if not player.animation_player.is_playing():
		machine.change_to_name("IdleState")
		return
	
	player.stand_common(delta)
