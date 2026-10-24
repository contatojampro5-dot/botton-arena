extends SceneTree
## Gera as tabelas do README a partir dos dados do jogo (rodar: godot --headless -s tests/tabela_readme.gd)
func _init() -> void:
	var G = load("res://scripts/game.gd")
	var P = load("res://scripts/powers.gd")
	var tipos: Dictionary = G.TIPOS
	print("| Botton | Tipo | H (neutro) | → + H (frente) | ↑ + H (cima) | ↓ + H (baixo) | Supremo |")
	print("|---|---|---|---|---|---|---|")
	for c in G.ROSTER:
		var cel := []
		for pid in c.poderes:
			var d: Dictionary = P.DEF[pid]
			cel.append("**%s**: %s" % [d.nome, d.desc])
		print("| %s | %s | %s | %s | %s | %s | **%s**: %s |" % [c.nome, tipos[c.tipo].nome, cel[0], cel[1], cel[2], cel[3], c.supremo_nome, c.supremo_desc])
	print("")
	print("| Tipo | Forte contra | Fraco contra |")
	print("|---|---|---|")
	for k in tipos.keys():
		var fortes := []
		for f in tipos[k].forte: fortes.append(tipos[f].nome)
		var fracos := []
		for k2 in tipos.keys():
			if k in tipos[k2].forte: fracos.append(tipos[k2].nome)
		print("| %s | %s | %s |" % [tipos[k].nome, ", ".join(fortes), ", ".join(fracos)])
	quit()
