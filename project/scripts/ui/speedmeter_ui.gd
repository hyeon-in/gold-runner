## 현재 게임 속도를 속도계 UI로 표시합니다.
extends Control

const MIN_ANGLE: float = -150
const MAX_ANGLE: float = 150
const JITTER_AMOUNT: float = 5.0

@export var arrow_ui: Control
@export var speed_label: Label

func _ready() -> void:
	if not DebugValidator.validate_batch(self, {
		arrow_ui:"arrow_ui",
		speed_label:"speed_label"
	}):
		set_physics_process(false)
		return

	arrow_ui.rotation_degrees = MIN_ANGLE
	_update_speed_label(GameSpeedManager.current_speed)

	GameEvents.speed_updated.connect(_update_speed_label)
	GameEvents.game_over.connect(_on_game_over)

func _physics_process(_delta: float) -> void:
	_update_arrow_rotation()

## 현재 속도에 맞춰 속도계 바늘 회전 및 흔들림 연출을 처리합니다.
func _update_arrow_rotation() -> void:
	var t: float = inverse_lerp(0.0, GameSpeedManager.MAX_SPEED, GameSpeedManager.current_speed)
	var target_angle: float = lerp(MIN_ANGLE, MAX_ANGLE, t)

	# 속도계 바늘이 떨리는 연출 처리
	var jitter: float = randf_range(-JITTER_AMOUNT, JITTER_AMOUNT)

	arrow_ui.rotation_degrees = target_angle + jitter

func _update_speed_label(current_speed: float) -> void:
	speed_label.text = "%dkm/h" % current_speed

func _on_game_over() -> void:
	set_physics_process(false)