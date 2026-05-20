shader_type canvas_item;

// 0.5를 기준으로 화면 덮기/지우기 전환
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// 화면을 몇 개의 다이아몬드 격자로 나눌지 설정(X, Y)
uniform vec2 diamond_count = vec2(40.0, 30.0);
// 화면을 덮을 다이아몬드의 색상
uniform vec4 transition_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// 현재 픽셀 위치(UV)를 기준으로 격자 내의 로컬 좌표 계산
    vec2 cell_uv = fract(UV * diamond_count);

	// 격자 중심으로부터의 맨해튼 거리를 구해 마름모 모양 생성
    float diamond = abs(cell_uv.x - 0.5) + abs(cell_uv.y - 0.5);
    diamond *= 2.0;
	
	// 화면 왼쪽에서 오른쪽으로 진행하는 기준값 생성
    float wipe = UV.x;
	// mix를 사용하여 다이아몬드 형태에 따라 부드럽게 섞이도록 설정
	float threshold = mix(wipe, 1.0, diamond * 0.15);

    float alpha;
    if (progress < 0.5) {
		// 페이드 아웃(0.0 ~ 0.5)
        float p = progress * 2.0;
        alpha = 1.0 - step(threshold, p);
    }
    else {
		// 페이드 인(0.5 ~ 1.0)
        float p = (progress - 0.5) * 2.0;
        alpha = step(threshold, p);
    }
	
	// 최종 색상 적용
    COLOR = transition_color;
    COLOR.a = 1.0 - alpha;
}