# BOTTON ARENA — A Batalha dos Núcleos (v0.1)

Jogo de luta 1 contra 1 para 2 jogadores no mesmo teclado (ou contra a CPU), feito no **Godot 4.7** no modo **Compatibility** (roda em vídeo integrado).

## Como jogar
1. Baixe o Godot 4.7 (versão padrão, não a .NET) em https://godotengine.org/download e descompacte.
2. Abra o Godot, clique em **Importar**, escolha o arquivo `project.godot` desta pasta.
3. Com o projeto aberto, aperte **F5** (ou o botão ▶ no canto superior direito).

## Controles
| Ação | Jogador 1 | Jogador 2 |
|---|---|---|
| Andar / pular | A D / W | ← → / ↑ |
| Ataque leve | F | K |
| Ataque pesado | G | L |
| Especial | H | Ç |
| Defesa (segure) | R | O |
| Dash | Shift esquerdo (ou toque duplo na direção) | I (ou toque duplo) |
| Supremo (Núcleo cheio) | T | P |
| Pausa | Esc | Esc |

Controles de videogame também funcionam: o 1º controle é do Jogador 1, o 2º do Jogador 2.

## Sistemas
- **Combos:** leve → leve → pesado lança o adversário para o ar; dá para continuar no ar. Golpes leves podem ser cancelados em pesado ou especial.
- **Limite de combo:** depois de 6 acertos no ar o adversário cai; golpes seguidos causam cada vez menos dano.
- **Defesa:** segure a tecla de defesa. Apertar a defesa logo antes do golpe chegar faz um **PERFEITO**: não toma dano, o atacante fica atordoado e você ganha Núcleo.
- **Núcleo:** enche ao bater, apanhar e defender. Cheio, libera o **Supremo** (câmera cinematográfica + raio).
- **Choque de poderes:** dois orbes que se encontram se anulam.
- **Especiais** (por personagem): Orbe de Núcleo (projétil), Investida, Ascensão (golpe para cima) e Passo Sombrio (teleporte para trás do adversário).
- Melhor de 3 rounds, 99 segundos por round.

## Onde mexer
- `scripts/game.gd` — elenco (nomes, frases, cores, atributos, especial de cada um) e teclas.
- `scripts/fighter.gd` — golpes (`MOVES`: dano, velocidade, alcance), pulo, gravidade.
- `scripts/fight.gd` — rounds, tempo, CPU.
- `scripts/arena_bg.gd` — o cenário.
- `assets/chars/` — a arte de cada botton (PNG com fundo transparente).

## Testes automáticos
- `godot --headless -- --mechtest` testa combos, defesa, perfeito, especiais e supremo.
- `godot --headless -- --autotest --fights=3` faz CPU contra CPU em 3 lutas.
