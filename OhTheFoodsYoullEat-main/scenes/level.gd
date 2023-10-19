extends Node2D

var healthyFoods = []
var unhealthyFoods = []
const selectedMat = preload("res://assets/redOutline.tres")
const foodScene = preload("res://scenes/food.tscn")
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
	$Landscape.play()


var spawnedFoods = []
var index = 1
var oldIndex = index
var isCooldowned = false
func _process(delta):
	if Input.is_action_just_pressed("left"):
		oldIndex = index
		index -= 1
		index = clamp(index, 0, 2)
	if Input.is_action_just_pressed("right"):
		oldIndex = index
		index += 1
		index = clamp(index, 0, 2)
	$HUD/SatBar.value = clamp(saturation, 0, 100)
	$HUD/AnxBar.value = clamp(anxiety, 0, 100)
	spawnedFoods[oldIndex].material = null
	spawnedFoods[index].material = selectedMat
	if Input.is_action_just_pressed("confirm") && not isCooldowned:
		if spawnedFoods[index].get_meta("isHealthy") == true:
			saturation += 5
			anxiety -= 2.5
		else:
			saturation += 7.5
			anxiety += 15
			if not $saturationDebuffTimer.time_left > 0:
				$saturationDebuffTimer.start()
		isCooldowned = true
		$selectionCooldownTimer.start()
		$spawnFoodTimer.start()
		spawnFoods()
	
func spawnFoods():
	for spawnedFood in spawnedFoods:
		spawnedFood.queue_free()
	spawnedFoods.clear()
	var healthyFoodIteration = randi_range(0, 2)
	var selectedIterationSprites = []
	for i in range(3):
		var food = foodScene.instantiate() 
		if i == healthyFoodIteration:
			var selectedTexture = healthyFoods[randi() % healthyFoods.size()]
			food.set_texture(selectedTexture)
			food.set_meta("isHealthy", true)
		else:
			food.set_texture(unhealthyFoods[randi() % unhealthyFoods.size()])
			food.set_meta("isHealthy", false)
		food.position = get_node("FoodSlot" + str(i)).position
		food.z_index = 1
		spawnedFoods.append(food)
		food.scale = Vector2(5, 5)
		food.fade_in()
		$Machines.play()
		add_child(food)

func _on_spawn_food_timer_timeout():
	spawnFoods()

var unhealthyDebuffCount = 0
func _on_saturation_debuff_timer_timeout():
	if(unhealthyDebuffCount >= 3):
		unhealthyDebuffCount = 0
		$saturationDebuffTimer.stop()
		return
	saturation -= 5
	var sb = StyleBoxFlat.new()
	$HUD/SatBar.add_theme_stylebox_override("fill", sb)
	sb.bg_color = Color("d50000")
	unhealthyDebuffCount += 1

func _on_passive_anxiety_debuff_timer_timeout():
	anxiety -= 1
	anxiety = clamp(anxiety, 0, 100)

func _on_selection_cooldown_timer_timeout():
	isCooldowned = false
