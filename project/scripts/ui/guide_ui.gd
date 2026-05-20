## 잠시 동안 키 설명 UI를 보여준 후 제거합니다.
extends Control

const DISPLAY_DURATION: float = 8.0

static var _has_shown_tutorial: bool = false

func _ready() -> void:
	if _has_shown_tutorial:
		queue_free()
		return
	
	_has_shown_tutorial = true

	await get_tree().create_timer(DISPLAY_DURATION, true, false, true).timeout

	if is_inside_tree():
		queue_free()