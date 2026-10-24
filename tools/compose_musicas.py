"""Compõe as músicas do BOTTON ARENA (rode: python3 compose.py pasta_saida [nome])."""
import sys, numpy as np
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from music import *

OUT = sys.argv[1] if len(sys.argv) > 1 else '.'
SO = sys.argv[2] if len(sys.argv) > 2 else None

def n(name):
    """'D5' -> midi"""
    nm = name[:-1]; o = int(name[-1])
    return 12 * (o + 1) + NOTE[nm]

def drums_basic(tr, bar, kick=(0, 2), snare=(1, 3), hats=8, crash=False, bus='drums', vel=1.0, open_hat=False):
    b0 = bar * 4
    for k in kick: tr.hit(bus, 'kick', b0 + k, 1.0 * vel)
    for s in snare: tr.hit(bus, 'snare', b0 + s, 0.85 * vel)
    if hats:
        step = 4 / hats
        for i in range(hats):
            tr.hit(bus, 'hat', b0 + i * step, (0.4 if i % 2 else 0.6) * vel)
    if open_hat:
        tr.hit(bus, 'ohat', b0 + 3.5, 0.5 * vel)
    if crash: tr.hit(bus, 'crash', b0, 0.9 * vel)

def pad_chords(tr, prog, octave=4, bus='pad', vel=0.8, bars_per=1):
    for i, ch in enumerate(prog):
        for m in chord(ch, octave):
            tr.note(bus, 'pad', i * 4 * bars_per, 4 * bars_per, m, vel)

def bass_line(tr, prog, pattern, octave=2, bus='bass', inst_name='bass', vel=0.9, oct_jump=False):
    for i, ch in enumerate(prog):
        r = chord(ch, octave)[0]
        for j, (pos, dur) in enumerate(pattern):
            m = r + (12 if oct_jump and j % 2 == 1 else 0)
            tr.note(bus, inst_name, i * 4 + pos, dur, m, vel)

def arp(tr, prog, octave=5, bus='arp', inst_name='arp', step=0.25, vel=0.6, shape=(0, 1, 2, 1), bars=None):
    for i, ch in enumerate(prog):
        if bars is not None and i not in bars: continue
        c = chord(ch, octave)
        c = c + [c[0] + 12]
        k = 0
        pos = 0.0
        while pos < 4 - 1e-6:
            m = c[shape[k % len(shape)] % len(c)]
            tr.note(bus, inst_name, i * 4 + pos, step * 0.9, m, vel)
            pos += step; k += 1

def play_mel(tr, mel, bus='lead', inst_name='lead', offset=0.0, vel=0.9, transp=0):
    for b, d, m in mel:
        tr.note(bus, inst_name, offset + b, d, m + transp, vel)

def hand_mel(spec, start=0.0):
    """spec: lista de compassos; cada compasso = lista de (nota|None, duração)"""
    out = []
    beat = start
    for bar in spec:
        pos = 0.0
        for nt, d in bar:
            if nt is not None:
                out.append((beat + pos, d * 0.95, n(nt)))
            pos += d
        beat += 4
    return out

# =================================================================== MENU
def t_menu():
    prog = ['D', 'A', 'Bm', 'G', 'D', 'A', 'G', 'A', 'Bm', 'G', 'D', 'A', 'G', 'A', 'D', 'D']
    tr = Track(112, len(prog))
    tr.bus('drums', 0.75, 0.0, 0.12); tr.bus('bass', 0.5, 0.0, 0.05); tr.bus('pad', 0.22, 0.0, 0.45)
    tr.bus('arp', 0.13, 0.35, 0.3); tr.bus('lead', 0.34, -0.05, 0.28, delay=0.75)
    pad_chords(tr, prog, 4)
    bass_line(tr, prog, [(0, 0.45), (1, 0.45), (1.5, 0.45), (2, 0.45), (3, 0.45), (3.5, 0.45)])
    arp(tr, prog, 5, bars=range(4, 16))
    for b in range(16):
        drums_basic(tr, b, kick=(0, 2, 2.5) if b % 4 == 3 else (0, 2), crash=b in (0, 8), open_hat=b % 2 == 1)
        if b % 4 == 3:
            for k in range(4): tr.hit('drums', 'tom', b * 4 + 3 + k * 0.25, 0.6)
    A = [[('F#5', 1), ('A5', 1), ('D6', 1.5), ('C#6', 0.5)], [('B5', 1), ('A5', 1), ('E5', 2)],
         [('F#5', 1), ('B5', 1), ('D6', 1), ('C#6', 1)], [('B5', 1.5), ('A5', 0.5), ('G5', 2)],
         [('F#5', 1), ('A5', 1), ('D6', 1.5), ('E6', 0.5)], [('F#6', 1), ('E6', 1), ('C#6', 2)],
         [('D6', 1), ('B5', 1), ('G5', 1), ('B5', 1)], [('A5', 3), (None, 1)],
         [('D6', 1.5), ('C#6', 0.5), ('B5', 1), ('F#5', 1)], [('G5', 1), ('B5', 1), ('D6', 2)],
         [('A5', 1.5), ('F#5', 0.5), ('A5', 1), ('D6', 1)], [('C#6', 1), ('E6', 1), ('A5', 2)],
         [('B5', 1), ('D6', 1), ('G6', 1.5), ('F#6', 0.5)], [('E6', 1), ('C#6', 1), ('A5', 1), ('E6', 1)],
         [('F#6', 2), ('E6', 1), ('D6', 1)], [('D6', 3), (None, 1)]]
    play_mel(tr, hand_mel(A))
    tr.render(f'{OUT}/menu.ogg')

