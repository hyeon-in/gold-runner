## 범용적인 장애물을 처리합니다.
## 게임 속도에 비례해 스폰 주기를 동적으로 조절하며, 화면 밖으로 벗어나면 자동으로 대기 상태로 전환됩니다.
extends Node2D

const DEACTIVATE_POSITION_X: float = -200
const WARNING_HIDE_POSITION_X: float = 160

enum State { INACTIVE, ACTIVE, DYING }

@export_group("Nodes")
@export var hitbox: ObstacleHitbox
@export var sprite: Sprite2D
@export var particles: CPUParticles2D

@export_group("Settings")
## 게임 시작 시 (속도가 0일 때)의 기본 스폰 주기입니다.
@export_range(0.1, 60.0, 0.01, "suffix:s") var max_spawn_interval: float = 10.0
## 최고 속도에 도달했을 때의 가장 빠른 스폰 주기입니다.
@export_range(0.1, 60.0, 0.01, "suffix:s") var min_spawn_interval: float = 2.0
## 무작위 스폰 주기 오프셋 범위입니다.
@export_range(0.0, 5.0, 0.01, "suffix:s") var spawn_interval_random_offset: float = 1.0
## 경고 사용 여부입니다.
@export var use_warning: bool = true

var _initial_position: Vector2
var _spawn_timer: float = 0.0
var _spawn_interval_offset : float = 0.0
var _spawn_time_overflow: float = 0.0
var _is_warning_active: bool = false
var _is_game_over: bool = false
var _current_state: State = State.INACTIVE

func _ready() -> void:
	if not DebugValidator.validate(self, hitbox, "hitbox"):
		set_physics_process(false)
		return

	_initial_position = global_position

	if particles:
		particles.emitting = false
		particles.one_shot = true

	hitbox.hurt.connect(_on_hurt)
	GameEvents.game_over.connect(_on_game_over)
	
	_reset_spawn_offset()
	_change_state(State.INACTIVE)

func _physics_process(delta: float) -> void:
	match _current_state:
		State.INACTIVE:
			var current_interval: float = remap(GameSpeedManager.current_speed, 0.0, GameSpeedManager.MAX_SPEED, max_spawn_interval, min_spawn_interval)
			_spawn_timer += delta
			if _spawn_timer >= max(0.0, current_interval + _spawn_interval_offset):
				# 프레임 지연으로 초과된 시간만큼 스폰 위치 보정
				_spawn_time_overflow = _spawn_timer - max(0.0, current_interval + _spawn_interval_offset)
				_change_state(State.ACTIVE)
		State.ACTIVE:
				var speed: float = GameSpeedManager.current_speed * GameSpeedManager.KMH_TO_MPS * GameSpeedManager.PIXELS_PER_METER
				global_position -= GameEnvironment.DOWNHILL_DIRECTION * speed * delta
				
				if _is_warning_active and global_position.x <= WARNING_HIDE_POSITION_X:
					_hide_warning()
				
				if global_position.x <= DEACTIVATE_POSITION_X:
					_change_state(State.INACTIVE)

## 장애물의 상태를 전환하고 각 상태에 필요한 초기화와 연출을 처리합니다.
func _change_state(new_state: State) -> void:
	_current_state = new_state
	_spawn_timer = 0.0

	match _current_state:
		State.INACTIVE:
			_set_hitbox_active(false)
			_hide_warning()
			_reset_spawn_offset()
			hide()
		State.ACTIVE:
			var speed: float = GameSpeedManager.current_speed * GameSpeedManager.KMH_TO_MPS * GameSpeedManager.PIXELS_PER_METER
			# 속도 * 초과된 시간 만큼 이동 거리를 보정해서 스폰 위치 지정
			var spawn_offset: Vector2 = GameEnvironment.DOWNHILL_DIRECTION * speed * _spawn_time_overflow

			global_position = _initial_position + spawn_offset

			_set_hitbox_active(true)
			reset_physics_interpolation()

			if sprite:
				sprite.show()
			
			# 활성화 되면 경고 표시
			if use_warning:
				_is_warning_active = true
				GameEvents.oak_cask_warning_started.emit()
			
			show()
		State.DYING:
			_set_hitbox_active(false)
			_hide_warning()
			
			if sprite:
				sprite.hide()
			
			if particles:
				particles.emitting = true
				await particles.finished
			
			# 이미 게임 오버 된 상태일 경우 상태를 변경하지 않음
			if _is_game_over:
				return

			_change_state(State.INACTIVE)

## 무작위 오프셋 시간을 초기화합니다.
func _reset_spawn_offset() -> void:
	_spawn_interval_offset = randf_range(-spawn_interval_random_offset, spawn_interval_random_offset)

## 히트박스의 활성화 여부를 설정합니다.
func _set_hitbox_active(active: bool) -> void:
	hitbox.set_deferred("monitorable", active)
	hitbox.set_deferred("monitoring", active)

## 활성화 된 경고 표시 이펙트를 종료하도록 이벤트를 발생시킵니다.
func _hide_warning() -> void:
	if _is_warning_active:
		_is_warning_active = false
		GameEvents.oak_cask_warning_finished.emit()

## 공격 받았을 때 사망 처리를 실행합니다.
func _on_hurt() -> void:
	if _current_state == State.DYING or _current_state == State.INACTIVE:
		return

	_change_state(State.DYING)

## 게임 오버가 되면 물리 연산을 중단합니다.
func _on_game_over() -> void:
	_is_game_over = true
	set_physics_process(false)
	_hide_warning()
	_set_hitbox_active(false)