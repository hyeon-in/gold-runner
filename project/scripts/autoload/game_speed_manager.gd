## GameSpeedManager.gd (Autoload)
## 시간 경과에 따라 게임 속도를 증가시키고,
#@# 플레이어가 장애물에 충돌 시 감속 및 회복 처리하는 싱글톤입니다.
extends Node

# 속도 설정
const MAX_SPEED: float = 200.0
const INITIAL_SPEED: float = 10.0
const SPEED_INCREASE_PER_SECOND: float = 2.0

# Physics 설정
const PHYSICS_FPS: int = 60
const ACCELERATION_PER_TICK: float = SPEED_INCREASE_PER_SECOND / PHYSICS_FPS

# 거리 단위 변환
const PIXELS_PER_METER: float = 16.0 # 16픽셀을 1미터로 설정
const KMH_TO_MPS: float = 1000.0 / 3600.0 # Km/h 단위를 m/s 단위로 변환

# 충돌 및 회복 설정
const COLLISION_PENALTY_RATE: float = 0.5
const RECOVERY_DURATION: float = 1.0
const RECOVERY_TICKS: int = int(RECOVERY_DURATION * PHYSICS_FPS)

var current_speed: float = INITIAL_SPEED

var _is_recovering: bool = false
var _recovery_ticks_left: int = 0
var _penalty_target_speed: float = 0.0

func _ready() -> void:
	set_physics_process(false)

	GameEvents.game_start.connect(_on_game_start)
	GameEvents.game_over.connect(_on_game_over)

func _physics_process(_delta: float) -> void:
	if not _is_recovering:
		_update_speed()
	else:
		_update_recovery()
	
	GameEvents.speed_updated.emit(current_speed)

## 속도 증가 처리
func _update_speed() -> void:
	current_speed = min(current_speed + ACCELERATION_PER_TICK, MAX_SPEED)

## 충돌 후 속도 회복 처리
func _update_recovery() -> void:
	_recovery_ticks_left -= 1

	var t: float = 1.0 - (float(_recovery_ticks_left) / RECOVERY_TICKS)
	current_speed = lerp(0.0, _penalty_target_speed, t)

	if _recovery_ticks_left <= 0:
		_is_recovering = false
		current_speed = _penalty_target_speed

## 장애물 충돌 시 속도 감소를 처리합니다.
func collision_obstacle() -> void:
	_penalty_target_speed = current_speed * COLLISION_PENALTY_RATE

	# 충돌 시 순간적으로 속도 0으로 변경
	current_speed = 0.0

	_is_recovering = true
	_recovery_ticks_left = RECOVERY_TICKS

	GameEvents.speed_updated.emit(current_speed)

## 게임이 시작될 때 필요한 설정을 초기화합니다.
func _on_game_start() -> void:
	current_speed = INITIAL_SPEED

	_is_recovering = false
	_recovery_ticks_left = 0

	set_physics_process(true)

## 게임 오버가 되면 프로세스를 중단하고 속도를 0으로 만듭니다.
func _on_game_over() -> void:
	set_physics_process(false)
	current_speed = 0.0