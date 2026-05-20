## AudioManager.gd (Autoload)
## 사운드 재생 및 설정을 관리하는 싱글톤입니다.
extends Node

const DEFAULT_SFX_PLAYER_COUNT: int = 8

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _sfx_id_counter: int = 0

func _ready() -> void:
	# 게임 내내 사운드 재생이 끊기지 않도록 방지
	process_mode = Node.PROCESS_MODE_ALWAYS

	# BGM 플레이어 초기화
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	add_child(bgm_player)

	# SFX 플레이어 초기화
	for i in range(DEFAULT_SFX_PLAYER_COUNT):
		sfx_players.append(_create_new_sfx_player())

## BGM을 재생합니다.
func play_bgm(bgm: AudioStream) -> void:
	if not bgm:
		return
	
	# 같은 음악을 재생하려고 할 경우 무시
	if bgm_player.stream == bgm and bgm_player.playing:
		return
	
	bgm_player.stream = bgm
	bgm_player.play()

## 현재 BGM 재생을 중단합니다.
func stop_bgm() -> void:
	bgm_player.stop()
	bgm_player.stream = null

## SFW를 재생합니다.
func play_sfx(sfx: AudioStream, volume: float = 1.0) -> void:
	if not sfx:
		return
	
	## 활성화 된 SFX 플레이어를 가져옴
	var available_player := _get_available_sfx_player()

	available_player.volume_db = linear_to_db(max(volume, 0.001)) 
	available_player.stream = sfx
	available_player.play()

## 사용 가능한 SFX 플레이어를 반환합니다.
func _get_available_sfx_player() -> AudioStreamPlayer:
	# SFX 플레이어가 풀에 있으면 가져오고 아니면 새로 생성
	if not sfx_players.is_empty():
		return sfx_players.pop_back()
	
	return _create_new_sfx_player()

## 새로운 SFX 플레이어를 생성하고 반환합니다.
func _create_new_sfx_player() -> AudioStreamPlayer:
	_sfx_id_counter += 1
	var new_player := AudioStreamPlayer.new()
	new_player.name = "SFXPlayer_" + str(_sfx_id_counter)
	add_child(new_player)

	# 재생 종료된 SFX 플레이어를 풀에 반환
	new_player.finished.connect(_on_sfx_finished.bind(new_player))

	return new_player

## 효과음 재생이 종료되면 풀로 되돌립니다.
func _on_sfx_finished(sfx_player: AudioStreamPlayer) -> void:
	if not sfx_players.has(sfx_player):
		sfx_players.append(sfx_player)