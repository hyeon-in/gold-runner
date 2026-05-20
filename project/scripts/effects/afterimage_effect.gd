## 잔상 이펙트를 Rendering Server 기반으로 처리하는 클래스입니다.
class_name AfterimageEffects
extends Node2D

const PARAM_OVERLAY_COLOR:StringName = &"overlay_color"	# 오버레이 컬러의 색상 파라미터

class Afterimage:
	var rid: RID
	var transform: Transform2D
	var duration: float
	var timer: float

	func _init(p_rid: RID) -> void:
		rid = p_rid

@export var color_overlay_material: Material
@export var afterimage_effect_color := Color8(0, 86, 103, 100)
@export_range(1,100) var _initial_pool_size: int = 10 # 기본으로 생성하는 잔상 개수
@export_range(1,100) var _max_pool_size: int = 50 	  # 생성할 수 있는 최대 잔상 개수

var _idle_pool: Array[Afterimage] = []		# 대기 중인 풀
var _active_pool: Array[Afterimage] = []	# 사용 중인 풀
var _pool_count:int = 0						# 현재 풀의 개수

func _ready() -> void:
	if not DebugValidator.validate(self, color_overlay_material, "color_overlay_material"):
		set_physics_process(false)
		return

	top_level = true

	# 초기에 필요한 풀을 미리 생성
	_initial_pool_size = min(_initial_pool_size, _max_pool_size)
	for i in range(_initial_pool_size):
		_create_new_effect()

	set_physics_process(false)

func _notification(what: int) -> void:
	# 노드 제거 시 RID 일괄 삭제
	if what == NOTIFICATION_PREDELETE:
		for effect in _idle_pool:
			RenderingServer.free_rid(effect.rid)
		for effect in _active_pool:
			RenderingServer.free_rid(effect.rid)

func _physics_process(delta: float) -> void:
	# 실시간으로 이펙트의 상태를 업데이트
	var i:int = _active_pool.size() - 1
	while i >= 0:
		var effect := _active_pool[i]
		effect.timer -= delta

		if effect.timer <= 0:
			_deactivate_at(i)
		else:
			effect.transform.origin -= GameEnvironment.DOWNHILL_DIRECTION * GameSpeedManager.current_speed * GameSpeedManager.PIXELS_PER_METER * delta
			RenderingServer.canvas_item_set_transform(effect.rid, effect.transform)
		i -= 1

## Sprite2D의 현재 상태를 복제하여 잔상을 생성합니다.
func emit(sprite: Sprite2D, duration: float) -> void:
	if not color_overlay_material:
		return
	
	if not sprite or not sprite.texture:
		return

	# 활성화 된 이펙트를 가져오고 모든 이펙트가 활성화 된 상태이면 실행 취소
	var effect := _get_available_effect()
	if not effect:
		return

	# 텍스처 RID 가져오기
	var texture_rid := sprite.texture.get_rid()
	var frame_size := Vector2(
		float(sprite.texture.get_width()) / sprite.hframes,
		float(sprite.texture.get_height()) / sprite.vframes
	)

	var target_rect := sprite.get_rect()

	# Region 계산
	var src_rect := Rect2(
		(sprite.frame % sprite.hframes) * frame_size.x,
		floori(float(sprite.frame) / sprite.hframes) * frame_size.y,
		frame_size.x,
		frame_size.y
	)
	
	RenderingServer.canvas_item_clear(effect.rid)
	RenderingServer.canvas_item_add_texture_rect_region(effect.rid, target_rect, texture_rid, src_rect)

	var final_transform := sprite.global_transform
	if sprite.flip_h:
		final_transform = final_transform.scaled_local(Vector2(-1, 1))
	if sprite.flip_v:
		final_transform = final_transform.scaled_local(Vector2(1, -1))

	## effect 값 설정
	effect.transform = final_transform
	effect.duration = duration
	effect.timer = duration

	# 캔버스 아이템 보이게 설정
	RenderingServer.canvas_item_set_transform(effect.rid, effect.transform)
	RenderingServer.canvas_item_set_visible(effect.rid, true)

	# 풀에 할당
	_active_pool.append(effect)

	# physics_process가 비활성화된 상태이면 활성화
	if not is_physics_processing():
		set_physics_process(true)

## 모든 잔상 이펙트를 대기 상태로 전환합니다.
func clear_all() -> void:
	for i in range(_active_pool.size() - 1, -1, -1):
		_deactivate_at(i)

## 활성화 된 이펙트를 가져옵니다.
## 만약 활성화 된 이펙트가 없다면 풀의 수를 체크한 후, 최대 수량에 도달하지 않았다면 새롭게 생성하여 가져옵니다.
func _get_available_effect() -> Afterimage:
	if _idle_pool.is_empty():
		if _pool_count < _max_pool_size:
			_create_new_effect()
		else:
			return null
	return _idle_pool.pop_back()

## RenderingServer에 잔상 이펙트로 사용할 캔버스 아이템을 생성하고 풀에 추가합니다.
func _create_new_effect() -> void:
	var canvas_item_rid := RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(canvas_item_rid, get_canvas_item())
	RenderingServer.canvas_item_set_material(canvas_item_rid, color_overlay_material.get_rid())
	RenderingServer.canvas_item_set_visible(canvas_item_rid, false)
	RenderingServer.canvas_item_set_interpolated(canvas_item_rid, false)
	RenderingServer.canvas_item_set_instance_shader_parameter(canvas_item_rid, PARAM_OVERLAY_COLOR, afterimage_effect_color)
	RenderingServer.canvas_item_set_z_index(canvas_item_rid, -1)

	_idle_pool.append(Afterimage.new(canvas_item_rid))
	_pool_count += 1

func _deactivate_at(index: int) -> void:
	var effect := _active_pool[index]
	RenderingServer.canvas_item_set_visible(effect.rid, false)
	
	# 마지막 요소랑 자리를 바꿔서 제거(O(1) 유지를 위함)
	var last_index:int = _active_pool.size() - 1
	if index != last_index:
		_active_pool[index] = _active_pool[last_index]
	_active_pool.pop_back()

	_idle_pool.append(effect)

	# 활성화 된 풀이 없을 경우 사용하지 않는 상태로 전환
	if _active_pool.is_empty():
		set_physics_process(false)
