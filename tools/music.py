"""Sintetizador simples para as músicas do BOTTON ARENA.
Gera trilhas em loop (OGG) a partir de progressões, padrões e melodias.
"""
import numpy as np, wave, subprocess, os, sys
from scipy.signal import lfilter, fftconvolve

SR = 44100
rng = np.random.default_rng(11)

def mtof(m): return 440.0 * 2 ** ((m - 69) / 12.0)

# ---------------------------------------------------------------- osciladores (tabelas de onda sem aliasing)
_tables = {}
def table(kind, K):
    key = (kind, K)
    if key in _tables: return _tables[key]
    N = 2048
    ph = np.arange(N) / N
    w = np.zeros(N)
    for k in range(1, K + 1):
        if kind == 'saw': w += ((-1) ** (k + 1)) * np.sin(2 * np.pi * k * ph) / k
        elif kind == 'square' and k % 2 == 1: w += np.sin(2 * np.pi * k * ph) / k
        elif kind == 'tri' and k % 2 == 1: w += ((-1) ** ((k - 1) // 2)) * np.sin(2 * np.pi * k * ph) / (k * k)
    w /= np.max(np.abs(w)) + 1e-9
    _tables[key] = w
    return w

def osc(kind, f, n, ph0=0.0, vib=0.0, vib_rate=5.5, vib_delay=0.2):
    t = np.arange(n) / SR
    if kind == 'sine':
        freq = f * (1 + vib * np.sin(2 * np.pi * vib_rate * t) * np.clip((t - vib_delay) * 4, 0, 1))
        return np.sin(2 * np.pi * np.cumsum(freq) / SR + ph0)
    K = max(1, min(40, int((SR / 2) / max(f, 1.0) * 0.9)))
    tb = table(kind, K)
    freq = f * (1 + vib * np.sin(2 * np.pi * vib_rate * t) * np.clip((t - vib_delay) * 4, 0, 1))
    phase = (np.cumsum(freq) / SR + ph0) % 1.0
    idx = phase * len(tb)
    i0 = idx.astype(int) % len(tb)
    i1 = (i0 + 1) % len(tb)
    fr = idx - np.floor(idx)
    return tb[i0] * (1 - fr) + tb[i1] * fr

def pulse(f, n, width=0.25):
    a = osc('saw', f, n)
    b = osc('saw', f, n, ph0=width)
    return (a - b) * 0.5

def adsr(n, a=0.01, d=0.1, s=0.7, r=0.1, hold=None):
    """envelope de n amostras; hold = amostras até soltar a nota"""
    if hold is None: hold = n
    e = np.zeros(n)
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    i = np.arange(n)
    e = np.where(i < na, i / max(1, na), 1.0)
    dec = np.clip((i - na) / max(1, nd), 0, 1)
    e = np.where(i >= na, 1 - (1 - s) * dec, e)
    rel = np.clip((i - hold) / max(1, nr), 0, 1)
    e = e * np.where(i >= hold, 1 - rel, 1.0)
    return e

def lowpass(x, fc):
    fc = min(fc, SR * 0.45)
    a = np.exp(-2 * np.pi * fc / SR)
    return lfilter([1 - a], [1, -a], x)

def highpass(x, fc):
    return x - lowpass(x, fc)

def lowpass_env(x, f0, f1, tau):
    """filtro com cutoff que cai de f0 para f1 (aprox. em blocos)"""
    out = np.zeros_like(x)
    blk = 256
    state = 0.0
    for s0 in range(0, len(x), blk):
        tt = s0 / SR
        fc = f1 + (f0 - f1) * np.exp(-tt / tau)
        a = np.exp(-2 * np.pi * min(fc, SR * 0.45) / SR)
        seg = x[s0:s0 + blk]
        y, zf = lfilter([1 - a], [1, -a], seg, zi=[state * a])
        out[s0:s0 + blk] = y
        state = y[-1] / a if a > 0 else 0.0
        state = y[-1]
        # zi espera estado interno; aproximação suficiente para música
    return out

# ---------------------------------------------------------------- instrumentos
def inst(name, midi, dur, vel=1.0):
    f = mtof(midi)
    hold = int(dur * SR)
    tail = {'pad': 0.6, 'lead': 0.18, 'bass': 0.06, 'pluck': 0.25, 'arp': 0.12, 'bell': 0.9, 'brass': 0.15,
            'power': 0.1, 'piano': 0.8, 'sub': 0.05, 'glass': 0.6, 'organ': 0.15}.get(name, 0.1)
    n = hold + int(tail * SR)
    if name == 'lead':
        x = 0.6 * osc('saw', f, n, vib=0.006) + 0.4 * osc('square', f * 1.003, n, vib=0.006)
        x = lowpass(x, 3200 + 1500 * vel)
        x *= adsr(n, 0.008, 0.12, 0.75, 0.16, hold)
    elif name == 'pluck':
        x = 0.7 * osc('saw', f, n) + 0.3 * osc('square', f * 2, n)
        x = lowpass_env(x, 5200, 600, 0.12)
        x *= adsr(n, 0.003, 0.25, 0.25, 0.2, hold)
    elif name == 'arp':
        x = pulse(f, n, 0.25)
        x = lowpass(x, 3600)
        x *= adsr(n, 0.002, 0.09, 0.2, 0.08, hold)
    elif name == 'pad':
        x = sum(osc('saw', f * d, n, ph0=rng.random()) for d in (0.995, 1.0, 1.006)) / 3
        x = lowpass(x, 1300)
        x *= adsr(n, 0.25, 0.4, 0.8, 0.55, hold)
    elif name == 'bass':
        x = 0.7 * osc('saw', f, n) + 0.6 * osc('sine', f, n)
        x = lowpass_env(x, 1400, 380, 0.08)
        x *= adsr(n, 0.004, 0.12, 0.7, 0.05, hold)
    elif name == 'sub':
        x = osc('sine', f, n) + 0.3 * osc('tri', f * 2, n)
        x *= adsr(n, 0.004, 0.2, 0.8, 0.05, hold)
    elif name == 'bell':
        t = np.arange(n) / SR
        mod = np.sin(2 * np.pi * f * 3.5 * t) * 2.2 * np.exp(-t * 3)
        x = np.sin(2 * np.pi * f * t + mod) * np.exp(-t * 2.2)
        x *= adsr(n, 0.002, 0.05, 1.0, 0.6, hold)
    elif name == 'glass':
        t = np.arange(n) / SR
        x = (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.01 * t) * np.exp(-t * 4)) * np.exp(-t * 1.6)
        x *= adsr(n, 0.004, 0.05, 1.0, 0.5, hold)
    elif name == 'brass':
        x = osc('saw', f, n, vib=0.004)
        env = adsr(n, 0.04, 0.15, 0.7, 0.12, hold)
        x = lowpass(x, 900 + 2200 * vel) * env
    elif name == 'power':
        x = sum(osc('saw', f * r, n, ph0=rng.random()) * g for r, g in ((1, 1), (1.4983, 0.7), (2, 0.5), (0.5, 0.5)))
        x = np.tanh(x * 2.2) * 0.6
        x = lowpass(x, 2600)
        x *= adsr(n, 0.004, 0.1, 0.8, 0.08, hold)
    elif name == 'piano':
        t = np.arange(n) / SR
        x = sum(np.sin(2 * np.pi * f * k * t) * np.exp(-t * (1.8 + k * 1.2)) / k for k in range(1, 6))
        x *= adsr(n, 0.003, 0.05, 1.0, 0.5, hold)
    elif name == 'organ':
        x = sum(osc('sine', f * k, n) * g for k, g in ((1, 1), (2, 0.5), (3, 0.3), (4, 0.2)))
        x = lowpass(x, 3000) * adsr(n, 0.02, 0.1, 0.8, 0.1, hold)
    else:
        x = osc('sine', f, n) * adsr(n, 0.01, 0.1, 0.7, 0.1, hold)
    return x * vel

# ---------------------------------------------------------------- bateria
_drums = {}
def drum(name):
    if name in _drums: return _drums[name]
    if name == 'kick':
        n = int(0.35 * SR); t = np.arange(n) / SR
        f = 45 + 110 * np.exp(-t * 28)
        x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7)
        x[:200] += rng.uniform(-0.5, 0.5, 200) * np.linspace(1, 0, 200)
        x = np.tanh(x * 1.6)
    elif name == 'snare':
        n = int(0.25 * SR); t = np.arange(n) / SR
        noise = highpass(rng.uniform(-1, 1, n), 1200) * np.exp(-t * 18)
        tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 22)
        x = noise * 0.8 + tone * 0.6
    elif name == 'clap':
        n = int(0.22 * SR); t = np.arange(n) / SR
        env = np.exp(-t * 20)
        for d in (0.0, 0.012, 0.024):
            env += (t >= d) * np.exp(-np.clip(t - d, 0, None) * 120) * 0.6
        x = highpass(lowpass(rng.uniform(-1, 1, n), 5000), 900) * env * 0.7
    elif name == 'hat':
        n = int(0.06 * SR); t = np.arange(n) / SR
        x = highpass(rng.uniform(-1, 1, n), 7000) * np.exp(-t * 70) * 0.5
    elif name == 'ohat':
        n = int(0.3 * SR); t = np.arange(n) / SR
        x = highpass(rng.uniform(-1, 1, n), 6500) * np.exp(-t * 9) * 0.4
    elif name == 'crash':
        n = int(1.6 * SR); t = np.arange(n) / SR
        x = highpass(rng.uniform(-1, 1, n), 4500) * np.exp(-t * 2.4) * 0.45
    elif name == 'tom':
        n = int(0.4 * SR); t = np.arange(n) / SR
        f = 90 + 60 * np.exp(-t * 15)
        x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 8) * 0.9
    elif name == 'tick':
        n = int(0.04 * SR); t = np.arange(n) / SR
        x = np.sin(2 * np.pi * 2200 * t) * np.exp(-t * 120) * 0.6
    elif name == 'tock':
        n = int(0.06 * SR); t = np.arange(n) / SR
        x = np.sin(2 * np.pi * 900 * t) * np.exp(-t * 80) * 0.7
    elif name == 'shaker':
        n = int(0.08 * SR); t = np.arange(n) / SR
        x = highpass(rng.uniform(-1, 1, n), 5000) * np.sin(np.pi * t / 0.08) * 0.3
    else:
        x = np.zeros(10)
    _drums[name] = x
    return x

