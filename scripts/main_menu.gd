extends Control

@onready var high_score_label: Label = $TopBar/HighScorePill/HighScoreLabel
@onready var coin_label: Label = $TopBar/CoinPill/CoinLabel
@onready var play_button: Button = $BottomBar/PlayButton
@onready var skins_button: Button = $BottomBar/RowSmall/SkinsButton
@onready var shop_button: Button = $BottomBar/RowSmall/ShopButton
@onready var settings_button: Button = $BottomBar/RowSmall/SettingsButton
@onready var daily_button: Button = $BottomBar/DailyButton
@onready var info_dialog: AcceptDialog = $InfoDialog
@onready var character: Panel = $CharacterPreview
@onready var cloud_a: Panel = $CloudA
@onready var cloud_b: Panel = $CloudB

func _ready() -> void:
	_refresh_labels()
	GameManager.coins_changed.connect(func(_v): _refresh_labels())
	play_button.pressed.connect(_on_play_pressed)
	skins_button.pressed.connect(func(): _show_info("Skins", "Menu Skins akan hadir di tahap berikutnya."))
	shop_button.pressed.connect(func(): _show_info("Shop", "Menu Shop akan hadir di tahap berikutnya."))
	settings_button.pressed.connect(func(): _show_info("Settings", "Menu Settings (music/sound/vibration) akan hadir di tahap berikutnya."))
	daily_button.pressed.connect(_on_daily_pressed)
	_start_idle_animations()

func _refresh_labels() -> void:
	high_score_label.text = "%d" % GameManager.high_score
	coin_label.text = "%d" % GameManager.coins

func _start_idle_animations() -> void:
	var char_tw := create_tween().set_loops()
	char_tw.tween_property(character, "position:y", character.position.y - 14, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	char_tw.tween_property(character, "position:y", character.position.y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var cloud_tw := create_tween().set_loops()
	cloud_tw.tween_property(cloud_a, "position:x", cloud_a.position.x + 30, 3.0).set_trans(Tween.TRANS_SINE)
	cloud_tw.tween_property(cloud_a, "position:x", cloud_a.position.x, 3.0).set_trans(Tween.TRANS_SINE)

	var cloud_tw2 := create_tween().set_loops()
	cloud_tw2.tween_property(cloud_b, "position:x", cloud_b.position.x - 24, 3.6).set_trans(Tween.TRANS_SINE)
	cloud_tw2.tween_property(cloud_b, "position:x", cloud_b.position.x, 3.6).set_trans(Tween.TRANS_SINE)

	var play_tw := create_tween().set_loops()
	play_tw.tween_property(play_button, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	play_tw.tween_property(play_button, "scale", Vector2(1, 1), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_play_pressed() -> void:
	var tw := create_tween()
	tw.tween_property(play_button, "scale", Vector2(0.88, 0.88), 0.08)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))

func _on_daily_pressed() -> void:
	if GameManager.can_claim_daily_reward():
		var reward := GameManager.claim_daily_reward()
		_show_info("Daily Reward", "Kamu mendapat %d coin! (Hari ke-%d)" % [reward, GameManager.daily_reward_streak])
	else:
		_show_info("Daily Reward", "Sudah diambil hari ini. Coba lagi besok!")

func _show_info(title: String, text: String) -> void:
	info_dialog.title = title
	info_dialog.dialog_text = text
	info_dialog.popup_centered()
