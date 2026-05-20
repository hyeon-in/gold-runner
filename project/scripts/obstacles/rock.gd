## 비탈길을 굴러가며 플레이어를 쫓아가는 돌로 이 게임의 핵심 요소이자 게임 오버 역할을 담당합니다.
class_name Rock
extends Node2D

const ACCELERATION: float = 1.0
const GAME_OVER_SPEED: float = 600.0
const DESPAWN_X_THRESHOLD: float = 320.0
const DUST_EMISSION_X_MIN: float = -160.0
const ROLL_ROTATION_MULTIPLIER: float = 0.3

@export_group("Nodes")
@export var tracking_marker: Marker2D
@export var sprite: Sprite2D
@export var dust_particles: CPUParticles2D

@export_group("Settings")
@export var initial_chase_speed: float = 10.0

var _chase_speed: float = 0.0

func _ready() -> void:
	if not DebugValidator.validate_batch(self, {
		tracking_marker: "tracking_marker",
		sprite: "sprite"
	}):
		set_physics_process(false)
		return
	
	_chase_speed = initial_chase_speed
	GameEvents.game_over.connect(_on_game_over)

func _physics_process(delta: float) -> void:
	if global_position.x > DESPAWN_X_THRESHOLD:
		queue_free.call_deferred()
		return
	
	# 스프라이트 회전 연출
	sprite.rotate((_chase_speed * ROLL_ROTATION_MULTIPLIER) * delta)

	# 게임 속도와의 차분만큼 위치 이동 (상대 속도 보정)
	var speed_difference: float = _chase_speed - GameSpeedManager.current_speed
	global_position += GameEnvironment.DOWNHILL_DIRECTION * speed_difference * delta

	_chase_speed += ACCELERATION * delta

	# 일정 이상 위치에서만 파티클 활성화(최적화 처리)
	if dust_particles and tracking_marker:
		dust_particles.emitting = tracking_marker.global_position.x > DUST_EMISSION_X_MIN

	GameEvents.rock_marker_x_changed.emit(tracking_marker.global_position.x)

## 게임 오버 시 빠르게 화면 밖까지 돌진하는 연출을 처리합니다.
func _on_game_over() -> void:
	_chase_speed = GAME_OVER_SPEED