# ---------------------------------------------------------------- mixagem
class Track:
    def __init__(self, bpm, bars, beats_per_bar=4):
        self.bpm = bpm
        self.spb = 60.0 / bpm
        self.beats = bars * beats_per_bar
        self.n = int(self.beats * self.spb * SR)
        self.buses = {}
        self.cfg = {}

    def bus(self, name, gain=1.0, pan=0.0, rev=0.2, delay=0.0):
        if name not in self.buses:
            self.buses[name] = np.zeros(self.n + 4 * SR)
            self.cfg[name] = (gain, pan, rev, delay)
        return self.buses[name]

    def note(self, busname, instname, beat, dur, midi, vel=1.0):
        b = self.buses[busname]
        x = inst(instname, midi, dur * self.spb, vel)
        s = int(beat * self.spb * SR)
        e = min(len(b), s + len(x))
        b[s:e] += x[:e - s]

    def hit(self, busname, name, beat, vel=1.0):
        b = self.buses[busname]
        x = drum(name) * vel
        s = int(beat * self.spb * SR)
        e = min(len(b), s + len(x))
        b[s:e] += x[:e - s]

    def render(self, path, master=0.9):
        L = np.zeros(self.n + 4 * SR)
        R = np.zeros(self.n + 4 * SR)
        revL = np.zeros_like(L)
        revR = np.zeros_like(R)
        for name, b in self.buses.items():
            g, pan, rev, dly = self.cfg[name]
            x = b * g
            if dly > 0:
                d = int(dly * self.spb * SR)
                y = x.copy()
                for k in range(1, 4):
                    sh = np.zeros_like(x); sh[d * k:] = x[:-d * k] * (0.35 ** k)
                    y += sh
                x = y
            gl = np.cos((pan + 1) * np.pi / 4); gr = np.sin((pan + 1) * np.pi / 4)
            L += x * gl; R += x * gr
            revL += x * gl * rev; revR += x * gr * rev
        # reverb: impulso de ruído decaindo
        n_ir = int(1.4 * SR)
        t = np.arange(n_ir) / SR
        irL = rng.uniform(-1, 1, n_ir) * np.exp(-t * 3.2); irR = rng.uniform(-1, 1, n_ir) * np.exp(-t * 3.2)
        irL = lowpass(irL, 5000); irR = lowpass(irR, 5000)
        irL /= np.sqrt(np.sum(irL ** 2)); irR /= np.sqrt(np.sum(irR ** 2))
        L += fftconvolve(revL, irL)[:len(L)] * 0.5
        R += fftconvolve(revR, irR)[:len(R)] * 0.5
        # loop sem emenda: o que passa do fim volta para o começo
        loopL = L[:self.n].copy(); loopR = R[:self.n].copy()
        tailL = L[self.n:]; tailR = R[self.n:]
        k = min(len(tailL), self.n)
        loopL[:k] += tailL[:k]; loopR[:k] += tailR[:k]
        loopL = loopL - 0.25 * highpass(loopL, 9000); loopR = loopR - 0.25 * highpass(loopR, 9000)
        st = np.stack([loopL, loopR], axis=1)
        st = np.tanh(st * 1.1) / np.tanh(1.1)
        st = st / (np.max(np.abs(st)) + 1e-9) * master
        write_ogg(path, st)

