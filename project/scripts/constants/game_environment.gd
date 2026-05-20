## 게임 환경의 물리적 설정값을 관리합니다.
class_name GameEnvironment

## 경사면의 기울기 (도 단위)
const SLOPE_ANGLE: float = 15.0
## 경사면의 하향 방향 벡터
static var DOWNHILL_DIRECTION : Vector2 = Vector2.RIGHT.rotated(deg_to_rad(SLOPE_ANGLE)).normalized()