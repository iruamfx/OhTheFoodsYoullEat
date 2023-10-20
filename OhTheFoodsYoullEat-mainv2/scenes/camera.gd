extends Camera2D

var trauma = 0.0
var trauma_power = 2
var amount = 0.0
var decay = 0.8
var max_offset = Vector2(36, 64)
var max_roll = 0.1

func _ready():
	randomize()

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		rough_shake()

func rough_shake():
	amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)

func set_shake(add_trauma = 0.5):
	trauma = min(trauma + add_trauma, 1.0)
	
#feito por iruam codigo inteirinho juro juradinho






















#🤞
