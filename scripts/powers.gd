extends RefCounted
## PODERES — os 4 poderes de cada botton (estilo Pokémon) e o que cada um solta na arena.
## slot: 0 = neutro (H), 1 = frente (→+H), 2 = cima (↑+H), 3 = baixo (↓+H)
## Campos: nome, desc, startup/active/recovery (quadros a 60 por segundo), cd (recarga em quadros).
## Poderes "do corpo" (self) têm caixa de golpe própria (box, dmg, kb...).

const FLOOR_Y := 600.0

const DEF := {
	# ---------------------------------------------------------------- PROTÓTIPO (Energia)
	"orbe": {"nome": "Orbe de Núcleo", "desc": "Esfera de energia que voa reto até o rival.", "startup": 13, "active": 1, "recovery": 20, "cd": 45},
	"rajada": {"nome": "Rajada Tripla", "desc": "Três orbes em leque: difícil de pular.", "startup": 12, "active": 1, "recovery": 22, "cd": 80},
	"propulsor": {"nome": "Propulsor", "desc": "Sobe como um foguete. Invencível no começo.", "startup": 4, "active": 14, "recovery": 18, "cd": 70,
		"self": "rise", "dmg": 90.0, "hitstun": 28, "blockstun": 16, "kb": Vector2(100, -900), "box": Rect2(-10, -225, 110, 225), "gain": 11.0, "invuln": 6},
	"mina": {"nome": "Mina de Núcleo", "desc": "Deixa uma mina no chão que explode quando o rival chega perto.", "startup": 10, "active": 1, "recovery": 16, "cd": 150},
	# ---------------------------------------------------------------- GUARDIÃO DAS CHAMAS (Fogo)
	"bola_fogo": {"nome": "Bola de Fogo", "desc": "Uma bola de fogo com rastro de chamas.", "startup": 13, "active": 1, "recovery": 20, "cd": 45},
	"investida": {"nome": "Investida Ígnea", "desc": "Avança envolto em chamas e arremessa o rival.", "startup": 8, "active": 16, "recovery": 16, "cd": 60,
		"self": "rush", "speed": 760.0, "dmg": 95.0, "hitstun": 24, "blockstun": 16, "kb": Vector2(460, -260), "box": Rect2(10, -150, 95, 140), "gain": 11.0},
	"coluna_fogo": {"nome": "Coluna de Fogo", "desc": "Uma coluna de fogo sobe à sua frente. Ótima contra pulos.", "startup": 12, "active": 1, "recovery": 20, "cd": 80},
	"brasas": {"nome": "Rastro de Brasas", "desc": "Deixa o chão em chamas por alguns segundos.", "startup": 10, "active": 1, "recovery": 18, "cd": 130},
	# ---------------------------------------------------------------- ENTIDADE DAS SOMBRAS (Sombra)
	"esfera_sombria": {"nome": "Esfera Sombria", "desc": "Uma esfera escura que ondula no ar.", "startup": 14, "active": 1, "recovery": 20, "cd": 50},
	"sombra": {"nome": "Passo Sombrio", "desc": "Some e reaparece atrás do rival com um golpe.", "startup": 12, "active": 4, "recovery": 14, "cd": 60,
		"self": "tp", "dmg": 85.0, "hitstun": 22, "blockstun": 14, "kb": Vector2(320, -200), "box": Rect2(10, -150, 105, 130), "gain": 10.0, "lunge": 20.0},
	"garra": {"nome": "Garras Sombrias", "desc": "Garras saem do chão embaixo do rival.", "startup": 10, "active": 1, "recovery": 22, "cd": 85},
	"poco": {"nome": "Poço Sombrio", "desc": "Uma poça de sombra que deixa o rival lento.", "startup": 10, "active": 1, "recovery": 18, "cd": 150},
	# ---------------------------------------------------------------- GUARDIÃO DA FLORESTA (Planta)
	"folha": {"nome": "Folha Navalha", "desc": "Três folhas afiadas giram até o rival.", "startup": 12, "active": 1, "recovery": 20, "cd": 50},
	"raizes": {"nome": "Raízes Presas", "desc": "Raízes brotam do chão em fila e lançam o rival.", "startup": 10, "active": 1, "recovery": 28, "cd": 70},
	"broto": {"nome": "Broto Gigante", "desc": "Um broto enorme sobe à sua frente. Ótimo contra pulos.", "startup": 9, "active": 1, "recovery": 22, "cd": 75},
	"semente": {"nome": "Semente Bomba", "desc": "Arremessa uma semente que vira um espinheiro no chão.", "startup": 12, "active": 1, "recovery": 18, "cd": 120},
	# ---------------------------------------------------------------- ESPÍRITO DOS VENTOS (Vento)
	"lamina_ar": {"nome": "Lâmina de Ar", "desc": "Uma lâmina de vento muito rápida.", "startup": 10, "active": 1, "recovery": 18, "cd": 40},
	"tornado": {"nome": "Tornado", "desc": "Um redemoinho lento que levanta o rival várias vezes.", "startup": 12, "active": 1, "recovery": 22, "cd": 80},
	"rajada_asc": {"nome": "Rajada Ascendente", "desc": "Sobe girando com o vento. Invencível no começo.", "startup": 4, "active": 16, "recovery": 18, "cd": 70,
		"self": "rise", "dmg": 85.0, "hitstun": 28, "blockstun": 16, "kb": Vector2(80, -900), "box": Rect2(-30, -230, 130, 230), "gain": 11.0, "invuln": 6},
	"corrente": {"nome": "Corrente de Ar", "desc": "Uma ventania que empurra o rival para longe.", "startup": 10, "active": 1, "recovery": 18, "cd": 110},
	# ---------------------------------------------------------------- NÚCLEO DAS MARÉS (Água)
	"hidro_jato": {"nome": "Hidro Jato", "desc": "Um jato de água muito rápido.", "startup": 11, "active": 1, "recovery": 18, "cd": 40},
	"onda": {"nome": "Onda", "desc": "Uma onda corre pelo chão (dá para pular por cima).", "startup": 12, "active": 1, "recovery": 20, "cd": 60},
	"geiser": {"nome": "Gêiser", "desc": "Um gêiser explode embaixo do rival.", "startup": 12, "active": 1, "recovery": 22, "cd": 85},
	"bolhas": {"nome": "Bolhas", "desc": "Três bolhas flutuam devagar e estouram no rival.", "startup": 12, "active": 1, "recovery": 18, "cd": 120},
	# ---------------------------------------------------------------- CORAÇÃO GLACIAL (Gelo)
	"lanca": {"nome": "Lança de Gelo", "desc": "Projétil rápido que congela o rival por um instante.", "startup": 11, "active": 1, "recovery": 22, "cd": 50},
	"rajada_glacial": {"nome": "Rajada Glacial", "desc": "Um sopro de gelo de perto que congela.", "startup": 10, "active": 1, "recovery": 24, "cd": 90},
	"pico": {"nome": "Pico de Gelo", "desc": "Um cristal de gelo sobe à sua frente.", "startup": 10, "active": 1, "recovery": 20, "cd": 75},
	"chao_gelo": {"nome": "Chão Congelado", "desc": "Uma placa de gelo que congela quem pisar.", "startup": 10, "active": 1, "recovery": 18, "cd": 140},
	# ---------------------------------------------------------------- RELÍQUIA SOLAR (Luz)
	"disco": {"nome": "Disco Solar", "desc": "Um disco de luz que gira até o rival.", "startup": 12, "active": 1, "recovery": 18, "cd": 45},
	"raio_luz": {"nome": "Raio de Luz", "desc": "Um raio fino que cruza a arena num instante.", "startup": 16, "active": 1, "recovery": 24, "cd": 100},
	"ascensao": {"nome": "Ascensão Solar", "desc": "Golpe para cima, invencível no início. Ótimo contra pulos.", "startup": 5, "active": 14, "recovery": 18, "cd": 60,
		"self": "rise", "dmg": 100.0, "hitstun": 28, "blockstun": 16, "kb": Vector2(90, -900), "box": Rect2(-10, -225, 110, 225), "gain": 11.0, "invuln": 6},
	"clarao": {"nome": "Clarão", "desc": "Uma explosão de luz em volta que deixa o rival tonto.", "startup": 8, "active": 1, "recovery": 26, "cd": 120},
	# ---------------------------------------------------------------- COLOSSO DE PEDRA (Pedra)
	"pedra": {"nome": "Arremesso de Pedra", "desc": "Arremessa uma rocha enorme em arco.", "startup": 16, "active": 1, "recovery": 22, "cd": 55},
	"avalanche": {"nome": "Avalanche", "desc": "Investida pesada que aguenta um golpe sem parar.", "startup": 10, "active": 18, "recovery": 20, "cd": 80,
		"self": "rush", "speed": 620.0, "armor": true, "dmg": 110.0, "hitstun": 26, "blockstun": 18, "kb": Vector2(520, -300), "box": Rect2(10, -160, 100, 160), "gain": 12.0},
	"pilar": {"nome": "Pilar de Pedra", "desc": "Um pilar de pedra sobe à sua frente.", "startup": 12, "active": 1, "recovery": 22, "cd": 80},
	"pisao": {"nome": "Pisão Sísmico", "desc": "Ondas de choque correm pelo chão (pule!).", "startup": 14, "active": 1, "recovery": 22, "cd": 110},
	# ---------------------------------------------------------------- AUTÔMATO STEAMPUNK (Metal)
	"serra": {"nome": "Engrenagem Serra", "desc": "Lança uma serra que vai e volta como bumerangue.", "startup": 12, "active": 1, "recovery": 18, "cd": 70},
	"vapor": {"nome": "Jato de Vapor", "desc": "Um jato de vapor de perto que empurra o rival.", "startup": 10, "active": 1, "recovery": 22, "cd": 80},
	"martelo": {"nome": "Martelo a Vapor", "desc": "Sobe com um golpe de pistão. Invencível no começo.", "startup": 6, "active": 14, "recovery": 20, "cd": 75,
		"self": "rise", "dmg": 95.0, "hitstun": 28, "blockstun": 16, "kb": Vector2(100, -880), "box": Rect2(-10, -225, 115, 225), "gain": 11.0, "invuln": 7},
	"torreta": {"nome": "Torreta", "desc": "Monta uma torreta que atira sozinha por um tempo.", "startup": 14, "active": 1, "recovery": 18, "cd": 220},
	# ---------------------------------------------------------------- VIAJANTE CÓSMICO (Cosmos)
	"estrela": {"nome": "Estrela Cadente", "desc": "Uma estrela cai do céu mirando no rival.", "startup": 12, "active": 1, "recovery": 20, "cd": 50},
	"portal": {"nome": "Portal Estelar", "desc": "Entra num portal e cai em cima do rival.", "startup": 14, "active": 40, "recovery": 16, "cd": 80,
		"self": "portal", "dmg": 90.0, "hitstun": 24, "blockstun": 16, "kb": Vector2(240, -380), "box": Rect2(-58, -175, 116, 185), "gain": 10.0},
	"aneis": {"nome": "Anéis Planetários", "desc": "Anéis giram em volta e acertam quem chegar perto.", "startup": 6, "active": 1, "recovery": 18, "cd": 90},
	"buraco_negro": {"nome": "Buraco Negro", "desc": "Um buraco negro que puxa o rival.", "startup": 14, "active": 1, "recovery": 20, "cd": 160},
	# ---------------------------------------------------------------- ALQUIMISTA PROIBIDO (Veneno)
	"frasco": {"nome": "Frasco Tóxico", "desc": "Arremessa um frasco que deixa uma nuvem venenosa.", "startup": 14, "active": 1, "recovery": 20, "cd": 60},
	"acido": {"nome": "Bomba Ácida", "desc": "Um projétil ácido rápido que envenena.", "startup": 10, "active": 1, "recovery": 18, "cd": 55},
	"geiser_acido": {"nome": "Gêiser Ácido", "desc": "Ácido jorra do chão à sua frente e envenena.", "startup": 12, "active": 1, "recovery": 22, "cd": 85},
	"runa": {"nome": "Runa Proibida", "desc": "Uma runa no chão que explode quando o rival pisa.", "startup": 12, "active": 1, "recovery": 18, "cd": 150},
}

