## 플레이어가 장애물에 충돌하는 기능 및 효과를 처리합니다.
class_name PlayerBodyArea
extends Area2D

const BLINK_COUNT: int = 4
const HURT_FRAME_FREEZE_DURATION: float = 0.2
const HURT_SCREEN_SHAKE_TRAUMA: float = 0.5
const HURT_SCREEN_SHAKE_DURATION: float = 0.5
const DEATH_FRAME_FREEZE_DURATION: float = 0.75

@export var invincibility_duration: float = 1.5
@export var visuals: ActorVisuals
@export var hurt_sound: AudioStream
@export var death_sound: AudioStream

var _camera: CameraController
var _invincible_timer: float = 0.0

var is_invincible: bool:
	get: return _invincible_timer > 0.0

func _ready() -> void:
	_camera = get_viewport().get_camera_2d() as CameraController

	collision_layer = PhysicsLayers.PLAYER_BODY
	collision_mask = PhysicsLayers.OBSTACLE

	## 무적 시간 처리만 process 활성화
	set_process(false)

func _process(delta: float) -> void:
	_invincible_timer -= delta
	if _invincible_timer <= 0.0:
		_end_invincibility()

## 일반적인 장애물 충돌을 처리합니다. (속도 감속 처리)
func take_damage() -> void:
	if is_invincible:
		return

	_start_invincibility()
	
	FrameFreeze.freeze(HURT_FRAME_FREEZE_DURATION)
	_camera.apply_shake(HURT_SCREEN_SHAKE_TRAUMA, HURT_SCREEN_SHAKE_DURATION)
	_play_sfx(hurt_sound)

	# GameSpeedManager에서 캐릭터 속도 감소 처리
	GameSpeedManager.collision_obstacle()

## 치명적인 장애물 충돌을 처리합니다. (게임 오버 처리)
func crush() -> void:
	set_process(false)
	
	if visuals:
		visuals.stop_blink_effect()

	# 게임 오버 이후 추가 충돌이 발생하지 않도록 완전히 비활성화
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0

	AudioManager.stop_bgm()

	FrameFreeze.freeze(DEATH_FRAME_FREEZE_DURATION)
	_apply_camera_shake(HURT_SCREEN_SHAKE_TRAUMA, HURT_SCREEN_SHAKE_DURATION)
	_play_sfx(hurt_sound)

	GameEvents.game_over.emit()

	await FrameFreeze.wait_until_finished()
	_play_sfx(death_sound, 0.6)

## 카메라 흔들림 연출을 적용합니다.
func _apply_camera_shake(trauma: float, duration: float) -> void:
	if is_instance_valid(_camera):
		_camera.apply_shake(trauma, duration)

## 효과음을 재생합니다.
func _play_sfx(sfx: AudioStream, volume: float = 1.0) -> void:
	if sfx:
		AudioManager.play_sfx(sfx, volume)

## 피격 시 무적 상태 및 시각 효과를 실행합니다.
func _start_invincibility() -> void:
	_invincible_timer = invincibility_duration
	set_deferred("monitoring", false)
	if visuals:
		visuals.apply_blink_effect(Color.WHITE, invincibility_duration, BLINK_COUNT)
	set_process(true)
		

## 무적 시간 종료 및 충돌 처리를 복구합니다.
func _end_invincibility() -> void:
	set_process(false)
	set_deferred("monitoring", true)