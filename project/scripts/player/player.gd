## 플레이어 캐릭터를 제어하는 클래스입니다.
class_name Player
extends CharacterBody2D

# 애니메이션 이름
const ANIMATION_RUN := &"run"
const ANIMATION_FAST_RUN := &"fast_run"
const ANIMATION_VERY_FAST_RUN := &"very_fast_run"
const ANIMATION_JUMP := &"jump"
const ANIMATION_FALLING := &"falling"
const ANIMATION_ATTACK := &"attack"
const ANIMATION_DEATH := &"death"

# 입력 액션
const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_JUMP := &"jump"
const ACTION_ATTACK := &"attack"

# 플레이어의 이동 범위 경계선
const MIN_X: float = -160.0
const MAX_X: float = 160.0

# 애니메이션 전환 기준이 되는 속도
const FAST_SPEED_THRESHOLD: float = GameSpeedManager.MAX_SPEED * 0.5

# 스쿼시 & 스트레치 설정
const JUMP_STRETCH_SCALE := Vector2(0.5, 1.5)
const LANDING_STRETCH_SCALE := Vector2(1.5, 0.5)
const STRETCH_TWEEN_DURATION: float = 0.2

# 잔상 효과 설정
const AFTERIMAGE_EFFECT_INTERVAL: float = 0.02
const AFTERIMAGE_EFFECT_DURATION: float = 0.1

# 사망 연출 처리
const DEATH_BOUNCE_OFFSET := Vector2(0.0, -50.0)
const DEATH_FALL_OFFSET := Vector2(0.0, 400.0)

const DEATH_BOUNCE_DURATION: float = 0.4
const DEATH_FALL_DURATION: float = 2.0

@export_group("Movement Settings")
@export_range(0.0, 500.0, 1.0, "suffix:px") var move_speed: float = 170.0
@export_range(0.0, 10.0, 0.01, "suffix:s") var acceleration_time: float = 0.4
@export_range(0.0, 10.0, 0.01, "suffix:s") var friction_time: float = 0.25
@export_range(0.0, 10.0, 0.01, "suffix:x") var air_control_modifier: float = 1.5
@export_range(0.0, 1000.0, 1.0) var jump_force: float = 320.0
@export_range(0.0, 1000.0, 1.0) var gravity: float = 450.0
@export_range(0.0, 5.0, 0.01, "suffix:s") var jump_input_buffer_time: float = 0.25

@export_group("Nodes")
@export var pivot: Node2D
@export var visuals: ActorVisuals
@export var spin_gold_statue: AnimatedSprite2D
@export var run_dust_particles: CPUParticles2D
@export var jump_dust_particles: CPUParticles2D
@export var afterimage_effect: AfterimageEffects
@export var animation_player: AnimationPlayer

@export_group("SFX")
@export var jump_sound: AudioStream
@export var landing_sound: AudioStream
@export var attack_swing_sound: AudioStream

static var instance: CharacterBody2D

var _move_direction: float = 0.0
var _is_attacking: bool = false
var _was_on_floor: bool = true

var _jump_input_buffer_timer: float = 0.0
var _afterimage_timer: float = 0.0

func _ready() -> void:
	# 선택 노드 검증
	DebugValidator.validate_batch(self, {
		visuals: "visuals",
		spin_gold_statue: "spin_gold_statue",
		afterimage_effect: "afterimage_effect",
		run_dust_particles: "run_dust_particles" ,
		jump_dust_particles: "jump_dust_particles",
		jump_sound: "jump_sound",
		landing_sound: "landing_sound",
		attack_swing_sound: "attack_swing_sound"
	}, false)

	# 필수 노드 검증
	if not DebugValidator.validate_batch(self, {
		pivot: "pivot",
		animation_player: "animation_player"
	}):
		set_physics_process(false)
		return
	
	instance = self

	collision_mask = PhysicsLayers.WORLD

	if jump_dust_particles:
		jump_dust_particles.emitting = false
		jump_dust_particles.one_shot = true
		jump_dust_particles.top_level = true
	
	if spin_gold_statue:
		spin_gold_statue.hide()
	
	GameEvents.game_over.connect(_on_game_over)
	animation_player.animation_finished.connect(_on_animation_finished)

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _physics_process(delta: float) -> void:
	_handle_input()

	_update_jump_buffer(delta)

	_update_movement(delta)
	_update_world_constraints()

	_update_visual_effects(delta)
	_update_animations_state()

## 플레이어의 입력을 받아오고 실행합니다.
func _handle_input() -> void:
	_move_direction = Input.get_axis(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT)

	if Input.is_action_just_pressed(ACTION_JUMP):
		_jump_input_buffer_timer = jump_input_buffer_time

	if Input.is_action_just_pressed(ACTION_ATTACK):
		_perform_attack()

## 플레이어의 공격 실행
func _perform_attack() -> void:
	if _is_attacking:
		return
	
	_is_attacking = true

	# 왼쪽 입력 시 왼쪽 공격 처리
	if _move_direction < 0.0:
		_set_facing_direction(-1.0)

	animation_player.play(ANIMATION_ATTACK)

	_play_sfx(attack_swing_sound)

## 점프 버퍼 타이머를 처리합니다.
func _update_jump_buffer(delta: float) -> void:
	if _jump_input_buffer_timer > 0.0:
		_jump_input_buffer_timer -= delta

func _update_movement(delta: float) -> void:
	_handle_horizontal_movement(delta)
	_apply_gravity(delta)
	_handle_jump()
	move_and_slide()

