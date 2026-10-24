// Versão leve do vidro (sem ler a tela): para computadores fracos.
shader_type canvas_item;

uniform vec2 size = vec2(300.0, 100.0);
uniform float margin = 24.0;
uniform float radius = 24.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.10);
uniform float glow = 0.0;
uniform vec4 glow_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform float shadow = 0.35;
uniform float sheen = 1.0;
uniform float blur = 0.0;
uniform float refraction = 0.0;

float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 full = size + vec2(margin * 2.0);
	vec2 p = (UV - 0.5) * full;
	vec2 hb = size * 0.5;
	float r = min(radius, min(hb.x, hb.y));
	float d = sd_box(p, hb, r);
	float inside = 1.0 - smoothstep(-1.0, 1.0, d);
	float ds = sd_box(p - vec2(0.0, 6.0), hb, r);
	float sh = (1.0 - smoothstep(-4.0, 22.0, ds)) * shadow;
	float gl = (1.0 - smoothstep(0.0, margin, d)) * glow;
	vec4 outside = mix(vec4(0.0, 0.0, 0.0, sh), vec4(glow_color.rgb, gl * 0.85), clamp(gl * 1.2, 0.0, 1.0));
	vec3 base = mix(vec3(0.07, 0.06, 0.14), tint.rgb, clamp(tint.a * 1.6, 0.0, 1.0));
	float top = 1.0 - UV.y;
	base += vec3(0.10) * sheen * smoothstep(0.35, 1.0, top);
	float rim = smoothstep(-3.0, -0.5, d);
	base += vec3(0.35) * rim * sheen * smoothstep(0.3, 0.9, top);
	base += glow_color.rgb * glow * 0.15;
	vec4 inner = vec4(base, 0.78);
	COLOR = mix(outside, inner, inside) * COLOR;
}
