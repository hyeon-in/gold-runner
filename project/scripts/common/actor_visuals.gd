## 게임 상의 Actor의 비주얼 관련 이펙트를 처리합니다.
class_name ActorVisuals
extends Sprite2D

const OVERLAY_COLOR: StringName = &"overlay_color"

var _init_scale:Vector2
var _squash_and_stretch_tween:Tween = null

@export var color_overlay_material: Material = null

var _blink_tween:Tween

func _ready() -> void:
	if DebugValidator.validate(self, color_overlay_material, "color_overlay_material"):
		material = color_overlay_material

	_init_scale = scale

## 스쿼드 앤 스트래치 애니메이션을 처리합니다.
func apply_squash_and_stretch(strength: Vector2, duration: float, transition_type: Tween.TransitionType = Tween.TRANS_QUAD) -> void:
	if _squash_and_stretch_tween:
		_squash_and_stretch_tween.kill()

	# 찌그러뜨리기
	scale = strength
	
	# 트윈으로 scale 복구
	_squash_and_stretch_tween = create_tween().set_trans(transition_type).set_ease(Tween.EASE_OUT)
	_squash_and_stretch_tween.tween_property(self, "scale", _init_scale, duration)

## 블링크 이펙트 실행합니다.
func apply_blink_effect(color:Color, duration: float, blink_count: int) -> void:
	if not material:
		return

	stop_blink_effect()

	_blink_tween = create_tween()
	var step_duration := duration / (blink_count * 2.0)

	for i in blink_count:
		# 색 적용
		_blink_tween.tween_callback(func() -> void: set_instance_shader_parameter(OVERLAY_COLOR, color))
		_blink_tween.tween_interval(step_duration)

		# 투명화
		_blink_tween.tween_callback(func() -> void: set_instance_shader_parameter(OVERLAY_COLOR, Color.TRANSPARENT))
		_blink_tween.tween_interval(step_duration)

## 블링크 이펙트를 중단합니다.
func stop_blink_effect() -> void:
	if _blink_tween:
		_blink_tween.kill()
		_blink_tween = null

		if material:
			set_instance_shader_parameter(OVERLAY_COLOR, Color.TRANSPARENT)
