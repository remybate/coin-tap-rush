extends Node
## Clears play-root position when the tree pauses so a mid-shake offset never sticks (children stay pausable).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var p := get_parent() as Node2D
	if p != null and get_tree().paused:
		p.position = Vector2.ZERO
