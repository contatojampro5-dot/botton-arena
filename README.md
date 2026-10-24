# BOTTON ARENA — A Batalha dos Núcleos (v0.3)

Jogo de luta 1 contra 1 com os 12 bottons, feito no **Godot 4.7** no modo **Compatibility** (roda em vídeo integrado, como o do Lenovo G40-80).

## Jogar sem o Godot (Windows)
Baixe o jogo pronto por este link: https://github.com/contatojampro5-dot/botton-arena/raw/windows/BottonArena_v0.3_Windows.zip
(ele fica no ramo **windows** do repositório). Descompacte e dê dois cliques em **BOTTON ARENA.exe**. Se o Windows avisar "O Windows protegeu o computador", clique em **Mais informações** e depois em **Executar assim mesmo**.

## Novidades da v0.3
- **Poderes estilo Pokémon**: cada botton tem **4 poderes** (especial sozinho ou com direção) e um **tipo**. Poder de um tipo forte contra o tipo do rival dá **+25% de dano** e aparece **"É SUPER EFETIVO!"**.
- **Visual de vidro líquido** (estilo Liquid Glass) em todas as telas: painéis que desfocam o fundo, brilho na borda e seleção que desliza.
- **Controles de videogame completos**: menus, luta, pausa, vibração, botões na tela que mudam sozinhos entre teclado e controle, e aviso quando um controle é ligado ou desligado.
- **Mais leve e sem travadas**: o fundo de cada arena vira uma imagem só antes da luta, as letras são preparadas na abertura do jogo, os brilhos são mais baratos e existe a opção **Qualidade** (Automática, Alta, Leve). Na Automática, se o computador não aguentar 60 quadros por segundo, o jogo liga o modo leve sozinho.

## Como abrir no Godot
1. Baixe o Godot 4.7 (versão padrão, não a .NET) em https://godotengine.org/download e descompacte.
2. No GitHub, clique em **Code > Download ZIP** e descompacte (ou importe o zip direto no Godot).
3. Abra o Godot, clique em **Importar**, escolha o `project.godot` e depois **Importar e Editar**.
4. Aperte **F5** (ou o botão ▶ no canto superior direito).

## Modos
- **Arcade**: escolha seu botton e vença 6 rivais seguidos, cada um na sua arena, com a CPU ficando mais forte. No fim, o chefe **Eco Sombrio** (uma versão sombria e mais forte de você). Tem pontuação, tempo e continues.
- **2 Jogadores**: dois jogadores no mesmo teclado ou com controles.
- **Contra CPU**: escolha seu botton e o da CPU.
- **Treino**: boneco que fica parado, defende, pula ou luta como CPU; vida que se recupera, Núcleo infinito e contador de combo com recorde.
- **Galeria**: as fichas originais de cada botton, com tipo, vantagens, os 4 poderes e o supremo.
- **Opções**: música, efeitos, qualidade, dificuldade da CPU, tempo do round, rounds, tela cheia, vibração do controle e troca de controles (J1/J2). Tudo fica salvo.

## Controles
| Ação | Jogador 1 | Jogador 2 | Controle (Xbox / PlayStation) |
|---|---|---|---|
| Andar / pular | A D / W | ← → / ↑ | Direcional ou analógico |
| Ataque leve | F | K | X / □ |
| Ataque pesado | G | L | Y / △ |
| Poder | H | Ç | B / ○ |
| Poder da frente / de cima / de baixo | H + D / W / S | Ç + → / ↑ / ↓ | B + direção |
| Defesa (segure) | R | O | LB ou LT |
| Dash | Shift esquerdo (ou dois toques na direção) | I (ou dois toques) | RB |
| Supremo (Núcleo cheio) | T | P | RT |
| Sobrecarga / Explosão de Núcleo | G + H juntos | L + Ç juntos | Y + B juntos |
| Pausa | Esc | Esc | Start |