## 플레이어의 수평 이동을 처리합니다.
func _handle_horizontal_movement(delta: float) -> void:
	# 땅 위에 있는지 공중에 있는지 따라 가속도/감속도가 달라짐
	var control_modifier: float = air_control_modifier if not is_on_floor() else 1.0
	var target_time: float = (acceleration_time if _move_direction != 0 else friction_time) * control_modifier
	var acceleration_force: float = (move_speed / max(target_time, 0.01)) * delta

	velocity.x = move_toward(velocity.x, _move_direction * move_speed, acceleration_force)

## 플레이어의 중력을 처리합니다.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

## 플레이어의 점프를 제어합니다.
func _handle_jump() -> void:
	if not is_on_floor() or _jump_input_buffer_timer <= 0.0:
		return

	_jump_input_buffer_timer = 0.0
	velocity.y = -jump_force

	_play_sfx(jump_sound)
	_play_jump_feedback()

## 플레이어의 이동 범위 제한을 처리합니다.
func _update_world_constraints() -> void:
	global_position.x = clamp(global_position.x, MIN_X, MAX_X)
	if global_position.x <= MIN_X or global_position.x >= MAX_X:
		velocity.x = 0.0

func _update_visual_effects(delta: float) -> void:
	_update_run_particles()
	_update_landing_feedback()
	_update_afterimage(delta)

## 바닥에 있을 때만 달릴 때 나오는 먼지 파티클 이펙트를 실행합니다.
func _update_run_particles() -> void:
	if run_dust_particles:
		run_dust_particles.emitting = is_on_floor()

## 착지 시에 발생하는 이펙트를 처리합니다.
func _update_landing_feedback() -> void:
	if is_on_floor() and not _was_on_floor:
		_play_sfx(landing_sound)
		if visuals:
			visuals.apply_squash_and_stretch(LANDING_STRETCH_SCALE, STRETCH_TWEEN_DURATION)

	_was_on_floor = is_on_floor()

## 속도가 최고 속도에 도달했을 경우 잔상 이펙트 효과를 처리합니다.
func _update_afterimage(delta: float) -> void:
	if GameSpeedManager.current_speed >= GameSpeedManager.MAX_SPEED:
		_afterimage_timer -= delta
		if _afterimage_timer <= 0.0:
			if afterimage_effect:
				afterimage_effect.emit(visuals, AFTERIMAGE_EFFECT_DURATION)
			_afterimage_timer = AFTERIMAGE_EFFECT_INTERVAL
	else:
		_afterimage_timer = 0.0

## 애니메이션의 상태를 제어합니다.
func _update_animations_state() -> void:
	if _is_attacking:
		return

	var target_animation := _get_target_animation()
	if animation_player.current_animation != target_animation:
		animation_player.play(target_animation)

## 현재 상태에 맞는 애니메이션 이름을 반환합니다.
func _get_target_animation() -> StringName:
	if not is_on_floor():
		return ANIMATION_JUMP if velocity.y <= 0.0 else ANIMATION_FALLING
	
	if GameSpeedManager.current_speed < FAST_SPEED_THRESHOLD:
		return ANIMATION_RUN
	elif GameSpeedManager.current_speed < GameSpeedManager.MAX_SPEED:
		return ANIMATION_FAST_RUN
	
	return ANIMATION_VERY_FAST_RUN

## 점프 시에 발생하는 연출을 처리합니다.
func _play_jump_feedback() -> void:
	if visuals:
		visuals.apply_squash_and_stretch(JUMP_STRETCH_SCALE, STRETCH_TWEEN_DURATION)
	if jump_dust_particles:
		jump_dust_particles.global_position = global_position
		jump_dust_particles.reset_physics_interpolation()
		jump_dust_particles.emitting = true

## 효과음을 재생합니다.
func _play_sfx(sfx: AudioStream) -> void:
	if sfx:
		AudioManager.play_sfx(sfx)

## 캐릭터가 바라보는 방향을 처리합니다.
func _set_facing_direction(direction: float) -> void:
	if not pivot:
		return
	
	var new_scale := pivot.scale
	new_scale.x = abs(pivot.scale.x) * sign(direction)
	pivot.scale = new_scale


## 공격이 끝났을 때 공격을 중단하고 캐릭터가 앞을 바라보게 합니다.
func _finish_attack() -> void:
	if _is_attacking:
		_is_attacking = false
		_set_facing_direction(1.0)

## 사망 애니메이션을 실행합니다
func _play_death_animation() -> void:
	animation_player.play(ANIMATION_DEATH)
	var bounce_position: Vector2 = global_position + DEATH_BOUNCE_OFFSET
	var tween:Tween = get_tree().create_tween()

	tween.tween_property(
		self, 
		"global_position",
		bounce_position,
		DEATH_BOUNCE_DURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.tween_property(
		self,
		"global_position",
		bounce_position + DEATH_FALL_OFFSET,
		DEATH_FALL_DURATION
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	tween.tween_callback(queue_free.call_deferred)

## 애니메이션이 종료되면 호출됩니다.
func _on_animation_finished(animation_name: StringName) -> void:
	if is_queued_for_deletion():
		return

	if animation_name == ANIMATION_ATTACK:
		_finish_attack()

## 게임 오버를 처리합니다.
func _on_game_over() -> void:
	if not is_physics_processing():
		return
	
	set_physics_process(false)
		
	if run_dust_particles:
		run_dust_particles.emitting = false
	
	if spin_gold_statue:
		spin_gold_statue.play()
		spin_gold_statue.show()

	_play_death_animation()