# =================================================================== SELEÇÃO
def t_selecao():
    prog = ['Am', 'F', 'C', 'G', 'Am', 'F', 'C', 'E', 'Am', 'F', 'C', 'G', 'F', 'G', 'Am', 'E']
    tr = Track(124, len(prog))
    tr.bus('drums', 0.7, 0.0, 0.1); tr.bus('bass', 0.5, 0.0, 0.05); tr.bus('pluck', 0.2, -0.3, 0.25)
    tr.bus('arp', 0.12, 0.4, 0.3); tr.bus('lead', 0.3, 0.05, 0.25, delay=0.75)
    for b in range(16):
        drums_basic(tr, b, kick=(0, 1, 2, 3), snare=(), hats=0, crash=b in (0, 8))
        tr.hit('drums', 'clap', b * 4 + 1, 0.8); tr.hit('drums', 'clap', b * 4 + 3, 0.8)
        for k in range(4): tr.hit('drums', 'ohat', b * 4 + k + 0.5, 0.45)
    bass_line(tr, prog, [(0, 0.4), (0.75, 0.2), (1.5, 0.4), (2.5, 0.4), (3.25, 0.2), (3.5, 0.4)], oct_jump=True)
    for i, ch in enumerate(prog):
        for pos in (0.5, 1.5, 2.5, 3.5):
            for m in chord(ch, 4): tr.note('pluck', 'pluck', i * 4 + pos, 0.25, m, 0.5)
    arp(tr, prog, 5, step=0.25, shape=(0, 2, 1, 3), bars=range(8, 16))
    mel = melody(prog, scale('A', 'menor'), None, lo=69, hi=84, seed=21)
    play_mel(tr, mel)
    tr.render(f'{OUT}/selecao.ogg')

# =================================================================== LUTA 1 (Santuário)
def t_luta1():
    A = ['Em', 'C', 'D', 'B', 'Em', 'C', 'Am', 'B']
    B = ['C', 'D', 'Em', 'Em', 'C', 'D', 'B', 'B']
    prog = A + A + B + A
    tr = Track(150, len(prog))
    tr.bus('drums', 0.75, 0.0, 0.08); tr.bus('bass', 0.48, 0.0, 0.03); tr.bus('power', 0.24, -0.25, 0.12)
    tr.bus('arp', 0.11, 0.35, 0.25); tr.bus('lead', 0.32, 0.1, 0.22, delay=0.75); tr.bus('pad', 0.12, 0.0, 0.4)
    for i, ch in enumerate(prog):
        r = chord(ch, 3)[0]
        for k in range(8):
            if k in (3, 7) and i % 2 == 1: continue
            tr.note('power', 'power', i * 4 + k * 0.5, 0.4, r, 0.9 if k % 2 == 0 else 0.7)
        sec_b = 16 <= i < 24
        drums_basic(tr, i, kick=(0, 0.5, 2, 2.5) if sec_b else (0, 1.5, 2), crash=i % 8 == 0)
        if i % 8 == 7:
            for k in range(8): tr.hit('drums', 'tom' if k < 6 else 'snare', i * 4 + 2 + k * 0.25, 0.7)
    bass_line(tr, prog, [(k * 0.5, 0.42) for k in range(8)])
    pad_chords(tr, prog, 4, vel=0.6)
    arp(tr, prog, 5, step=0.25, shape=(0, 1, 2, 3, 2, 1), bars=list(range(8, 16)) + list(range(24, 32)))
    hook = hand_mel([[('E5', 1), ('G5', 0.5), ('B5', 1), ('E6', 1.5)], [('D6', 1), ('C6', 1), ('G5', 2)],
                     [('A5', 1), ('D6', 1), ('F#6', 1.5), ('E6', 0.5)], [('D#6', 2), ('B5', 2)],
                     [('E6', 0.5), ('D6', 0.5), ('B5', 1), ('G5', 1), ('E5', 1)], [('G5', 1), ('C6', 1), ('E6', 2)],
                     [('C6', 1), ('A5', 1), ('E5', 1), ('A5', 1)], [('B5', 2), ('D#6', 1), ('F#6', 1)]])
    play_mel(tr, hook, offset=0)
    play_mel(tr, hook, offset=32, transp=0)
    melB = melody(B, scale('E', 'harm'), None, lo=71, hi=90, seed=7)
    play_mel(tr, melB, offset=64)
    play_mel(tr, hook, offset=96, transp=12, vel=0.75)
    tr.render(f'{OUT}/luta1.ogg')

