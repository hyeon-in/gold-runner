## 하늘을 날아다니며 플레이어를 추적하는 유령을 처리합니다.
extends Node2D

enum State { INACTIVE, ACTIVE, DYING}

const ANIMATION_DEFAULT = &"default"
const ANIMATION_DEATH = &"death"

const DEATH_FLY_AWAY_SPEED: float = 600.0
const DEATH_FLY_DIRECTION: Vector2 = Vector2(1.0, -1.0)

const WARNING_HIDE_POSITION_X: float = 160.0
const DEACTIVATE_POSITION_X: float = 400.0

@export_group("Nodes")
@export var hitbox: ObstacleHitbox
@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer

@export_group("Settings")
## 유령의 플레이어 추격 속도입니다.
@export_range(0.0, 1000.0, 1.0, "suffix:px") var chase_speed: float = 120.0
## 게임 시작 시 기본 스폰 주기입니다.
@export_range(0.1, 60.0, 0.01, "suffix:s") var max_spawn_interval: float = 10.0
## 최고 속도에 도달했을 때의 가장 빠른 스폰 주기입니다.
@export_range(0.1, 60.0, 0.01, "suffix:s") var min_spawn_interval: float = 2.0
## 무작위 스폰 주기 오프셋 범위입니다.
@export_range(0.0, 5.0, 0.01, "suffix:s") var spawn_interval_random_offset: float = 1.0

var _initial_position: Vector2
var _spawn_timer: float = 0.0
var _spawn_interval_offset: float = 0.0
var _is_warning_active: bool = false
var _current_state: State = State.INACTIVE

func _ready() -> void:
	if not DebugValidator.validate(self, hitbox, "hitbox"):
		set_physics_process(false)
		return

	_initial_position = global_position

	hitbox.hurt.connect(_on_hurt)
	GameEvents.game_over.connect(_on_game_over)

	_change_state(State.INACTIVE)

func _physics_process(delta: float) -> void:
	match _current_state:
		State.INACTIVE:
			var current_interval: float = remap(GameSpeedManager.current_speed, 0.0, GameSpeedManager.MAX_SPEED, max_spawn_interval, min_spawn_interval)
			_spawn_timer += delta
			if _spawn_timer >= max(0.0, current_interval + _spawn_interval_offset):
				_change_state(State.ACTIVE)
		State.ACTIVE:
			var player_instance := Player.instance
			if is_instance_valid(player_instance):
				var direction: Vector2 = (player_instance.global_position - global_position).normalized()
				global_position += direction * chase_speed * delta
				
			if _is_warning_active and global_position.x <= WARNING_HIDE_POSITION_X:
				_hide_warning()

		State.DYING:
			# 피격 후 화면 밖으로 날아가는 연출
			global_position += DEATH_FLY_DIRECTION.normalized() * DEATH_FLY_AWAY_SPEED * delta
			if global_position.x >= DEACTIVATE_POSITION_X:
				_change_state(State.INACTIVE)

## 유령의 상태를 전환하고 각 상태에 필요한 초기화와 연출을 처리합니다.
func _change_state(new_state: State) -> void:
	_current_state = new_state
	_spawn_timer = 0.0

	match _current_state:
		State.INACTIVE:
			global_position = _initial_position
			reset_physics_interpolation()

			_set_hitbox_active(false)

			_reset_spawn_offset()
			_hide_warning()
			hide()
		State.ACTIVE:
			_set_hitbox_active(true)

			_is_warning_active = true
			GameEvents.ghost_warning_started.emit()

			if animation_player:
				animation_player.play(ANIMATION_DEFAULT)
			
			show()
		State.DYING:
			_set_hitbox_active(false)
			_hide_warning()

			if animation_player:
				animation_player.play(ANIMATION_DEATH)

## 히트박스의 활성화 여부를 설정합니다.
func _set_hitbox_active(active: bool) -> void:
	hitbox.set_deferred("monitorable", active)
	hitbox.set_deferred("monitoring", active)

## 활성화 된 경고 표시 이펙트를 종료하도록 이벤트를 발생시킵니다.
func _hide_warning() -> void:
	if _is_warning_active:
		_is_warning_active = false
		GameEvents.ghost_warning_finished.emit()

## 무작위 오프셋 시간을 초기화합니다.
func _reset_spawn_offset() -> void:
	_spawn_interval_offset = randf_range(-spawn_interval_random_offset, spawn_interval_random_offset)

## 공격 받았을 때 사망 처리를 실행합니다.
func _on_hurt() -> void:
	if _current_state == State.DYING or _current_state == State.INACTIVE:
		return

	_change_state(State.DYING)

## 게임 오버가 되면 물리 연산을 중단합니다.
func _on_game_over() -> void:
	set_physics_process(false)
	_hide_warning()
	_set_hitbox_active(false)