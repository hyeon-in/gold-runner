## 카메라의 흔들림 효과를 처리합니다.
class_name CameraController
extends Camera2D

const NOISE_SPEED: float = 40.0
const MAX_OFFSET: Vector2 = Vector2(32, 18)

var _shake_intensity: float = 0.0
var _shake_decay: float = 0.0
var _noise_offset: float = 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.5
	make_current()
	set_process(false)

func _process(delta: float) -> void:
	_update_shake(delta)

## 카메라 흔들기를 실행합니다.
func apply_shake(trauma: float, duration: float) -> void:
	if trauma <= 0 or duration <= 0.0:
		return
	
	_shake_intensity = clamp(max(_shake_intensity, trauma), 0.0, 1.0)
	_shake_decay = _shake_intensity / duration
	set_process(true)

## 외부에서 카메라 흔들기를 요청했을 때 이를 처리합니다.
func _update_shake(delta: float) -> void:
	if _shake_intensity > 0.0:
		_noise_offset += delta * NOISE_SPEED

		var offset_x := _noise.get_noise_1d(_noise_offset) * _shake_intensity * MAX_OFFSET.x
		var offset_y := _noise.get_noise_1d(_noise_offset + 5000.0) * _shake_intensity * MAX_OFFSET.y
		offset = Vector2(offset_x, offset_y)

		_shake_intensity = max(_shake_intensity - _shake_decay * delta, 0.0)
	else:
		offset = Vector2.ZERO
		_noise_offset = 0.0
		set_process(false)
