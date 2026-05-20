## 최고 점수를 텍스트로 표시합니다.
extends Label

func _ready() -> void:
	_update_high_score_text(ScoreManager.high_score)
	GameEvents.high_score_changed.connect(_update_high_score_text)

func _update_high_score_text(score: int) -> void:
	text = "HI %dm" % score