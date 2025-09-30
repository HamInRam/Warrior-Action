class_name State
extends Node

var machine: StateMachine
var player
var name_id: StringName

func _ready() -> void:
	machine = get_parent() as StateMachine
	player  = machine.player
	name_id = name

func enter(_from: State) -> void: pass
func exit(_to: State) -> void: pass
func physics(delta: float) -> void: pass
func input(event: InputEvent) -> void: pass
