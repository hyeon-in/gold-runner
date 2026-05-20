## SceneChanger.gd (Autoload)
## 게임의 씬 전환을 처리하는 싱글톤입니다.
extends CanvasLayer

const PROGRESS = &"progress"

@export var fade_color_rect: ColorRect
@export var fade_material: ShaderMaterial

var is_transitioning := false

func _ready() -> void:
	if not DebugValidator.validate_batch(self,{
		fade_color_rect : "fade_color_rect",
		fade_material : "fade_material"
	}):
		return

	process_mode = Node.PROCESS_MODE_ALWAYS

	fade_color_rect.material = fade_material
	layer = 100

	_set_fade_progress(0.0)

## 게임 씬을 다른 씬으로 전환합니다.
func change_scene(target_scene_path: String, duration: float = 1.0) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true

	# 페이드 아웃 실행
	var tween_out := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_out.tween_method(_set_fade_progress, 0.0, 0.5, duration)
	await tween_out.finished

	# 씬 교체 
	var err := get_tree().change_scene_to_file(target_scene_path)

	# 씬 교체 실패 시 예외 처리
	if err != OK:
		push_error("씬 전환 실패: %s" % target_scene_path)
		# 페이드 롤백
		var tween_rollback := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween_rollback.tween_method(_set_fade_progress, 0.5, 1.0, duration)
		await tween_rollback.finished
		is_transitioning = false
		return
	
	# 씬 로드 후 미세한 대기 
	await get_tree().create_timer(0.05).timeout

	# 페이드 인 실행
	var tween_in := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_method(_set_fade_progress, 0.5, 1.0, duration)
	await tween_in.finished

	_set_fade_progress(0.0)
	is_transitioning = false

## 셰이더의 progress 파라미터 값을 설정할 때 사용합니다.
func _set_fade_progress(value: float) -> void:
	fade_material.set_shader_parameter(PROGRESS, value)