# =================================================================== LUTA 2 (Vulcão)
def t_luta2():
    prog = ['Dm', 'Dm', 'Bb', 'C', 'Dm', 'Dm', 'Gm', 'A', 'Bb', 'C', 'Dm', 'Dm', 'Gm', 'A', 'Dm', 'A']
    tr = Track(140, len(prog))
    tr.bus('drums', 0.8, 0.0, 0.1); tr.bus('bass', 0.5, 0.0, 0.03); tr.bus('power', 0.3, 0.0, 0.12)
    tr.bus('lead', 0.32, 0.1, 0.25, delay=0.5)
    for i, ch in enumerate(prog):
        r = chord(ch, 3)[0]
        for pos, d in ((0, 0.4), (0.75, 0.2), (1.0, 0.4), (1.5, 0.4), (2.5, 0.4), (3.0, 0.4), (3.5, 0.4)):
            tr.note('power', 'power', i * 4 + pos, d, r, 1.0)
        drums_basic(tr, i, kick=(0, 0.75, 1.5, 2, 2.75), snare=(1, 3), hats=8, crash=i % 4 == 0)
        if i % 4 == 3:
            for k in range(4): tr.hit('drums', 'tom', i * 4 + 3 + k * 0.25, 0.8)
    bass_line(tr, prog, [(0, 0.4), (0.75, 0.2), (1.0, 0.4), (1.5, 0.4), (2.5, 0.4), (3.0, 0.4), (3.5, 0.4)], oct_jump=True)
    mel = melody(prog, scale('D', 'harm'), None, lo=62, hi=81, seed=33,
                 ritmos=[[1.5, 0.5, 2], [1, 1, 1, 1], [0.5, 0.5, 1, 2], [2, 1.5, 0.5]])
    play_mel(tr, mel, inst_name='brass', vel=0.95)
    tr.render(f'{OUT}/luta2.ogg')

# =================================================================== LUTA 3 (Floresta / Costa)
def t_luta3():
    prog = ['G', 'Em', 'C', 'D', 'G', 'Em', 'C', 'D', 'Em', 'C', 'G', 'D', 'Em', 'C', 'D', 'D']
    tr = Track(136, len(prog))
    tr.bus('drums', 0.65, 0.0, 0.12); tr.bus('bass', 0.48, 0.0, 0.05); tr.bus('pluck', 0.2, -0.35, 0.3)
    tr.bus('bell', 0.14, 0.4, 0.35); tr.bus('lead', 0.3, 0.0, 0.3, delay=0.75); tr.bus('pad', 0.14, 0, 0.45)
    for i, ch in enumerate(prog):
        drums_basic(tr, i, kick=(0, 1.5, 2.5), snare=(1, 3), hats=0, crash=i % 8 == 0)
        for k in range(16): tr.hit('drums', 'shaker', i * 4 + k * 0.25, 0.6 if k % 2 else 0.9)
    arp(tr, prog, 4, bus='pluck', inst_name='pluck', step=0.5, shape=(0, 1, 2, 3, 2, 1, 0, 2), vel=0.7)
    arp(tr, prog, 6, bus='bell', inst_name='bell', step=1.0, shape=(2, 1, 0, 1), vel=0.5, bars=range(8, 16))
    bass_line(tr, prog, [(0, 0.9), (1.5, 0.4), (2, 0.9), (3.5, 0.4)])
    pad_chords(tr, prog, 4, vel=0.5)
    mel = melody(prog, scale('G', 'penta'), None, lo=67, hi=86, seed=5)
    play_mel(tr, mel)
    tr.render(f'{OUT}/luta3.ogg')

