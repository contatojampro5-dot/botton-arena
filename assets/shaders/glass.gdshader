// Vidro líquido (estilo "Liquid Glass"): desfoque do fundo, refração na borda,
// leve dispersão de cor, brilho especular e sombra suave.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 size = vec2(300.0, 100.0);      // tamanho do painel em pixels
uniform float margin = 24.0;                  // área extra para a sombra/brilho
uniform float radius = 24.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.10);
uniform float blur = 3.2;                     // nível de mipmap do desfoque
uniform float refraction = 14.0;              // pixels de deslocamento na borda
uniform float glow = 0.0;                     // brilho externo (seleção)
uniform vec4 glow_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform float shadow = 0.35;
uniform float sheen = 1.0;

float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec2 sd_grad(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	vec2 g;
	if (q.x > 0.0 && q.y > 0.0) g = normalize(q);
	else if (q.x > q.y) g = vec2(1.0, 0.0);
	else g = vec2(0.0, 1.0);
	return g * sign(p + 0.0001);
}

void fragment() {
	vec2 full = size + vec2(margin * 2.0);
	vec2 p = (UV - 0.5) * full;
	vec2 hb = size * 0.5;
	float r = min(radius, min(hb.x, hb.y));
	float d = sd_box(p, hb, r);
	float aa = 1.0;
	float inside = 1.0 - smoothstep(-aa, aa, d);

	// sombra suave deslocada para baixo
	float ds = sd_box(p - vec2(0.0, 6.0), hb, r);
	float sh = (1.0 - smoothstep(-4.0, 22.0, ds)) * shadow;
	// brilho externo
	float gl = (1.0 - smoothstep(0.0, margin, d)) * glow;
	vec4 outside = vec4(glow_color.rgb, gl * 0.85);
	outside = mix(vec4(0.0, 0.0, 0.0, sh), outside, clamp(gl * 1.2, 0.0, 1.0));

	// dentro do vidro
	vec2 g = sd_grad(p, hb, r);
	float edge = clamp(1.0 + d / max(r, 8.0), 0.0, 1.0);    // 1 na borda, 0 no meio
	float bend = edge * edge * edge;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 off = -g * refraction * bend * px;
	vec2 suv = SCREEN_UV + off;
	vec3 col;
	col.r = textureLod(screen_tex, suv + off * 0.35, blur).r;
	col.g = textureLod(screen_tex, suv, blur).g;
	col.b = textureLod(screen_tex, suv - off * 0.35, blur).b;
	// vibração: um pouco mais de saturação e brilho
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, 1.25) * 1.05;
	col = mix(col, tint.rgb, tint.a);
	// brilho superior (luz vindo de cima à esquerda)
	float top = 1.0 - UV.y;
	col += vec3(0.10) * sheen * smoothstep(0.35, 1.0, top);
	vec2 luz = normalize(vec2(-0.55, -0.85));
	float rim = smoothstep(-3.5, -0.5, d);
	float spec = rim * pow(max(dot(g, luz), 0.0), 2.0);
	float spec2 = rim * pow(max(dot(g, -luz), 0.0), 3.0) * 0.35;
	col += vec3(0.85) * spec * sheen + vec3(0.5) * spec2 * sheen;
	// borda interna clarinha + brilho da seleção dentro
	col += glow_color.rgb * glow * 0.12 * (0.4 + edge);
	col = mix(col, col * 0.85, smoothstep(0.6, 1.0, UV.y) * 0.4);

	vec4 inner = vec4(col, 1.0);
	COLOR = mix(outside, inner, inside) * COLOR;
}
