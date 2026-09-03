extends Node2D
## Controller scene gameplay utama (Game.tscn) - versi cartoon UI.

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var bg_layer1: ParallaxLayer = $Background/ParallaxLayer1
@onready var bg_layer2: ParallaxLayer = $Background/ParallaxLayer2
@onready var bg_layer3: ParallaxLayer = $Background/ParallaxLayer3

@onready var score_label: Label = $UI/ScorePill/ScoreLabel
@onready var coin_label: Label = $UI/CoinPill/CoinLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var difficulty_label: Label = $UI/DifficultyLabel
@onready var pause_button: Button = $UI/PauseButton
@onready var shield_icon: Panel = $UI/ShieldPill/ShieldIcon
@onready var coin_pill: Panel = $UI/CoinPill
@onready var countdown_label: Label = $UI/CountdownLabel

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_panel: Panel = $PauseMenu/Panel
@onready var game_over_menu: CanvasLayer = $GameOverMenu
@onready var go_panel: Panel = $GameOverMenu/Panel
@onready var go_score_value: Label = $GameOverMenu/Panel/VBox/ScoreValue
@onready var go_coins_value: Label = $GameOverMenu/Panel/VBox/CoinsValue
@onready var go_best_value: Label = $GameOverMenu/Panel/VBox/BestValue
@onready var go_new_high: Label = $GameOverMenu/Panel/VBox/NewHighLabel
@onready var confetti: CPUParticles2D = $GameOverMenu/Confetti

var _magnet_active := false
var _coin2x_active := false
var _slowmo_active := false
var _magnet_timer := 0.0
var _coin2x_timer := 0.0
var _slowmo_timer := 0.0
var _game_started := false
var _displayed_coins := 0

func _ready() -> void:
	GameManager.start_new_run()
	spawner.set_player(player)
	spawner.ground_y = player.position.y
	player.died.connect(_on_player_died)
	pause_menu.visible = false
	game_over_menu.visible = false
	pause_button.pressed.connect(_toggle_pause)
	spawner.powerup_collected.connect(_on_powerup_collected)
	spawner.coin_collected.connect(_on_coin_collected)
	shield_icon.get_parent().modulate.a = 0.35
	_run_countdown()

func _run_countdown() -> void:
	player.is_alive = false # tahan input selama countdown
	for text in ["3", "2", "1", "GO!"]:
		countdown_label.text = text
		countdown_label.visible = true
		countdown_label.scale = Vector2(0.4, 0.4)
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(countdown_label, "scale", Vector2(1, 1), 0.25)
		await get_tree().create_timer(0.5).timeout
	countdown_label.visible = false
	player.is_alive = true
	_game_started = true

func _physics_process(delta: float) -> void:
	if not player.is_alive or not _game_started:
		return

	var speed: float = 500.0 * GameManager.get_speed_multiplier()
	if _slowmo_active:
		speed *= 0.45

	GameManager.add_distance(speed * delta)

	bg_layer1.motion_offset.x -= speed * delta * 0.2
	bg_layer2.motion_offset.x -= speed * delta * 0.45
	bg_layer3.motion_offset.x -= speed * delta * 0.8

	_update_hud()
	_update_powerup_timers(delta)
	_apply_magnet_to_coins()

func _update_hud() -> void:
	score_label.text = str(GameManager.run_score)
	combo_label.text = "Combo x%d" % GameManager.run_combo
	combo_label.visible = GameManager.run_combo > 1
	difficulty_label.text = GameManager.get_difficulty_name()
	shield_icon.get_parent().modulate.a = 1.0 if player.has_shield else 0.35

func _update_powerup_timers(delta: float) -> void:
	if _magnet_active:
		_magnet_timer -= delta
		if _magnet_timer <= 0:
			_magnet_active = false
	if _coin2x_active:
		_coin2x_timer -= delta
		if _coin2x_timer <= 0:
			_coin2x_active = false
			spawner.coin_multiplier = 1
	if _slowmo_active:
		_slowmo_timer -= delta
		if _slowmo_timer <= 0:
			_slowmo_active = false

func _apply_magnet_to_coins() -> void:
	if not _magnet_active:
		return
	for child in spawner.get_children():
		if child.has_method("set_magnet_target") and child.global_position.distance_to(player.global_position) < 500.0:
			child.set_magnet_target(player)

func _on_powerup_collected(power_type: String) -> void:
	match power_type:
		"magnet":
			_magnet_active = true
			_magnet_timer = 6.0
		"shield":
			player.activate_shield()
		"coin2x":
			_coin2x_active = true
			_coin2x_timer = 8.0
			spawner.coin_multiplier = 2
		"slowmo":
			_slowmo_active = true
			_slowmo_timer = 4.0

func _on_coin_collected(value: int, world_pos: Vector2) -> void:
	# Animasi coin "terbang" menuju counter + sparkle + counter naik.
	var ghost := Panel.new()
	ghost.size = Vector2(24, 24)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 0.85, 0.1, 1)
	box.set_corner_radius_all(12)
	box.border_color = Color(0.106, 0.122, 0.231, 1)
	box.set_border_width_all(3)
	ghost.add_theme_stylebox_override("panel", box)
	ghost.global_position = world_pos
	ghost.z_index = 100
	add_child(ghost)

	var target: Vector2 = coin_pill.global_position + coin_pill.size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "global_position", target, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(ghost, "scale", Vector2(0.4, 0.4), 0.45)
	tw.chain().tween_callback(func():
		ghost.queue_free()
		_pop_coin_pill()
	)

func _pop_coin_pill() -> void:
	_displayed_coins += 1
	coin_label.text = str(GameManager.run_coins)
	var tw := create_tween()
	tw.tween_property(coin_pill, "scale", Vector2(1.25, 1.25), 0.08)
	tw.tween_property(coin_pill, "scale", Vector2(1, 1), 0.12)

func _on_player_died() -> void:
	GameManager.end_run()
	go_score_value.text = str(GameManager.run_score)
	go_coins_value.text = str(GameManager.run_coins)
	go_best_value.text = str(GameManager.high_score)
	var is_new_high := GameManager.is_new_high_score()
	go_new_high.visible = is_new_high
	game_over_menu.visible = true
	get_tree().paused = true
	go_panel.scale = Vector2(0.6, 0.6)
	go_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(go_panel, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(go_panel, "modulate:a", 1.0, 0.2)
	if is_new_high:
		confetti.emitting = true

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused
	if pause_menu.visible:
		pause_panel.scale = Vector2(0.7, 0.7)
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(pause_panel, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
