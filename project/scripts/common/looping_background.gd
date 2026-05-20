## 무한 스크롤 배경 오브젝트를 처리합니다.
extends Node2D

@export var _loop_position: Vector2 = Vector2(-529.0, -143.0)
@export_range(0.0, 5.0, 0.01) var _scroll_factor: float = 1.0

var _initial_position: Vector2
var _scroll_direction: Vector2

func _ready() -> void:
	_initial_position = global_position
	# 초기 위치에서 루프 위치의 방향을 구해 스크롤 방향으로 설정합니다.
	_scroll_direction = (_initial_position - _loop_position).normalized()

func _physics_process(delta: float) -> void:
	var speed: float = GameSpeedManager.current_speed * (GameSpeedManager.KMH_TO_MPS * GameSpeedManager.PIXELS_PER_METER)
	global_position -= _scroll_direction * speed * _scroll_factor * delta

	# 현재 위치가 루프 경계선을 넘어섰는지 내적 연산으로 판정
	var to_loop := global_position - _loop_position
	if to_loop.dot(_scroll_direction) <= 0.0:
		# 경계선을 얼마나 초과했는지 픽셀 거리 계산 후 초과한 거리만큼을 보정하여 초기 위치로 이동
		var overshoot_distance_x: float = _loop_position.x - global_position.x
		var total_overshoot_distance: float = overshoot_distance_x / _scroll_direction.x
		var overshoot_vector: Vector2 = _scroll_direction * total_overshoot_distance

		global_position = _initial_position - overshoot_vector
		reset_physics_interpolation()