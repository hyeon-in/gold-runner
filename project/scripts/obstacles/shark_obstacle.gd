## 땅속에서 튀어나오며 공격하는 상어를 처리합니다.
extends Node2D

enum State { INACTIVE, WAIT, ATTACKING, DYING}

const ANIMATION_WAIT = &"wait"
const ANIMATION_ATTACK = &"attack"
const ANIMATION_DEATH = &"death"

const DEATH_FLY_AWAY_SPEED: float = 600.0
const DEATH_FLY_DIRECTION: Vector2 = Vector2(1.0, -1.0)

const DEACTIVATE_POSITION_LEFT: float = -200.0
const DEACTIVATE_POSITION_RIGHT: float = 400.0

@export_group("Nodes")
@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer
@export var hitbox: ObstacleHitbox
@export var warning_ui: Control

@export_group("Settings")
## 경고 후 공격 까지 걸리는 시간
@export_range(0.0, 10.0, 0.01, "suffix:s") var attack_delay: float = 2.0
## 게임 시작 시 (속도가 0일 때)의 기본 스폰 주기입니다.
@export_range(0.1, 60.0, 0.01, "suffix:s") var max_spawn_interval: float = 10.0
## 최고 속도(200)에 도달했을 때의 가장 빠른 스폰 주기입니다.
@export_range(0.1, 60.0, 0.01, "suffix:s") var min_spawn_interval: float = 2.0
## 무작위 스폰 주기 오프셋 범위입니다.
@export_range(0.0, 5.0, 0.01, "suffix:s") var spawn_interval_random_offset: float = 1.0
## 무작위 스폰 위치 거리를 지정합니다.
@export_range(0.0, 320.0, 0.1, "suffix:px") var spawn_distance_random_offset: float = 300.0

var _initial_position: Vector2
var _state_timer: float = 0.0
var _spawn_interval_offset : float = 0.0
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
			_state_timer += delta
			if _state_timer >= max(0.0, current_interval + _spawn_interval_offset):
				_change_state(State.WAIT)
		State.WAIT:
			_state_timer += delta
			if _state_timer >= attack_delay:
				_change_state(State.ATTACKING)
		State.ATTACKING:
			var speed: float = GameSpeedManager.current_speed * GameSpeedManager.KMH_TO_MPS * GameSpeedManager.PIXELS_PER_METER
			global_position -= GameEnvironment.DOWNHILL_DIRECTION  * speed * delta
			if global_position.x <= DEACTIVATE_POSITION_LEFT:
				_change_state(State.INACTIVE)
		State.DYING:
			# 피격 후 화면 밖으로 날아가는 연출
			global_position += DEATH_FLY_DIRECTION.normalized() * DEATH_FLY_AWAY_SPEED * delta
			if global_position.x >= DEACTIVATE_POSITION_RIGHT:
				_change_state(State.INACTIVE)

## 상어의 상태를 전환하고 각 상태에 필요한 초기화와 연출을 처리합니다.
func _change_state(new_state: State) -> void:
	_current_state = new_state
	_state_timer = 0.0

	match _current_state:
		State.INACTIVE:
			_reset_spawn_offset()
			_set_warning_visible(false)
			_set_hitbox_active(false)

			hide()
		State.WAIT:
			# 비탈길 방향 기준으로 스폰 위치를 무작위 조정
			var random_distance_offset: Vector2 = GameEnvironment.DOWNHILL_DIRECTION  * randf_range(0.0, spawn_distance_random_offset)
			global_position = _initial_position + random_distance_offset
			reset_physics_interpolation()

			_set_hitbox_active(false)
			_set_warning_visible(true)
			if animation_player:
				animation_player.play(ANIMATION_WAIT)

			show()
		State.ATTACKING:
			_set_hitbox_active(true)
			_set_warning_visible(false)
			if animation_player:
				animation_player.play(ANIMATION_ATTACK)
		State.DYING:
			_set_hitbox_active(false)
			_set_warning_visible(false)
			if animation_player:
				animation_player.play(ANIMATION_DEATH)

## 히트박스의 활성화 여부를 설정합니다.
func _set_hitbox_active(active: bool) -> void:
	hitbox.set_deferred("monitorable", active)
	hitbox.set_deferred("monitoring", active)

## 경고 UI의 표시 여부를 관리합니다.
func _set_warning_visible(enabled: bool) -> void:
	if not warning_ui:
		return
	warning_ui.visible = enabled

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
	_set_warning_visible(false)
	_set_hitbox_active(false)