- **1 jogador** (Arcade, Contra CPU, Treino): qualquer controle comanda o Jogador 1.
- **2 jogadores**: o 1º controle é do Jogador 1 e o 2º do Jogador 2 (dá para trocar em **Opções > Controles J1 / J2**). Também dá para um jogar no teclado e o outro no controle.
- Nos menus: direcional/analógico para escolher, **A** confirma, **B** volta.

## Poderes e tipos
Cada botton tem 4 poderes, que saem com o botão de poder:
- **H** sozinho: poder neutro (quase sempre um ataque de longe).
- **→ + H** (para o lado do rival): poder da frente.
- **↑ + H**: poder de cima (bom contra pulos). Dá para apertar cima e, logo em seguida, o poder.
- **↓ + H**: poder de baixo (armadilhas e zonas no chão).

Cada poder tem seu próprio tempo de recarga, mostrado nos 4 ícones embaixo da barra de vida (o ícone escurece e volta a acender quando o poder está pronto). Na **Sobrecarga**, os poderes recarregam duas vezes mais rápido.

| Botton | Tipo | H (neutro) | → + H (frente) | ↑ + H (cima) | ↓ + H (baixo) | Supremo |
|---|---|---|---|---|---|---|
| PROTÓTIPO | Energia | **Orbe de Núcleo**: Esfera de energia que voa reto até o rival. | **Rajada Tripla**: Três orbes em leque: difícil de pular. | **Propulsor**: Sobe como um foguete. Invencível no começo. | **Mina de Núcleo**: Deixa uma mina no chão que explode quando o rival chega perto. | **SOBRECARGA TOTAL**: Um raio de energia que atravessa a arena inteira. |
| GUARDIÃO DAS CHAMAS | Fogo | **Bola de Fogo**: Uma bola de fogo com rastro de chamas. | **Investida Ígnea**: Avança envolto em chamas e arremessa o rival. | **Coluna de Fogo**: Uma coluna de fogo sobe à sua frente. Ótima contra pulos. | **Rastro de Brasas**: Deixa o chão em chamas por alguns segundos. | **ERUPÇÃO**: Colunas de fogo explodem do chão até o rival. |
| ENTIDADE DAS SOMBRAS | Sombra | **Esfera Sombria**: Uma esfera escura que ondula no ar. | **Passo Sombrio**: Some e reaparece atrás do rival com um golpe. | **Garras Sombrias**: Garras saem do chão embaixo do rival. | **Poço Sombrio**: Uma poça de sombra que deixa o rival lento. | **MIL SOMBRAS**: Sombras atacam o rival de todos os lados. |
| GUARDIÃO DA FLORESTA | Planta | **Folha Navalha**: Três folhas afiadas giram até o rival. | **Raízes Presas**: Raízes brotam do chão em fila e lançam o rival. | **Broto Gigante**: Um broto enorme sobe à sua frente. Ótimo contra pulos. | **Semente Bomba**: Arremessa uma semente que vira um espinheiro no chão. | **FÚRIA DA FLORESTA**: Uma árvore colossal nasce embaixo do rival. |
| ESPÍRITO DOS VENTOS | Vento | **Lâmina de Ar**: Uma lâmina de vento muito rápida. | **Tornado**: Um redemoinho lento que levanta o rival várias vezes. | **Rajada Ascendente**: Sobe girando com o vento. Invencível no começo. | **Corrente de Ar**: Uma ventania que empurra o rival para longe. | **CICLONE**: Um ciclone gigante varre a arena. |
| NÚCLEO DAS MARÉS | Água | **Hidro Jato**: Um jato de água muito rápido. | **Onda**: Uma onda corre pelo chão (dá para pular por cima). | **Gêiser**: Um gêiser explode embaixo do rival. | **Bolhas**: Três bolhas flutuam devagar e estouram no rival. | **TSUNAMI**: Uma onda enorme cobre a arena inteira. |
| CORAÇÃO GLACIAL | Gelo | **Lança de Gelo**: Projétil rápido que congela o rival por um instante. | **Rajada Glacial**: Um sopro de gelo de perto que congela. | **Pico de Gelo**: Um cristal de gelo sobe à sua frente. | **Chão Congelado**: Uma placa de gelo que congela quem pisar. | **ERA GLACIAL**: Cristais brotam pelo chão, congelam e estilhaçam. |
| RELÍQUIA SOLAR | Luz | **Disco Solar**: Um disco de luz que gira até o rival. | **Raio de Luz**: Um raio fino que cruza a arena num instante. | **Ascensão Solar**: Golpe para cima, invencível no início. Ótimo contra pulos. | **Clarão**: Uma explosão de luz em volta que deixa o rival tonto. | **JULGAMENTO SOLAR**: Raios de luz caem do céu sobre o rival. |
| COLOSSO DE PEDRA | Pedra | **Arremesso de Pedra**: Arremessa uma rocha enorme em arco. | **Avalanche**: Investida pesada que aguenta um golpe sem parar. | **Pilar de Pedra**: Um pilar de pedra sobe à sua frente. | **Pisão Sísmico**: Ondas de choque correm pelo chão (pule!). | **TERREMOTO**: Abala o chão inteiro (pule!) e faz chover pedras. |
| AUTÔMATO STEAMPUNK | Metal | **Engrenagem Serra**: Lança uma serra que vai e volta como bumerangue. | **Jato de Vapor**: Um jato de vapor de perto que empurra o rival. | **Martelo a Vapor**: Sobe com um golpe de pistão. Invencível no começo. | **Torreta**: Monta uma torreta que atira sozinha por um tempo. | **CANHÃO A VAPOR**: Uma rajada de balas de engrenagem. |
| VIAJANTE CÓSMICO | Cosmos | **Estrela Cadente**: Uma estrela cai do céu mirando no rival. | **Portal Estelar**: Entra num portal e cai em cima do rival. | **Anéis Planetários**: Anéis giram em volta e acertam quem chegar perto. | **Buraco Negro**: Um buraco negro que puxa o rival. | **CHUVA DE METEOROS**: Meteoros despencam do céu. |
| ALQUIMISTA PROIBIDO | Veneno | **Frasco Tóxico**: Arremessa um frasco que deixa uma nuvem venenosa. | **Bomba Ácida**: Um projétil ácido rápido que envenena. | **Gêiser Ácido**: Ácido jorra do chão à sua frente e envenena. | **Runa Proibida**: Uma runa no chão que explode quando o rival pisa. | **TRANSMUTAÇÃO**: Um círculo alquímico explode sob o rival. |

