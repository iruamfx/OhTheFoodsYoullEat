extends Node2D

var healthyFoods = []
var unhealthyFoods = []
const selectedMat = preload("res://assets/shaders/redOutline.tres")
const foodScene = preload("res://scenes/food.tscn")
var saturation = 0
var anxiety = 0
var saturationDebuffLimit = 0

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
var isTransitioningLandscape = false
func _process(delta):
	handle_user_input()
	if not isTransitioningLandscape:
		apply_anxiety_effects()
	

func handle_user_input():
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
			saturationDebuffLimit += 3
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
			var selectedTexture = unhealthyFoods[randi() % unhealthyFoods.size()]
			while selectedTexture in selectedIterationSprites:
				print("selectedTex ", i, " has already been selected, reiterating selection")
				selectedTexture = unhealthyFoods[randi() % unhealthyFoods.size()]
			selectedIterationSprites.append(selectedTexture)
			food.set_texture(selectedTexture)
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

var saturationDebuffIterationCount = 0
func _on_debuff_timer_timeout():
	if(saturationDebuffIterationCount <= saturationDebuffLimit):
		if(saturationDebuffIterationCount == saturationDebuffLimit):
			saturationDebuffIterationCount = 0
			saturationDebuffLimit = 0
			saturation -= 0.25
			print("Decreasing 0.25 because LIMIT")
		else:
			saturation -= 1.5
			saturationDebuffIterationCount += 1
			print("Decreasing 1.5")
	anxiety -= 0.25
	anxiety = clamp(anxiety, 0, 100)
	saturation = clamp(saturation, 0, 100)

func _on_selection_cooldown_timer_timeout():
	isCooldowned = false

var currentAnxietyState = "low"
const transition_delay = 0.25
const anx_base_intensity = 0.05
const anx_scaling_factor = 0.05
const time_base_intensity = 4.5
const time_scaling_factor = -0.017
func apply_anxiety_effects():
	var vignetteLevel = anx_base_intensity * exp(anx_scaling_factor * anxiety)
	var timeWaitLevel = time_base_intensity * exp(time_scaling_factor * anxiety)
	$HUD/VignetteRect.material.set_shader_parameter("vignette_intensity", vignetteLevel)
	$spawnFoodTimer.set_wait_time(clamp(timeWaitLevel, 1.15, 4.5)) #talvez refazer
	if anxiety <= 30 && not currentAnxietyState == "low":
		$cameraShakeTimer.set_wait_time(1)
		$cameraShakeTimer.stop()
		isTransitioningLandscape = true
		$Landscape.animation = "lightning_trans"
		await get_tree().create_timer(transition_delay).timeout
		$Landscape.animation = "low"
		currentAnxietyState = "low"
		isTransitioningLandscape = false
	elif anxiety > 30 && anxiety <= 60 && not currentAnxietyState == "med":
		currentAnxietyState = "med"
		$cameraShakeTimer.set_wait_time(1)
		if $cameraShakeTimer.is_stopped():
			$cameraShakeTimer.start()
		isTransitioningLandscape = true
		$Landscape.animation = "lightning_trans"
		await get_tree().create_timer(transition_delay).timeout
		$Landscape.animation = "med"
		isTransitioningLandscape = false
	elif anxiety > 60 && anxiety <= 100 && not currentAnxietyState == "high":
		currentAnxietyState = "high"
		$cameraShakeTimer.set_wait_time(0.75)
		isTransitioningLandscape = true
		$Landscape.animation = "lightning_trans"
		await get_tree().create_timer(transition_delay).timeout
		$Landscape.animation = "high"
		isTransitioningLandscape = false

func _on_camera_shake_timer_timeout():
	$Camera2D.set_shake()

