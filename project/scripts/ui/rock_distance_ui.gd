## 화면 밖으로 나간 바위가 화면 경계 기준에서 얼마나 멀리 떨어져 있는지 표시합니다.
extends Control

const SCREEN_LEFT_BOUNDARY_X: float = -160.0

@export var distance_label: Label

func _ready() -> void:
	if not DebugValidator.validate(self, distance_label, "distance_label"):
		hide()
		return
	
	GameEvents.rock_marker_x_changed.connect(_update_rock_distance)

func _update_rock_distance(position_x: float) -> void:
	if position_x > SCREEN_LEFT_BOUNDARY_X:
		hide()
		return

	show()

	# 화면 경계선 기준으로 바위와의 거리를 계산
	var distance_px: float = SCREEN_LEFT_BOUNDARY_X - position_x
	var distance_meter: float = distance_px / GameSpeedManager.PIXELS_PER_METER
	distance_label.text = "%.2fm" % distance_meter