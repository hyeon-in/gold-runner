## 일회용 애니메이티드 스프라이트 이펙트를 처리합니다.
extends AnimatedSprite2D

func _ready() -> void:
	# 애니메이션 데이터가 존재하지 않으면 즉시 해제
	if not sprite_frames or not sprite_frames.has_animation(animation):
		queue_free()
		return

	sprite_frames.set_animation_loop(animation, false)
	animation_finished.connect(_on_animation_finished)

	play()

## 애니메이션이 종료되면 노드를 해제합니다.
func _on_animation_finished() -> void:
	queue_free.call_deferred()