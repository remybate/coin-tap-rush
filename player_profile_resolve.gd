extends RefCounted

## Reaches the PlayerProfile autoload by path — avoids relying on autoload name resolution at parse time (Godot 4.0.x).


static func node() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PlayerProfile")
