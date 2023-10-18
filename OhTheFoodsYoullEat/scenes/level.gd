extends Node2D

var healthyFoods = []
var unhealthyFoods = []
const selectedMat = preload("res://assets/selectedOutline.tres")
var saturation = 0
var anxiety = 0

func _ready():
	var dir = DirAccess.open("res://assets/foods")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.ends_with(".import"):
				if file_name.begins_with("h"):
					healthyFoods.append(load("res://assets/foods/" + file_name))
				else:
					unhealthyFoods.append(load("res://assets/foods/" + file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	spawnFoods()

var spawnedFoods = []
var index = 1
var oldIndex = index
func _process(delta):
	if Input.is_action_just_pressed("left"):
		oldIndex = index
		index -= 1
		index = clamp(index, 0, 2)
	if Input.is_action_just_pressed("right"):
		oldIndex = index
		index += 1
		index = clamp(index, 0, 2)
	spawnedFoods[oldIndex].material = null
	spawnedFoods[index].material = selectedMat
	if Input.is_action_just_pressed("confirm"):
		if spawnedFoods[index].get_meta("isHealthy") == true:
			saturation += 10
			anxiety -= 10
		else:
			saturation += 25
			anxiety += 20

func spawnFoods():
	print(spawnedFoods.size())
	for food in spawnedFoods:
		food.queue_free() #tomar no xanaino
	spawnedFoods.clear()
	for i in range(3):
		var isFoodHealthy = true if randi() % 2 == 0 else false
		var food = Sprite2D.new()
		if isFoodHealthy:
			food.set_texture(healthyFoods[randi() % healthyFoods.size()])
			food.set_meta("isHealthy", true)
		else:
			food.set_texture(unhealthyFoods[randi() % unhealthyFoods.size()])
			food.set_meta("isHealthy", false)
		food.position = get_node("FoodSlot" + str(i)).position
		food.z_index = 1
		spawnedFoods.append(food)
		food.scale = Vector2(10, 10)
		add_child(food)

func _on_reset_food_timer_timeout():
	spawnFoods()
