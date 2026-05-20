## 프로젝트의 안정성을 위해 노드 및 리소스의 유효성을 검사하는 유틸리티 클래스입니다.
class_name DebugValidator

## 특정 대상이 null인지 확인하고 로그를 남깁니다.
static func validate(owner: Node, target: Variant, target_name: String, is_critical: bool = true) -> bool:
	if target:
		return true

	var message := "[%s] '%s'가(이) 할당되지 않았습니다!" % [owner.name, target_name]
	if is_critical:
		if OS.is_debug_build():
			push_error("CRITICAL ERROR: " + message)
			# 디버그 환경에서는 강제 중단
			breakpoint 
		else:
			# 상용 빌드에서는 게임이 꺼지지 않도록 경고 로그만 남김
			push_warning("RELEASE WARNING (CRITICAL BYPASSED): " + message)
		return false
	else:
		push_warning("WARNING: " + message)
		return true

## 복수의 대상을 null인지 확인하고 로그를 남깁니다.
static func validate_batch(owner: Node, targets: Dictionary[Variant, String], is_critical: bool = true) -> bool:
	var all_passed: bool = true
	
	var target_names: Array = targets.values()
	var target_nodes: Array = targets.keys()
	
	for i in range(target_names.size()):
		var node: Variant = target_nodes[i]
		var node_name: String = str(target_names[i])

		if not validate(owner, node, node_name, is_critical):
			all_passed = false

	return all_passed