# =================================================================== LUTA 4 (Glacial)
def t_luta4():
    prog = ['F#m', 'D', 'A', 'E', 'F#m', 'D', 'A', 'E', 'Bm', 'D', 'F#m', 'E', 'Bm', 'D', 'E', 'E']
    tr = Track(144, len(prog))
    tr.bus('drums', 0.7, 0.0, 0.12); tr.bus('bass', 0.48, 0.0, 0.05); tr.bus('glass', 0.18, 0.3, 0.45)
    tr.bus('pad', 0.18, 0.0, 0.5); tr.bus('lead', 0.3, -0.1, 0.3, delay=0.75)
    for i, ch in enumerate(prog):
        drums_basic(tr, i, kick=(0, 1.75, 2.5), snare=(1, 3), hats=16 if i >= 8 else 8, crash=i % 8 == 0)
    arp(tr, prog, 5, bus='glass', inst_name='glass', step=0.25, shape=(0, 1, 2, 3, 2, 1), vel=0.6)
    pad_chords(tr, prog, 4, vel=0.7)
    bass_line(tr, prog, [(k * 0.5, 0.42) for k in range(8)], oct_jump=True)
    mel = melody(prog, scale('F#', 'menor'), None, lo=66, hi=85, seed=14)
    play_mel(tr, mel)
    tr.render(f'{OUT}/luta4.ogg')

# =================================================================== LUTA 5 (Cosmos)
def t_luta5():
    prog = ['Cm', 'Ab', 'Eb', 'Bb', 'Cm', 'Ab', 'Eb', 'G', 'Ab', 'Bb', 'Cm', 'Cm', 'Ab', 'Bb', 'G', 'G']
    tr = Track(128, len(prog))
    tr.bus('drums', 0.72, 0.0, 0.25); tr.bus('bass', 0.5, 0.0, 0.05); tr.bus('arp', 0.15, 0.35, 0.35)
    tr.bus('pad', 0.2, 0.0, 0.5); tr.bus('lead', 0.32, -0.1, 0.35, delay=0.75)
    for i, ch in enumerate(prog):
        drums_basic(tr, i, kick=(0, 1, 2, 3), snare=(1, 3), hats=8, crash=i % 8 == 0)
        tr.hit('drums', 'clap', i * 4 + 1, 0.6); tr.hit('drums', 'clap', i * 4 + 3, 0.6)
        for k in range(8):   # pad "cortado" (gate)
            for m in chord(ch, 4): tr.note('pad', 'pad', i * 4 + k * 0.5, 0.35, m, 0.5)
    arp(tr, prog, 4, step=0.25, shape=(0, 3, 1, 3, 2, 3, 1, 3), vel=0.6)
    bass_line(tr, prog, [(k * 0.5, 0.4) for k in range(8)], oct_jump=True)
    mel = melody(prog, scale('C', 'menor'), None, lo=67, hi=84, seed=42, ritmos=[[2, 1, 1], [1.5, 1.5, 1], [1, 1, 2], [3, 1]])
    play_mel(tr, mel)
    tr.render(f'{OUT}/luta5.ogg')

# =================================================================== LUTA 6 (Fábrica)
def t_luta6():
    prog = ['Am', 'Dm', 'E', 'Am', 'Am', 'Dm', 'E', 'E', 'F', 'G', 'Am', 'Am', 'Dm', 'E', 'Am', 'E']
    tr = Track(138, len(prog))
    tr.bus('drums', 0.72, 0.0, 0.1); tr.bus('bass', 0.5, 0.0, 0.05); tr.bus('brass', 0.22, -0.3, 0.2)
    tr.bus('lead', 0.3, 0.15, 0.25, delay=0.5); tr.bus('organ', 0.12, 0.3, 0.3)
    for i, ch in enumerate(prog):
        drums_basic(tr, i, kick=(0, 2, 2.75), snare=(1, 3), hats=0, crash=i % 8 == 0)
        for k in range(8): tr.hit('drums', 'tick' if k % 2 == 0 else 'tock', i * 4 + k * 0.5, 0.7)
        for pos in (0.5, 1.5, 2.5, 3.5):
            for m in chord(ch, 4): tr.note('brass', 'brass', i * 4 + pos, 0.22, m, 0.6)
    bass_line(tr, prog, [(0, 0.45), (1, 0.45), (2, 0.45), (3, 0.45)], inst_name='bass')
    pad_chords(tr, prog, 3, bus='organ', vel=0.5)
    mel = melody(prog, scale('A', 'harm'), None, lo=64, hi=84, seed=8, ritmos=[[0.5, 0.5, 1, 2], [1, 0.5, 0.5, 1, 1], [0.75, 0.75, 0.5, 2]])
    play_mel(tr, mel, inst_name='lead')
    tr.render(f'{OUT}/luta6.ogg')

