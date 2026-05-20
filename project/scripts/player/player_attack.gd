# 플레이어의 공격을 처리합니다.
extends Area2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.OBSTACLE

	area_entered.connect(_on_area_entered)

func _on_area_entered(target_area: Area2D) -> void:
	var hurtbox := target_area as ObstacleHitbox
	if hurtbox:
		hurtbox.apply_hit(self)
