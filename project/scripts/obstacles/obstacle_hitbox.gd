## 게임 상의 모든 장애물들의 히트박스를 처리합니다.
class_name ObstacleHitbox
extends Area2D

## 장애물 타입 정의
enum Type { OBSTACLE, ROCK, DESTRUCTIBLE }

const OBSTACLE_HIT_FRAME_FREEZE_DURATION: float = 0.075
const OBSTACLE_SHAKE_TRAUMA: float = 0.6
const OBSTACLE_SHAKE_DURATION: float = 0.35

const ROCK_HIT_FRAME_FREEZE_DURATION: float = 0.03
const ROCK_SHAKE_TRAUMA: float = 0.3
const ROCK_SHAKE_DURATION: float = 0.25

const DESTRUCTIBLE_SHAKE_TRAUMA: float = 0.1
const DESTRUCTIBLE_SHAKE_DURATION: float = 0.15

signal hurt

@export var type: Type = Type.OBSTACLE
@export var hit_sound: AudioStream
@export var hit_effect_scene: PackedScene

var rock_hit_effect_radius: float = 0.0
var _camera: CameraController

func _ready() -> void:
	var camera_node := get_viewport().get_camera_2d() as CameraController
	if camera_node:
		_camera = camera_node
	
	collision_layer = PhysicsLayers.OBSTACLE
	collision_mask = PhysicsLayers.PLAYER_BODY
	if type == Type.ROCK:
		# 바위는 다른 장애물과도 충돌하여 파괴 처리 가능
		collision_mask |= PhysicsLayers.OBSTACLE
		for child in get_children():
			var collision_node := child as CollisionShape2D
			if collision_node and collision_node.shape is CircleShape2D:
				# 바위 충돌 시 피격 이펙트를 표면 위치에 생성하기 위해 반지름 저장
				rock_hit_effect_radius = collision_node.shape.radius
	
	area_entered.connect(_on_area_entered)

## 플레이어 등에게 공격 받은 상황의 연출 및 신호 전달을 처리합니다.
func apply_hit(other_area: Area2D) -> void:
	# 연출 적용
	match type:
		Type.OBSTACLE:
			FrameFreeze.freeze(OBSTACLE_HIT_FRAME_FREEZE_DURATION)
			_apply_camera_shake(OBSTACLE_SHAKE_TRAUMA, OBSTACLE_SHAKE_DURATION)
		Type.ROCK:
			FrameFreeze.freeze(ROCK_HIT_FRAME_FREEZE_DURATION)
			_apply_camera_shake(ROCK_SHAKE_TRAUMA, ROCK_SHAKE_DURATION)
		Type.DESTRUCTIBLE:
			_apply_camera_shake(DESTRUCTIBLE_SHAKE_TRAUMA, DESTRUCTIBLE_SHAKE_DURATION)
	
	# 사운드 및 이펙트 처리
	if hit_sound:
		AudioManager.play_sfx(hit_sound)
	_spawn_hit_effect(other_area.global_position)

	hurt.emit()

func _apply_camera_shake(trauma: float, duration: float) -> void:
	if is_instance_valid(_camera):
		_camera.apply_shake(trauma, duration)

## 타격 이펙트 스폰을 처리합니다.
func _spawn_hit_effect(other_position: Vector2) -> void:
	if not hit_effect_scene:
		return

	var spawn_position := global_position

	# 바위는 타격 이펙트를 충돌한 외곽 표면에 생성합니다.
	if type == Type.ROCK and rock_hit_effect_radius > 0:
		var direction := (other_position- global_position).normalized()
		spawn_position = global_position + (direction * rock_hit_effect_radius)
	
	# 장애물이 비활성화되어도 이펙트가 유지되도록 현재 씬에 추가
	var effect := hit_effect_scene.instantiate()
	if effect:
		effect.global_position = spawn_position
		get_tree().current_scene.add_child(effect)

## 다른 Area에 접촉했을 경우를 처리합니다.
func _on_area_entered(other_area: Area2D) -> void:
	if other_area.collision_layer & PhysicsLayers.PLAYER_BODY:
		var player_body := other_area as PlayerBodyArea
		if player_body:
			match type:
				Type.OBSTACLE:
					player_body.take_damage()
				Type.ROCK:
					player_body.crush()
				Type.DESTRUCTIBLE:
					apply_hit(player_body)
	elif other_area.collision_layer & PhysicsLayers.OBSTACLE:
		var obstacle_hitbox := other_area as ObstacleHitbox
		if obstacle_hitbox:
			obstacle_hitbox.apply_hit(self)