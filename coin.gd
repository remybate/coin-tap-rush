extends Button

var speed = 200

func _ready():
	position.x = 540
	position.y = 0

func _process(delta):
	position.y += speed * delta

	if position.y > 600:
		position.y = 0