**Tipos** (poder ou supremo de um tipo forte contra o tipo do rival = +25% de dano e "É SUPER EFETIVO!"):

| Tipo | Forte contra | Fraco contra |
|---|---|---|
| Energia | Água, Metal | Pedra, Cosmos |
| Fogo | Planta, Gelo | Água, Pedra |
| Sombra | Luz, Cosmos | Vento, Luz |
| Planta | Água, Pedra | Fogo, Gelo, Veneno |
| Vento | Veneno, Sombra | Gelo |
| Água | Fogo, Pedra | Energia, Planta, Veneno |
| Gelo | Planta, Vento | Fogo, Metal |
| Luz | Sombra, Veneno | Sombra, Cosmos |
| Pedra | Energia, Fogo | Planta, Água, Metal |
| Metal | Gelo, Pedra | Energia |
| Cosmos | Luz, Energia | Sombra |
| Veneno | Planta, Água | Vento, Luz |

## Sistemas de luta
- **Braços animados**: cada botton tem corpo e braços separados, que socam, defendem, erguem e comemoram.
- **Combos**: leve → leve → pesado lança o rival para o ar; dá para continuar no ar e cancelar em poder ou supremo.
- **Defesa e PERFEITO**: segure a defesa. Apertar na hora exata em que o golpe chega faz um PERFEITO (sem dano, o atacante fica atordoado e você ganha Núcleo).
- **Núcleo**: enche ao bater, apanhar e defender.
  - **50%**: **Sobrecarga** (pesado + poder): 6 segundos com +20% de dano e velocidade e poderes recarregando mais rápido.
  - **50% apanhando**: **Explosão de Núcleo** (pesado + poder): escapa do combo e empurra o rival.
  - **100%**: **Supremo** com câmera cinematográfica e faixa estilo anime.
