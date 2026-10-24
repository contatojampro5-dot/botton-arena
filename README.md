# BOTTON ARENA — A Batalha dos Núcleos (v0.2)

Jogo de luta 1 contra 1 com os 12 bottons, feito no **Godot 4.7** no modo **Compatibility** (roda em vídeo integrado, como o do Lenovo G40-80).

## Como jogar
1. Baixe o Godot 4.7 (versão padrão, não a .NET) em https://godotengine.org/download e descompacte.
2. No GitHub, clique em **Code > Download ZIP** e descompacte (ou importe o zip direto no Godot).
3. Abra o Godot, clique em **Importar**, escolha o `project.godot` e depois **Importar e Editar**.
4. Aperte **F5** (ou o botão ▶ no canto superior direito).

## Modos
- **Arcade**: escolha seu botton e vença 6 rivais seguidos, cada um na sua arena, com a CPU ficando mais forte. No fim, o chefe **Eco Sombrio** (uma versão sombria e mais forte de você). Tem pontuação, tempo e continues.
- **2 Jogadores**: dois jogadores no mesmo teclado ou com controles.
- **Contra CPU**: escolha seu botton e o da CPU.
- **Treino**: boneco que fica parado, defende, pula ou luta como CPU; vida que se recupera, Núcleo infinito e contador de combo com recorde.
- **Opções**: volume da música e dos efeitos, dificuldade da CPU (fácil, normal, difícil), tempo do round (60, 99 ou infinito), rounds (1, melhor de 3 ou de 5) e tela cheia. Tudo fica salvo.

## Controles
| Ação | Jogador 1 | Jogador 2 |
|---|---|---|
| Andar / pular | A D / W | ← → / ↑ |
| Ataque leve | F | K |
| Ataque pesado | G | L |
| Especial | H | Ç |
| Defesa (segure) | R | O |
| Dash | Shift esquerdo (ou dois toques na direção) | I (ou dois toques) |
| Supremo (Núcleo cheio) | T | P |
| Sobrecarga / Explosão de Núcleo | G + H juntos | L + Ç juntos |
| Pausa | Esc | Esc |

Controles de videogame também funcionam: o 1º é do Jogador 1, o 2º do Jogador 2 (X leve, Y pesado, B especial, LB defesa, RB dash, RT supremo, Start pausa).

## Sistemas de luta
- **Braços animados**: cada botton tem corpo e braços separados, que socam, defendem, erguem e comemoram.
- **Combos**: leve → leve → pesado lança o rival para o ar; dá para continuar no ar e cancelar em especial ou supremo.
- **Defesa e PERFEITO**: segure a defesa. Apertar na hora exata em que o golpe chega faz um PERFEITO (sem dano, o atacante fica atordoado e você ganha Núcleo).
- **Núcleo**: enche ao bater, apanhar e defender.
  - **50%**: **Sobrecarga** (pesado + especial): 6 segundos com +20% de dano e velocidade, especial recarrega mais rápido.
  - **50% apanhando**: **Explosão de Núcleo** (pesado + especial): escapa do combo e empurra o rival.
  - **100%**: **Supremo** com câmera cinematográfica e faixa estilo anime.
- **Choque de poderes**: projéteis que se encontram se anulam (supremos vencem).
- **Limite de combo**: golpes seguidos causam menos dano e, depois de muitos acertos no ar, o rival cai.
- **Efeitos**: congelamento (gelo), veneno (alquimia), armadura (Avalanche), teleporte (sombras e portal).

## Os 12 bottons
| Botton | Especial | Supremo |
|---|---|---|
| PROTÓTIPO | **Orbe de Núcleo**: Dispara uma esfera de energia em linha reta. | **SOBRECARGA TOTAL**: Um raio de energia que atravessa a arena inteira. |
| GUARDIÃO DAS CHAMAS | **Investida Ígnea**: Avança envolto em chamas e arremessa o rival. | **ERUPÇÃO**: Colunas de fogo explodem do chão até o rival. |
| ENTIDADE DAS SOMBRAS | **Passo Sombrio**: Some e reaparece atrás do rival com um golpe. | **MIL SOMBRAS**: Sombras atacam o rival de todos os lados. |
| GUARDIÃO DA FLORESTA | **Raízes Presas**: Raízes brotam do chão à frente e lançam o rival. | **FÚRIA DA FLORESTA**: Uma árvore colossal nasce embaixo do rival. |
| ESPÍRITO DOS VENTOS | **Tornado**: Um redemoinho lento que levanta o rival várias vezes. | **CICLONE**: Um ciclone gigante varre a arena. |
| NÚCLEO DAS MARÉS | **Onda**: Uma onda corre pelo chão (dá para pular por cima). | **TSUNAMI**: Uma onda enorme cobre a arena inteira. |
| CORAÇÃO GLACIAL | **Lança de Gelo**: Projétil rápido que congela o rival por um instante. | **ERA GLACIAL**: Cristais brotam pelo chão, congelam e estilhaçam. |
| RELÍQUIA SOLAR | **Ascensão Solar**: Golpe para cima, invencível no início. Ótimo contra pulos. | **JULGAMENTO SOLAR**: Raios de luz caem do céu sobre o rival. |
| COLOSSO DE PEDRA | **Avalanche**: Investida pesada que aguenta um golpe sem parar. | **TERREMOTO**: Abala o chão inteiro (pule!) e faz chover pedras. |
| AUTÔMATO STEAMPUNK | **Engrenagem Serra**: Lança uma serra que vai e volta como bumerangue. | **CANHÃO A VAPOR**: Uma rajada de balas de engrenagem. |
| VIAJANTE CÓSMICO | **Portal Estelar**: Entra num portal e cai em cima do rival. | **CHUVA DE METEOROS**: Meteoros despencam do céu. |
| ALQUIMISTA PROIBIDO | **Frasco Tóxico**: Arremessa um frasco que deixa uma nuvem venenosa. | **TRANSMUTAÇÃO**: Um círculo alquímico explode sob o rival. |

## Arenas
Santuário dos Núcleos, Cratera Ardente, Floresta Ancestral, Pico Congelado, Costa das Marés, Órbita Estelar e Fábrica a Vapor. Todas desenhadas por código (leves) e com música própria.

## Onde mexer
- `scripts/game.gd`: elenco (nomes, frases, cores, atributos, especial e supremo), arenas, teclas e opções.
- `scripts/fighter.gd`: golpes (`MOVES`), especiais (`_spawn_special`), supremos (`_super_frame`) e poses dos braços (`P_...`).
- `scripts/fight.gd`: rounds, tempo, colisões, modos e menus.
- `scripts/ai.gd`: a CPU.
- `scripts/arena_bg.gd`: os cenários.
- `scripts/fx.gd`: efeitos visuais e o desenho de cada ataque.
- `assets/chars/`: a arte original de cada botton. `assets/rig/`: corpo e braços separados.
- `tools/`: scripts em Python que geraram as músicas (`compose_musicas.py`), os sons (`sfx.py`) e a separação dos braços (`separar_bracos.py`).

## Testes automáticos
- `godot --headless -- --mechtest`: testa combos, defesa, perfeito, sobrecarga e o especial e o supremo de cada botton.
- `godot --headless -- --autotest --fights=6`: CPU contra CPU em lutas aleatórias, Arcade e Treino.
- `godot -- --shots --shots=PASTA`: tira prints de todas as telas, arenas e golpes.
