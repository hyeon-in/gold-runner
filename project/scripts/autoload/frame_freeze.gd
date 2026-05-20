## FrameFreeze.gd (Autoload)
## 게임 화면을 정지시키는 이펙트를 처리하는 싱글톤입니다.
extends Node

const TIME_SCALE: float = 0.001

var _freeze_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func freeze(duration: float) -> void:
	if _freeze_tween:
		_freeze_tween.kill()
	
	Engine.time_scale = TIME_SCALE

	_freeze_tween = create_tween().set_ignore_time_scale()
	_freeze_tween.tween_interval(duration)
	_freeze_tween.tween_callback(_on_finished_tween)

## 프리즈 상태이면 끝날 때까지 대기합니다.
func wait_until_finished() -> void:
	if _freeze_tween and _freeze_tween.is_valid():
		await _freeze_tween.finished

## 프리즈 트윈이 종료되면 time_scale을 복구합니다.
func _on_finished_tween() -> void:
	Engine.time_scale = 1.0