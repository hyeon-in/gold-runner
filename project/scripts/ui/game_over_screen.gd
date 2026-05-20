## 게임 오버 화면을 제어하고 처리합니다.
extends Control

const ACTION_CONFIRM := &"confirm"

func _ready() -> void:
	hide()
	GameEvents.game_over.connect(_on_game_over)
	set_process_unhandled_input(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_CONFIRM) and not event.is_echo():
		set_process_unhandled_input(false)
		
		# 현재 씬을 다시 불러서 게임 재시작
		SceneChanger.change_scene(get_tree().current_scene.scene_file_path)

## 게임 오버 이후 프레임 프리즈 연출이 끝나면 화면을 표시합니다.
func _on_game_over() -> void:
	await FrameFreeze.wait_until_finished()

	if not is_inside_tree():
		return

	show()
	set_process_unhandled_input(true)