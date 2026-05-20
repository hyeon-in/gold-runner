## 현재 점수를 텍스트로 표시합니다.
extends Label

func _ready() -> void:
	_update_score_text(ScoreManager.current_score)
	GameEvents.current_score_changed.connect(_update_score_text)

func _update_score_text(score: int) -> void:
	text = "%dm" % score