const SLOT_NOME := ["NEUTRO", "FRENTE", "CIMA", "BAIXO"]

static func get_def(id: String) -> Dictionary:
	return DEF.get(id, {})

## Solta na arena o que o poder cria (projéteis, colunas, armadilhas...).
static func spawn(id: String, f: Node2D, fight: Node) -> void:
	if fight == null:
		return
	var d: int = f.facing
	var cor: Color = f.data.cor
	var x: float = f.position.x
	var y: float = f.position.y
	var o: Node2D = f.opp
	var base := {"owner": f, "dir": d, "cor": cor, "power": true}
	match id:
		# ---------------- projéteis retos
		"orbe":
			_s(fight, base, {"kind": "orb", "pos": Vector2(x + d * 80, y - 100), "vel": Vector2(d * 640, 0), "size": Vector2(46, 46), "life": 170,
				"dmg": 75.0, "kb": Vector2(300, -120), "hitstun": 20, "blockstun": 14, "projectile": true, "destroy_on_hit": true, "gain": 9.0})
			Game.play("zap")
		"rajada":
			for k in 3:
				var ang := (k - 1) * 0.2
				_s(fight, base, {"kind": "miniorb", "pos": Vector2(x + d * 80, y - 100), "vel": Vector2(d * cos(ang), sin(ang)) * 700.0,
					"size": Vector2(30, 30), "life": 120, "dmg": 30.0, "kb": Vector2(160, -100), "hitstun": 16, "blockstun": 10,
					"projectile": true, "destroy_on_hit": true, "gain": 4.0, "sfx": "hit_light"})
			Game.play("zap", 1.2)
		"bola_fogo":
			_s(fight, base, {"kind": "fireball", "pos": Vector2(x + d * 80, y - 95), "vel": Vector2(d * 600, 0), "size": Vector2(50, 46), "life": 170,
				"dmg": 80.0, "kb": Vector2(300, -160), "hitstun": 20, "blockstun": 14, "projectile": true, "destroy_on_hit": true, "gain": 9.0})
			Game.play("fire", 1.3, -4)
		"esfera_sombria":
			_s(fight, base, {"kind": "shadowball", "pos": Vector2(x + d * 80, y - 100), "vel": Vector2(d * 520, 0), "wave_amp": 26.0, "wave_freq": 0.16,
				"size": Vector2(56, 56), "life": 190, "dmg": 85.0, "kb": Vector2(300, -200), "hitstun": 22, "blockstun": 14, "projectile": true,
				"destroy_on_hit": true, "gain": 9.0})
			Game.play("shadow", 1.2)
		"folha":
			for k in 3:
				var ang2 := (k - 1) * 0.12
				_s(fight, base, {"kind": "leaf", "pos": Vector2(x + d * 70, y - 90 - (k - 1) * 12), "vel": Vector2(d * cos(ang2), sin(ang2)) * 620.0,
					"delay": k * 4, "size": Vector2(34, 28), "life": 140, "dmg": 28.0, "kb": Vector2(140, -120), "hitstun": 16, "blockstun": 10,
					"projectile": true, "destroy_on_hit": true, "gain": 4.0, "sfx": "hit_light"})
			Game.play("wind", 1.6, -6)
		"lamina_ar":
			_s(fight, base, {"kind": "airblade", "pos": Vector2(x + d * 80, y - 100), "vel": Vector2(d * 820, 0), "size": Vector2(44, 84), "life": 130,
				"dmg": 60.0, "kb": Vector2(260, -140), "hitstun": 18, "blockstun": 12, "projectile": true, "destroy_on_hit": true, "gain": 8.0})
			Game.play("wind", 1.4, -2)
		"hidro_jato":
			_s(fight, base, {"kind": "waterjet", "pos": Vector2(x + d * 80, y - 98), "vel": Vector2(d * 900, 0), "size": Vector2(70, 34), "life": 120,
				"dmg": 60.0, "kb": Vector2(280, -100), "hitstun": 18, "blockstun": 12, "projectile": true, "destroy_on_hit": true, "gain": 8.0})
			Game.play("water", 1.4, -2)
		"lanca":
			_s(fight, base, {"kind": "ice", "pos": Vector2(x + d * 80, y - 100), "vel": Vector2(d * 880, 0), "size": Vector2(84, 36), "life": 120,
				"dmg": 58.0, "freeze": 28, "kb": Vector2(160, 0), "hitstun": 18, "blockstun": 12, "projectile": true, "destroy_on_hit": true, "gain": 9.0})
			Game.play("ice")
		"disco":
			_s(fight, base, {"kind": "sundisc", "pos": Vector2(x + d * 80, y - 100), "vel": Vector2(d * 700, 0), "size": Vector2(58, 58), "life": 150,
				"dmg": 70.0, "kb": Vector2(280, -160), "hitstun": 20, "blockstun": 14, "projectile": true, "destroy_on_hit": true, "gain": 9.0})
			Game.play("zap", 0.9)
		"acido":
			_s(fight, base, {"kind": "acid", "pos": Vector2(x + d * 80, y - 98), "vel": Vector2(d * 760, 0), "size": Vector2(54, 40), "life": 130,
				"dmg": 55.0, "poison": true, "kb": Vector2(220, -120), "hitstun": 18, "blockstun": 12, "projectile": true, "destroy_on_hit": true, "gain": 8.0})
			Game.play("poison", 1.3)
		"serra":
			_s(fight, base, {"kind": "gear", "pos": Vector2(x + d * 80, y - 95), "vel": Vector2(d * 950, 0), "accel": Vector2(-d * 1150, 0),
				"size": Vector2(66, 66), "life": 220, "hits": 2, "interval": 22, "dmg": 42.0, "kb": Vector2(200, -150), "hitstun": 20, "blockstun": 12,
				"projectile": true, "boomerang": true, "gain": 6.0, "sfx": "hit_light"})
			Game.play("gear")
		# ---------------- projéteis em arco / mirados
		"pedra":
			_s(fight, base, {"kind": "boulder", "pos": Vector2(x + d * 60, y - 150), "vel": Vector2(d * 520, -430), "grav": 1400.0, "size": Vector2(80, 80),
				"life": 200, "dmg": 95.0, "kb": Vector2(320, -420), "hitstun": 24, "blockstun": 16, "projectile": true, "destroy_on_hit": true,
				"on_ground": "die", "on_death": "dust", "gain": 10.0})
			Game.play("whoosh", 0.6)
		"frasco":
			_s(fight, base, {"kind": "flask", "pos": Vector2(x + d * 60, y - 135), "vel": Vector2(d * 470, -640), "grav": 1900.0, "size": Vector2(36, 36),
				"life": 140, "dmg": 38.0, "kb": Vector2(120, -200), "hitstun": 18, "blockstun": 10, "destroy_on_hit": true, "on_ground": "die",
				"on_death": "poison", "gain": 6.0})
			Game.play("whoosh", 0.8)
		"semente":
			_s(fight, base, {"kind": "seed", "pos": Vector2(x + d * 60, y - 130), "vel": Vector2(d * 400, -560), "grav": 1800.0, "size": Vector2(30, 30),
				"life": 140, "dmg": 30.0, "kb": Vector2(120, -260), "hitstun": 18, "blockstun": 10, "destroy_on_hit": true, "on_ground": "die",
				"on_death": "thorns", "gain": 5.0})
			Game.play("whoosh", 1.1)
		"estrela":
			var alvo: Vector2 = o.position + Vector2(0, -80)
			var start := Vector2(x + d * 40, 60.0)
			var v: Vector2 = (alvo - start).normalized() * 760.0
			_s(fight, base, {"kind": "star", "pos": start, "vel": v, "size": Vector2(54, 54), "life": 160, "dmg": 70.0,
				"kb": Vector2(260, -300), "hitstun": 20, "blockstun": 14, "projectile": true, "destroy_on_hit": true, "on_ground": "die",
				"on_death": "pop", "gain": 9.0})
			Game.play("portal", 1.5, -4)
		# ---------------- erupções (anti-aéreo / embaixo do rival)
		"coluna_fogo":
			_s(fight, base, {"kind": "firepillar", "pos": Vector2(clampf(x + d * 170, 50, 1230), FLOOR_Y), "anchor": "b", "size": Vector2(110, 300),
				"delay": 6, "life": 18, "dmg": 85.0, "kb": Vector2(60, -850), "hitstun": 28, "blockstun": 14, "gain": 9.0})
			Game.play("fire", 1.1)
		"garra":
			_s(fight, base, {"kind": "claw", "pos": Vector2(o.position.x, FLOOR_Y), "anchor": "b", "track": true, "track_lock": 8, "size": Vector2(120, 260),
				"delay": 22, "life": 14, "dmg": 80.0, "kb": Vector2(40, -820), "hitstun": 28, "blockstun": 14, "gain": 9.0})
			Game.play("shadow", 0.9)
		"broto":
			_s(fight, base, {"kind": "sprout", "pos": Vector2(clampf(x + d * 120, 50, 1230), FLOOR_Y), "anchor": "b", "size": Vector2(90, 280),
				"delay": 6, "life": 18, "dmg": 85.0, "kb": Vector2(60, -880), "hitstun": 28, "blockstun": 14, "gain": 9.0})
			Game.play("quake", 1.6, -8)
		"geiser":
			_s(fight, base, {"kind": "geyser", "pos": Vector2(o.position.x, FLOOR_Y), "anchor": "b", "track": true, "track_lock": 8, "size": Vector2(120, 360),
				"delay": 26, "life": 22, "hits": 2, "interval": 8, "dmg": 42.0, "kb": Vector2(0, -500), "kb_last": Vector2(120, -900),
				"hitstun": 30, "blockstun": 12, "gain": 5.0})
			Game.play("water", 0.9)
		"pico":
			_s(fight, base, {"kind": "icespike", "pos": Vector2(clampf(x + d * 150, 50, 1230), FLOOR_Y), "anchor": "b", "size": Vector2(110, 240),
				"delay": 6, "life": 22, "dmg": 80.0, "freeze": 20, "kb": Vector2(40, -700), "hitstun": 26, "blockstun": 14, "gain": 9.0})
			Game.play("ice", 0.9)
		"pilar":
			_s(fight, base, {"kind": "pillar", "pos": Vector2(clampf(x + d * 150, 50, 1230), FLOOR_Y), "anchor": "b", "size": Vector2(110, 260),
				"delay": 6, "life": 22, "dmg": 90.0, "kb": Vector2(60, -860), "hitstun": 28, "blockstun": 14, "gain": 10.0})
			Game.play("quake", 1.3, -4)
		"geiser_acido":
			_s(fight, base, {"kind": "acidgeyser", "pos": Vector2(clampf(x + d * 170, 50, 1230), FLOOR_Y), "anchor": "b", "size": Vector2(110, 320),
				"delay": 8, "life": 22, "dmg": 80.0, "poison": true, "kb": Vector2(40, -850), "hitstun": 28, "blockstun": 14, "gain": 9.0})
			Game.play("poison", 0.8)
		# ---------------- golpes de perto que saem do corpo
		"rajada_glacial":
			_s(fight, base, {"kind": "frost", "follow": Vector2(150, -95), "pos": f.position, "anchor": "c", "size": Vector2(230, 120), "life": 22,
				"hits": 2, "interval": 10, "dmg": 30.0, "freeze": 30, "kb": Vector2(120, 0), "hitstun": 20, "blockstun": 12, "gain": 6.0, "sfx": "hit_light"})
			Game.play("ice", 0.7)
		"vapor":
			_s(fight, base, {"kind": "steam", "follow": Vector2(140, -95), "pos": f.position, "anchor": "c", "size": Vector2(220, 120), "life": 20,
				"hits": 2, "interval": 8, "dmg": 26.0, "kb": Vector2(520, -140), "hitstun": 18, "blockstun": 12, "push": 520.0, "gain": 6.0, "sfx": "hit_light"})
			Game.play("wind", 0.6)
		"clarao":
			_s(fight, base, {"kind": "flash", "follow": Vector2(0, -90), "pos": f.position, "anchor": "c", "size": Vector2(300, 300), "life": 8,
				"dmg": 40.0, "kb": Vector2(300, -200), "hitstun": 52, "blockstun": 12, "gain": 8.0})
			Game.play("zap", 0.6)
		"aneis":
			_s(fight, base, {"kind": "rings", "follow": Vector2(0, -90), "pos": f.position, "anchor": "c", "size": Vector2(240, 240), "life": 50,
				"hits": 4, "interval": 11, "dmg": 22.0, "kb": Vector2(180, -260), "hitstun": 18, "blockstun": 10, "gain": 4.0, "sfx": "hit_light"})
			Game.play("portal", 1.3, -4)
		# ---------------- raios
		"raio_luz":
			_s(fight, base, {"kind": "lightray", "pos": Vector2(x + d * 70, y - 100), "anchor": "beam", "size": Vector2(1000, 46), "life": 14,
				"hits": 2, "interval": 6, "dmg": 40.0, "kb": Vector2(260, -120), "hitstun": 18, "blockstun": 12, "gain": 6.0})
			Game.play("beam", 1.4, -2)
		# ---------------- pelo chão
		"raizes":
			for i in 4:
				_s(fight, base, {"kind": "vine", "pos": Vector2(x + d * (95 + i * 88), FLOOR_Y), "anchor": "b", "size": Vector2(84, 155),
					"delay": 4 + i * 6, "life": 14, "dmg": 26.0 if i < 3 else 40.0, "kb": Vector2(100, -560), "hitstun": 26, "blockstun": 10,
					"gain": 4.0, "sfx": "hit_light"})
			Game.play("quake", 1.4, -6)
		"tornado":
			_s(fight, base, {"kind": "tornado", "pos": Vector2(x + d * 90, FLOOR_Y), "anchor": "b", "vel": Vector2(d * 360, 0), "size": Vector2(92, 195),
				"life": 100, "hits": 3, "interval": 8, "dmg": 26.0, "kb": Vector2(60, -420), "kb_last": Vector2(220, -760), "hitstun": 24,
				"blockstun": 10, "projectile": true, "gain": 4.0, "sfx": "hit_light"})
			Game.play("wind")
		"onda":
			_s(fight, base, {"kind": "wave", "pos": Vector2(x + d * 80, FLOOR_Y), "anchor": "b", "vel": Vector2(d * 560, 0), "size": Vector2(130, 88),
				"life": 110, "dmg": 72.0, "kb": Vector2(360, -260), "hitstun": 22, "blockstun": 14, "projectile": true, "destroy_on_hit": true, "gain": 9.0})
			Game.play("water")
		"pisao":
			for s in [-1, 1]:
				_s(fight, base, {"kind": "shock", "pos": Vector2(x + s * 60, FLOOR_Y), "anchor": "b", "vel": Vector2(s * 520, 0), "size": Vector2(70, 56),
					"life": 70, "dmg": 60.0, "kb": Vector2(100, -560), "hitstun": 26, "blockstun": 12, "ground_only": true, "dir": s, "gain": 8.0})
			Game.play("quake", 1.0)
			fight.fx.ring(Vector2(x, FLOOR_Y - 5), f.data.cor2, 1.4)
		"corrente":
			_s(fight, base, {"kind": "gust", "pos": Vector2(x + d * 90, FLOOR_Y), "anchor": "b", "vel": Vector2(d * 300, 0), "size": Vector2(100, 210),
				"life": 90, "hits": 2, "interval": 30, "dmg": 12.0, "kb": Vector2(700, -120), "hitstun": 16, "blockstun": 10, "push": 600.0, "gain": 3.0,
				"sfx": "hit_light"})
			Game.play("wind", 0.8)
		"bolhas":
			for k in 3:
				_s(fight, base, {"kind": "bubble", "pos": Vector2(x + d * 70, y - 70 - k * 40), "vel": Vector2(d * (120 + k * 40), 0), "wave_amp": 18.0,
					"wave_freq": 0.08 + k * 0.02, "size": Vector2(44, 44), "life": 260, "delay": k * 8, "dmg": 30.0, "kb": Vector2(100, -300),
					"hitstun": 18, "blockstun": 10, "projectile": true, "destroy_on_hit": true, "on_death": "splash", "gain": 4.0, "sfx": "hit_light"})
			Game.play("water", 1.6, -4)
		# ---------------- zonas e armadilhas
		"brasas":
			_s(fight, base, {"kind": "embers", "pos": Vector2(clampf(x + d * 220, 120, 1160), FLOOR_Y), "anchor": "b", "size": Vector2(320, 46),
				"life": 160, "hits": 5, "interval": 28, "dmg": 16.0, "kb": Vector2(60, -180), "hitstun": 14, "blockstun": 8, "ground_only": true,
				"gain": 2.0, "sfx": "hit_light", "single": true})
			Game.play("fire", 1.0, -4)
		"poco":
			_s(fight, base, {"kind": "darkpool", "pos": Vector2(clampf(x + d * 190, 110, 1170), FLOOR_Y), "anchor": "b", "size": Vector2(210, 40),
				"life": 240, "hits": 4, "interval": 45, "dmg": 12.0, "kb": Vector2(0, 0), "hitstun": 10, "blockstun": 6, "slow": true, "ground_only": true,
				"gain": 2.0, "sfx": "hit_light", "single": true})
			Game.play("shadow", 0.7)
		"mina":
			_s(fight, base, {"kind": "mine", "pos": Vector2(clampf(x + d * 130, 60, 1220), FLOOR_Y), "anchor": "b", "size": Vector2(80, 40),
				"life": 330, "trap": true, "arm": 20, "trigger": Vector2(150, 160), "dmg": 80.0, "kb": Vector2(150, -720), "hitstun": 28,
				"blockstun": 14, "gain": 9.0, "single": true})
			Game.play("gear", 1.4, -4)
		"chao_gelo":
			_s(fight, base, {"kind": "icefloor", "pos": Vector2(clampf(x + d * 170, 100, 1180), FLOOR_Y), "anchor": "b", "size": Vector2(180, 26),
				"life": 300, "trap": true, "arm": 15, "trigger": Vector2(180, 60), "trigger_ground": true, "dmg": 50.0, "freeze": 60,
				"kb": Vector2(0, 0), "hitstun": 20, "blockstun": 10, "gain": 8.0, "single": true})
			Game.play("ice", 1.3, -4)
		"runa":
			_s(fight, base, {"kind": "rune", "pos": Vector2(clampf(x + d * 180, 100, 1180), FLOOR_Y), "anchor": "b", "size": Vector2(160, 30),
				"life": 300, "trap": true, "arm": 20, "trigger": Vector2(160, 70), "trigger_ground": true, "dmg": 90.0, "kb": Vector2(80, -900),
				"poison": true, "hitstun": 30, "blockstun": 14, "gain": 9.0, "single": true})
			Game.play("poison", 1.1)
		"torreta":
			_s(fight, base, {"kind": "turret", "pos": Vector2(clampf(x + d * 90, 60, 1220), FLOOR_Y), "anchor": "b", "size": Vector2(70, 80),
				"life": 330, "fire_every": 70, "visual_only": true, "single": true})
			Game.play("gear", 0.9)
		"buraco_negro":
			_s(fight, base, {"kind": "blackhole", "pos": Vector2(clampf(x + d * 260, 80, 1200), y - 110), "anchor": "c", "size": Vector2(90, 90),
				"life": 150, "pull": 360.0, "hits": 5, "interval": 28, "dmg": 12.0, "kb": Vector2(0, 0), "hitstun": 12, "blockstun": 6,
				"gain": 2.0, "sfx": "hit_light", "single": true})
			Game.play("portal", 0.5)

static func _s(fight: Node, base: Dictionary, e: Dictionary) -> void:
	var d := base.duplicate()
	d.merge(e, true)
	fight.spawn(d)
