## 타이틀 화면에서 인트로 재생 및 게임 플레이 씬으로 이동하는 기능을 처리합니다.
extends Node2D

const ANIMATION_INTRO = &"intro"
const ACTION_CONFIRM := &"confirm"

const SCREEN_SHAKE_TRAUMA: float = 0.5
const SCREEN_SHAKE_DURATION: float = 0.5

@export var animation_player: AnimationPlayer
@export var rock_landing_sound: AudioStream
@export_file("*.tscn") var game_play_scene_path: String

func _ready() -> void:
	if not DebugValidator.validate(self, animation_player, "animation_player"):
		set_process_unhandled_input(false)
		return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_CONFIRM) and not event.is_echo():
		set_process_unhandled_input(false)
		animation_player.play(ANIMATION_INTRO)

## 애니메이션 내에서 바위가 추락할 때 사운드를 재생합니다.
func play_rock_landing_sound() -> void:
	if rock_landing_sound:
		AudioManager.play_sfx(rock_landing_sound)

## 애니메이션 내에서 카메라 흔들기를 처리합니다.
func screen_shake() -> void:
	var camera := get_viewport().get_camera_2d() as CameraController
	if camera:
		camera.apply_shake(SCREEN_SHAKE_TRAUMA, SCREEN_SHAKE_DURATION)

## 애니메이션 내에서 게임 플레이 씬으로 전환을 처리합니다.
func change_to_game_play_scene() -> void:
	if game_play_scene_path.is_empty():
		push_warning("이동할 씬 경로(game_play_scene_path)가 설정되지 않았습니다.")
		return
	
	SceneChanger.change_scene(game_play_scene_path)