def write_ogg(path, st, loop=True):
    wav = path.replace('.ogg', '.wav')
    d = (np.clip(st, -1, 1) * 32000).astype(np.int16)
    w = wave.open(wav, 'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes()); w.close()
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '4', path], check=True)
    os.remove(wav)
    print('ok', path, round(len(st) / SR, 1), 's')

# ---------------------------------------------------------------- teoria
NOTE = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11}
def chord(name, octave=4):
    """'Am', 'F', 'G7', 'Bdim' -> lista de notas midi"""
    root = name[0] + (name[1] if len(name) > 1 and name[1] in '#b' else '')
    q = name[len(root):]
    r = 12 * (octave + 1) + NOTE[root]
    if q.startswith('m') and not q.startswith('maj'): iv = [0, 3, 7]
    elif q.startswith('dim'): iv = [0, 3, 6]
    elif q.startswith('sus'): iv = [0, 5, 7]
    else: iv = [0, 4, 7]
    if '7' in q: iv = iv + ([11] if 'maj' in q else [10])
    return [r + i for i in iv]

def scale(root, kind):
    steps = {'maior': [0, 2, 4, 5, 7, 9, 11], 'menor': [0, 2, 3, 5, 7, 8, 10], 'harm': [0, 2, 3, 5, 7, 8, 11],
             'penta': [0, 2, 4, 7, 9], 'dor': [0, 2, 3, 5, 7, 9, 10]}[kind]
    base = NOTE[root]
    out = []
    for o in range(2, 8):
        for s in steps: out.append(12 * (o + 1) + base + s)
    return sorted(out)

