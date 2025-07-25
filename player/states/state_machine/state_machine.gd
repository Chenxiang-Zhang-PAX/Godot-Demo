class_name StateMachine extends Node

## The initial state of the state machine. If not set, the first child node is used.
@export var initial_state: State = null
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"


## The current state of the state machine.
@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()

func _ready() -> void:
	# Give every state a reference to the state machine.
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(_transition_to_next_state)

	# State machines usually access data from the root node of the scene they're part of: the owner.
	# We wait for the owner to be ready to guarantee all the data and nodes the states may need are available.
	await owner.ready
	animation_player.animation_finished.connect(_on_anim_finished)
	state.enter("")
	

func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)


func _process(delta: float) -> void:
	state.process(delta)


func _physics_process(delta: float) -> void:
	state.physics_process(delta)


func _transition_to_next_state(target_state_path: String, data: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		printerr(owner.name + ": Trying to transition from " + state.name + " to state " + target_state_path + " but it does not exist.")
		return

	print("[", state.name, "] -> [", target_state_path, "]")
	var previous_state_path := state.name
	state.exit()
	state = get_node(target_state_path)
	state.enter(previous_state_path, data)

func _on_anim_finished(anim_name):
	if state and "on_animation_finished" in state:
		#print("Calling [", state, "] on_animation_finished with anim name: ", anim_name)
		state.on_animation_finished(anim_name)
