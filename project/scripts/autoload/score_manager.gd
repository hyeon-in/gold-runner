## ScoreManager.gd (Autoload)
## 게임의 점수를 관리하는 싱글톤입니다.
extends Node

const SAVE_PATH := "user://save_data.cfg"
const SECTION_NAME := "Progress"
const KEY_NAME := "high_score"

# 연산용 거리
var _distance_mm: int = 0
# 실제 게임 점수 및 최고 점수
var current_score: int = 0
var high_score: int = 0

func _ready() -> void:
	load_high_score()
	set_physics_process(false)
	GameEvents.game_start.connect(_on_game_start)
	GameEvents.game_over.connect(_on_game_over)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			# 게임이 정지되거나 종료되면 하이스코어 저장을 실행합니다.
			save_high_score()

func _physics_process(_delta: float) -> void:
	var speed_mps: float = GameSpeedManager.current_speed * GameSpeedManager.KMH_TO_MPS
	_distance_mm += int(speed_mps * 1000.0 / GameSpeedManager.PHYSICS_FPS)

	var new_score: int = int(_distance_mm / 1000.0)
	if new_score > current_score:
		current_score = new_score
		GameEvents.current_score_changed.emit(current_score)

		# 실시간 최고 점수 체크 및 동기화
		if current_score > high_score:
			high_score = current_score
			GameEvents.high_score_changed.emit(high_score)

## 데이터를 파일에 저장합니다.
func save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION_NAME, KEY_NAME, high_score)
	config.save(SAVE_PATH)

## 파일에서 데이터를 읽어옵니다.
func load_high_score() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == OK:
		high_score = config.get_value(SECTION_NAME, KEY_NAME, 0)
		GameEvents.high_score_changed.emit(high_score)

## 게임을 시작할 때 필요한 설정을 초기화합니다.
func _on_game_start() -> void:
	_distance_mm = 0
	current_score = 0
	GameEvents.current_score_changed.emit(0)
	set_physics_process(true)

## 게임 오버가 되면 프로세스를 중단하고 하이 스코어를 저장합니다.
func _on_game_over() -> void:
	set_physics_process(false)
	save_high_score()