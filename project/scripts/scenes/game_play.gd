## 게임 플레이 씬의 초기화 및 BGM 재생을 처리합니다.
extends Node2D

@export var _bgm:AudioStream 

func _ready() -> void:
	GameEvents.game_start.emit()
	if _bgm:
		AudioManager.play_bgm(_bgm)