## GameEvents.gd (Autoload)
## 게임 내 이벤트를 중계하는 글로벌 이벤트 버스입니다.
extends Node

## 게임 시작 시 발생하는 시그널
@warning_ignore("unused_signal")
signal game_start
## 게임 오버 시 발생하는 시그널
@warning_ignore("unused_signal")
signal game_over

## 현재 점수가 변하면 발생하는 시그널
@warning_ignore("unused_signal")
signal current_score_changed(score: int)
## 최고 점수가 변하면 발생하는 시그널
@warning_ignore("unused_signal")
signal high_score_changed(score: int)
## 속도가 업데이트되면 발생하는 시그널
@warning_ignore("unused_signal")
signal speed_updated(speed: float)

## 바위 마커의 글로벌 X 좌표가 변경되면 발생하는 시그널
@warning_ignore("unused_signal")
signal rock_marker_x_changed(position_x: float)
## 오크통 경고 시작
@warning_ignore("unused_signal")
signal oak_cask_warning_started
## 오크통 경고 종료
@warning_ignore("unused_signal")
signal oak_cask_warning_finished
## 유령 경고 시작
@warning_ignore("unused_signal")
signal ghost_warning_started
## 유령 경고 종료
@warning_ignore("unused_signal")
signal ghost_warning_finished