# =================================================================== VITÓRIA (fanfarra curta)
def t_vitoria():
    tr = Track(120, 3)
    tr.bus('brass', 0.4, 0.0, 0.3); tr.bus('drums', 0.7, 0.0, 0.2); tr.bus('pad', 0.25, 0, 0.5)
    seq = [('C5', 0, 0.5), ('E5', 0.5, 0.5), ('G5', 1.0, 0.5), ('C6', 1.5, 1.0), ('G5', 2.5, 0.5), ('C6', 3.0, 5.0)]
    for nt, b, d in seq: tr.note('brass', 'brass', b, d, n(nt), 1.0)
    for m in chord('C', 4): tr.note('brass', 'brass', 3.0, 5.0, m, 0.7)
    for m in chord('C', 3): tr.note('pad', 'pad', 3.0, 5.0, m, 0.8)
    for k in range(6): tr.hit('drums', 'tom', 1.5 + k * 0.25, 0.8)
    tr.hit('drums', 'crash', 3.0, 1.0); tr.hit('drums', 'kick', 3.0, 1.0)
    # sem loop: renderiza com cauda
    L = None
    tr.n = int(tr.beats * tr.spb * SR) + SR * 2
    for k in tr.buses: tr.buses[k] = np.concatenate([tr.buses[k], np.zeros(SR * 2)])
    tr.render(f'{OUT}/vitoria.ogg', master=0.85)

# =================================================================== FIM (Arcade concluído)
def t_fim():
    prog = ['D', 'Bm', 'G', 'A', 'D', 'Bm', 'G', 'A', 'G', 'A', 'F#m', 'Bm', 'G', 'A', 'D', 'D']
    tr = Track(96, len(prog))
    tr.bus('piano', 0.35, -0.1, 0.4); tr.bus('pad', 0.2, 0.0, 0.5); tr.bus('lead', 0.26, 0.1, 0.4, delay=0.75)
    tr.bus('drums', 0.45, 0, 0.2); tr.bus('bass', 0.35, 0, 0.1)
    arp(tr, prog, 4, bus='piano', inst_name='piano', step=0.5, shape=(0, 1, 2, 3, 2, 1, 2, 1), vel=0.7)
    pad_chords(tr, prog, 3, vel=0.6)
    bass_line(tr, prog, [(0, 1.8), (2, 1.8)], octave=2, inst_name='sub')
    for b in range(4, 16): drums_basic(tr, b, kick=(0, 2.5), snare=(2,), hats=4, vel=0.7)
    A = [[('F#5', 1), ('A5', 1), ('D6', 1.5), ('C#6', 0.5)], [('B5', 2), ('F#5', 2)],
         [('G5', 1), ('B5', 1), ('D6', 1), ('B5', 1)], [('A5', 3), (None, 1)],
         [('F#5', 1), ('A5', 1), ('D6', 1.5), ('E6', 0.5)], [('F#6', 2), ('D6', 2)],
         [('B5', 1), ('D6', 1), ('G6', 1), ('F#6', 1)], [('E6', 3), (None, 1)],
         [('D6', 1), ('B5', 1), ('G5', 2)], [('A5', 1), ('C#6', 1), ('E6', 2)],
         [('F#6', 1.5), ('E6', 0.5), ('C#6', 2)], [('D6', 1), ('B5', 1), ('F#5', 2)],
         [('G5', 1), ('B5', 1), ('D6', 1), ('G6', 1)], [('F#6', 1), ('E6', 1), ('C#6', 2)],
         [('D6', 4)], [(None, 4)]]
    play_mel(tr, hand_mel(A), vel=0.8)
    tr.render(f'{OUT}/fim.ogg')

TRACKS = {'menu': t_menu, 'selecao': t_selecao, 'luta1': t_luta1, 'luta2': t_luta2, 'luta3': t_luta3,
          'luta4': t_luta4, 'luta5': t_luta5, 'luta6': t_luta6, 'vitoria': t_vitoria, 'fim': t_fim}
for k, f in TRACKS.items():
    if SO is None or SO == k:
        f()