def nearest(notes, target):
    return min(notes, key=lambda n: abs(n - target))

def melody(prog, sc, rng_m, bars_per_chord=1, lo=67, hi=86, ritmos=None, seed=0):
    """Melodia com motivo + variação: retorna [(beat, dur, midi)]"""
    r = np.random.default_rng(seed)
    if ritmos is None:
        ritmos = [[1, 1, 1, 1], [1.5, 0.5, 1, 1], [0.5, 0.5, 1, 2], [1, 0.5, 0.5, 2], [0.75, 0.75, 0.5, 2], [2, 1, 1], [0.5, 0.5, 0.5, 0.5, 2]]
    motif_r = [ritmos[r.integers(len(ritmos))] for _ in range(2)]
    out = []
    beat = 0.0
    cur = (lo + hi) // 2
    pool = [n for n in sc if lo <= n <= hi]
    motif_shape = list(r.integers(-2, 3, size=8))
    for bi, ch in enumerate(prog):
        tones = [n for n in pool if (n % 12) in [c % 12 for c in chord(ch)]]
        rit = motif_r[bi % 2] if bi % 4 != 3 else [2, 2] if bi % 8 == 7 else motif_r[0]
        if bi % 8 == 7: rit = [1, 1, 2]
        pos = 0.0
        for k, d in enumerate(rit):
            strong = pos in (0.0, 2.0)
            if strong or d >= 2:
                cur = nearest(tones, cur + motif_shape[k % len(motif_shape)] * 2)
            else:
                idx = pool.index(nearest(pool, cur))
                step = int(motif_shape[(k + bi) % len(motif_shape)])
                step = step if step != 0 else (1 if r.random() < 0.5 else -1)
                cur = pool[max(0, min(len(pool) - 1, idx + step))]
            if bi == len(prog) - 1 and k == len(rit) - 1:
                cur = nearest(tones, cur)
            out.append((beat + pos, d * 0.92, cur))
            pos += d
        beat += 4 * bars_per_chord
    return out