- **Choque de poderes**: projéteis que se encontram se anulam (supremos vencem).
- **Limite de combo**: golpes seguidos causam menos dano e, depois de muitos acertos no ar, o rival cai.
- **Efeitos**: congelamento, veneno, lentidão (Poço Sombrio), armadura (Avalanche), teleporte, armadilhas, torreta e buraco negro que puxa.

## Arenas
Santuário dos Núcleos, Cratera Ardente, Floresta Ancestral, Pico Congelado, Costa das Marés, Órbita Estelar e Fábrica a Vapor. Todas desenhadas por código, com música própria.

## Qualidade
- **Automática** (padrão): começa bonita e, se o computador não der conta, liga o modo leve sozinho (aparece um aviso).
- **Alta**: vidro com desfoque de verdade e todos os brilhos.
- **Leve**: vidro simples (sem ler a tela), menos partículas e brilhos. Para computadores bem fracos.

## Onde mexer
- `scripts/game.gd`: elenco (nomes, frases, cores, atributos, tipo, poderes e supremo), tipos, arenas, teclas, controles e opções.
- `scripts/powers.gd`: os 48 poderes (nome, descrição, tempos, recarga, dano e o que cada um solta na arena).
- `scripts/fighter.gd`: golpes (`MOVES`), escolha do poder pela direção, supremos (`_super_frame`) e poses dos braços (`P_...`).
- `scripts/fight.gd`: rounds, tempo, colisões, ataques soltos (projéteis, armadilhas, zonas), modos e menus.
- `scripts/hud.gd`: a interface da luta (vida, Núcleo, poderes, menus).
- `scripts/ai.gd`: a CPU.
- `scripts/arena_bg.gd`: os cenários.
- `scripts/fx.gd`: efeitos visuais e o desenho de cada poder.
- `scripts/glass.gd` e `assets/shaders/glass.gdshader`: o vidro líquido.
- `assets/chars/`: a arte original de cada botton. `assets/rig/`: corpo e braços separados.
- `tools/`: scripts em Python que geraram as músicas, os sons e a separação dos braços.

## Testes automáticos
- `godot --headless -- --mechtest`: testa combos, defesa, perfeito, sobrecarga, tipos, os 48 poderes, os 12 supremos e se a CPU usa os poderes.
- `godot --headless -- --padtest`: simula controles de videogame (botões, analógico, gatilhos, troca de controles).
- `godot --headless -- --autotest --fights=6`: CPU contra CPU em lutas aleatórias, Arcade e Treino.
- `godot -- --shots --shots=PASTA` (opcional `--so=telas|arenas|golpes`, `--leve`): tira prints de todas as telas, arenas e poderes.
- `godot -- --film --shots=PASTA`: filma uma luta CPU contra CPU (um print a cada 2 segundos).
- `godot --headless -s tests/tabela_readme.gd`: gera as tabelas de poderes e tipos deste arquivo.

## Gerar o .exe
No Godot: **Projeto > Exportar > Windows Desktop > Exportar Projeto** (o modelo de exportação do Godot precisa estar instalado; o próprio Godot oferece baixar).

## Créditos
Arte dos bottons: fichas originais do projeto. Fontes: Lilita One e Nunito (SIL Open Font License); setas e símbolos recortados da DejaVu Sans (veja `assets/fonts/LICENCA-BottonSimbolos.txt`).
