class_name StateMachine
extends Node

@export var initial_state_path: NodePath
var current: State = null
var player

func _ready() -> void:
	await owner.ready
	player = owner

	# ★ 把 machine / player 引用注入到所有 State 子节点，避免它们自己在 _ready 里拿到 null
	for c in get_children():
		if c is State:
			c.machine = self
			c.player  = player

	# 选择初始状态
	if initial_state_path != NodePath():
		current = get_node(initial_state_path) as State
	else:
		for c in get_children():
			if c is State:
				current = c
				break

	if current:
		current.enter(null)

func change_to(to_state: State) -> void:
	if not to_state or to_state == current: return
	var from := current
	if from: from.exit(to_state)
	current = to_state
	current.enter(from)
	
	if player and player.has_node('StateLabel'):
		player.state_label.text = current.name_id

# 修复 has_node 形参类型：把 StringName 转 NodePath
func change_to_name(child_name: StringName) -> void:
	var path := NodePath(child_name)             # ← 关键修复点
	if has_node(path):
		var node := get_node(path)
		if node is State:
			change_to(node as State)

func _unhandled_input(event: InputEvent) -> void:
	if current:
		current.input(event)

func _physics_process(delta: float) -> void:
	if current:
		current.physics(delta)
