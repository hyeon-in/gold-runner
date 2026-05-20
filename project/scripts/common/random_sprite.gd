## 무작위로 스프라이트를 설정합니다.
extends Sprite2D

## 스프라이트를 나누는 기준이 되는 각 프레임의 크기입니다.
## 홀수이면 픽셀 밀림이 발생하니 반드시 짝수로 설정해주세요.
@export var frame_size: Vector2i = Vector2i(32, 32)

var _total_frames: int
var _is_ready: bool = false

func _ready() -> void:
	if not texture:
		return
	
	var texture_size := texture.get_size()

	hframes = floori(texture_size.x / frame_size.x)
	vframes = floori(texture_size.y / frame_size.y)

	_total_frames = hframes * vframes
	_is_ready = true
	
	_set_random_sprite()

func _notification(what: int) -> void:
	if not _is_ready:
		return

	if what == NOTIFICATION_VISIBILITY_CHANGED:
		# 화면에 보여지는 상태가 변하면 스프라이트를 무작위로 재설정합니다.
		if is_visible_in_tree():
			_set_random_sprite()

## 모든 프레임 중에 무작위 하나를 현재 프레임으로 설정합니다.
func _set_random_sprite() -> void:
	if _total_frames > 0:
		frame = randi() % _total_frames