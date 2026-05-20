## 장애물 경고 UI의 표시 상태를 제어합니다.
extends Control

@export var ghost_warning: Control
@export var oak_cask_warning: Control

func _ready() -> void:
	_bind_warning_visibility(ghost_warning, GameEvents.ghost_warning_started, GameEvents.ghost_warning_finished)
	_bind_warning_visibility(oak_cask_warning, GameEvents.oak_cask_warning_started, GameEvents.oak_cask_warning_finished)

## 경고 UI와 이벤트를 연결합니다.
func _bind_warning_visibility(warning_ui: Control, started_signal: Signal, finished_signal: Signal) -> void:
	if not warning_ui:
		return
	
	started_signal.connect(warning_ui.show)
	finished_signal.connect(warning_ui.hide)
	
	warning_ui.hide()