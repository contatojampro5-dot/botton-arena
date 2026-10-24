"""Efeitos sonoros do BOTTON ARENA (sintetizados). Uso: python3 sfx2.py pasta"""
import numpy as np, wave, sys
from scipy.signal import lfilter

SR = 22050
OUT = sys.argv[1]
rng = np.random.default_rng(5)

def save(n, x, peak=0.9):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    d = (np.clip(x, -1, 1) * 32000).astype(np.int16)
    w = wave.open(f'{OUT}/{n}.wav', 'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes()); w.close()

def t(d): return np.arange(int(SR * d)) / SR
def noise(d): return rng.uniform(-1, 1, int(SR * d))
def lp(x, fc):
    a = np.exp(-2 * np.pi * fc / SR); return lfilter([1 - a], [1, -a], x)
def hp(x, fc): return x - lp(x, fc)
def bp(x, lo, hi): return hp(lp(x, hi), lo)
def env(n, a, r):
    i = np.arange(n) / SR
    return np.minimum(1, i / max(a, 1e-4)) * np.exp(-i * r)
def sweep(f0, f1, d, kind='sin', curve=1.0):
    tt = t(d); k = (tt / d) ** curve
    f = f0 + (f1 - f0) * k
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == 'sin': return np.sin(ph)
    if kind == 'saw': return 2 * ((ph / (2 * np.pi)) % 1) - 1
    if kind == 'sq': return np.sign(np.sin(ph))
    if kind == 'tri': return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1) - 1) - 1

def fit(*xs):
    n = max(len(x) for x in xs); out = np.zeros(n)
    for x in xs: out[:len(x)] += x
    return out

# --- golpes
d = 0.14; x = fit(lp(noise(d), 4000) * env(int(SR * d), 0.001, 30) * 0.8, sweep(260, 90, d) * env(int(SR * d), 0.001, 22) * 0.9)
save('hit_light', np.tanh(x * 1.5))
d = 0.3; x = fit(lp(noise(d), 2500) * env(int(SR * d), 0.001, 16), sweep(160, 45, d, curve=0.5) * env(int(SR * d), 0.001, 11) * 1.2,
               hp(noise(0.04), 3000) * 0.6)
save('hit_heavy', np.tanh(x * 2.0))
d = 0.16; x = fit(sweep(1500, 1300, d, 'tri') * env(int(SR * d), 0.001, 25) * 0.5, sweep(2600, 2500, d) * env(int(SR * d), 0.001, 30) * 0.4,
               bp(noise(d), 1500, 6000) * env(int(SR * d), 0.001, 40) * 0.6)
save('block', x)
d = 0.2; x = bp(noise(d), 600, 3500) * np.sin(np.pi * t(d) / d) ** 2
save('whoosh', x, 0.6)
d = 0.4; x = fit(sweep(300, 900, d, 'saw', 0.6) * env(int(SR * d), 0.01, 6) * 0.4, sweep(450, 1350, d, 'sin', 0.6) * env(int(SR * d), 0.01, 6) * 0.5,
               bp(noise(d), 1000, 6000) * env(int(SR * d), 0.02, 8) * 0.3)
save('special', lp(x, 6000), 0.75)
d = 1.3; tt = t(d); x = fit(sweep(60, 120, d, 'saw') * 0.5 * np.minimum(1, tt * 3), bp(noise(d), 200, 5000) * np.minimum(1, tt * 1.2) * 0.4,
                         sweep(200, 900, d, 'sin', 2.0) * 0.4 * np.minimum(1, tt * 2))
x *= np.where(tt > d - 0.2, (d - tt) / 0.2, 1.0)
save('super', np.tanh(lp(x, 7000) * 1.8), 0.85)
d = 0.07; save('select', fit(np.sin(2 * np.pi * 880 * t(d)) * env(int(SR * d), 0.002, 40), np.sin(2 * np.pi * 1760 * t(d)) * env(int(SR * d), 0.002, 60) * 0.3), 0.5)
d = 0.32; tt = t(d); x = np.sin(2 * np.pi * np.where(tt < 0.09, 660, 990) * tt) * env(int(SR * d), 0.003, 6)
save('confirm', x, 0.55)
d = 1.0; x = fit(lp(noise(d), 1500) * env(int(SR * d), 0.001, 4), sweep(90, 30, d, curve=0.4) * env(int(SR * d), 0.001, 3.5) * 1.3,
               hp(noise(0.08), 2000) * 0.8)
save('ko', np.tanh(x * 2.2))
d = 0.6; x = sum(np.sin(2 * np.pi * f * t(d)) * env(int(SR * d), 0.002 + i * 0.03, 5) for i, f in enumerate((1047, 1319, 1568, 2093)))
save('perfect', x, 0.6)
d = 0.14; save('jump', sweep(260, 820, d, 'tri') * env(int(SR * d), 0.002, 14), 0.4)
d = 0.7; tt = t(d); x = sum(np.sin(2 * np.pi * f * tt) for f in (220, 330, 440, 660)) * env(int(SR * d), 0.01, 3)
save('round', x, 0.55)

# --- elementos
d = 0.9; tt = t(d)
crack = np.zeros(len(tt))
for k in range(40):
    p = rng.integers(0, len(tt) - 200)
    crack[p:p + 200] += hp(noise(200 / SR), 2000) * np.exp(-np.arange(200) / 30) * rng.uniform(0.3, 1)
x = fit(lp(noise(d), 900) * env(len(tt), 0.05, 3) * 1.2, crack * 0.6 * np.exp(-tt * 2), sweep(80, 40, d) * env(len(tt), 0.02, 4) * 0.6)
save('fire', x, 0.8)
d = 0.5; tt = t(d)
x = fit(sum(np.sin(2 * np.pi * f * tt) * env(len(tt), 0.001, 8 + i * 3) for i, f in enumerate((2100, 3150, 4200, 5700))) * 0.4,
        hp(noise(0.05), 4000) * 0.8)
save('ice', x, 0.6)
d = 0.9; tt = t(d)
x = bp(noise(d), 300, 2400) * (0.5 + 0.5 * np.sin(2 * np.pi * 3 * tt) ** 2) * np.sin(np.pi * tt / d)
save('wind', lp(x, 2000), 0.7)
d = 0.8; tt = t(d)
x = fit(lp(noise(d), 1400) * np.sin(np.pi * np.minimum(tt / 0.6, 1)) * np.exp(-tt * 1.5),
        sum(np.sin(2 * np.pi * rng.uniform(400, 900) * tt) * np.exp(-((tt - c) ** 2) / 0.0004) * 0.3 for c in rng.uniform(0.1, 0.7, 12)))
save('water', x, 0.75)
d = 1.0; tt = t(d)
x = fit(lp(noise(d), 180) * 3.0 * env(len(tt), 0.01, 2.5), sweep(55, 30, d) * env(len(tt), 0.01, 3) * 1.0)
x *= 1 + 0.5 * np.sin(2 * np.pi * 14 * tt)
save('quake', np.tanh(x * 1.5), 0.9)
d = 0.35; tt = t(d)
x = sweep(1800, 300, d, 'sq', 0.5) * env(len(tt), 0.001, 9) * 0.4 + hp(noise(d), 3000) * env(len(tt), 0.001, 20) * 0.5
x *= (rng.uniform(0, 1, len(tt)) > 0.15)
save('zap', lp(x, 7000), 0.6)
d = 0.8; tt = t(d)
bub = np.zeros(len(tt))
for c in rng.uniform(0.0, 0.7, 14):
    seg = (tt >= c) & (tt < c + 0.06)
    f0 = rng.uniform(300, 700)
    bub[seg] += np.sin(2 * np.pi * (f0 + 3000 * (tt[seg] - c)) * (tt[seg] - c)) * np.exp(-(tt[seg] - c) * 50)
x = fit(bub * 0.6, lp(noise(d), 600) * env(len(tt), 0.05, 3) * 0.5)
save('poison', x, 0.6)
d = 0.5; tt = t(d)
clicks = np.zeros(len(tt))
for k in range(int(d * 40)):
    p = int(k * SR / 40)
    if p + 100 < len(tt): clicks[p:p + 100] += np.sin(2 * np.pi * 2400 * np.arange(100) / SR) * np.exp(-np.arange(100) / 15)
x = fit(clicks * 0.5, sweep(400, 900, d, 'saw') * 0.15 * env(len(tt), 0.01, 3))
save('gear', lp(x, 6000), 0.6)
d = 0.8; tt = t(d)
x = sweep(200, 1200, d, 'sin', 0.7) * np.sin(2 * np.pi * 30 * tt) * 0.5 + bp(noise(d), 500, 3000) * 0.3
x *= np.sin(np.pi * tt / d)
save('portal', x, 0.6)
d = 0.6; tt = t(d)
x = fit(bp(noise(d), 150, 900) * np.sin(np.pi * tt / d), sweep(500, 80, d, 'saw', 0.5) * 0.2 * np.sin(np.pi * tt / d))
save('shadow', lp(x, 2500), 0.7)
d = 0.9; tt = t(d)
x = fit(lp(noise(d), 2200) * env(len(tt), 0.001, 5) * 1.3, sweep(110, 35, d, curve=0.4) * env(len(tt), 0.001, 4) * 1.2)
save('explode', np.tanh(x * 2.0), 0.9)
d = 0.9; tt = t(d)
x = fit(sweep(150, 1400, d, 'saw', 1.6) * 0.3 * np.sin(np.pi * tt / d), sweep(300, 2800, d, 'sin', 1.6) * 0.3 * np.sin(np.pi * tt / d),
        hp(noise(0.12), 2000) * np.exp(-np.arange(int(0.12 * SR)) / SR * 30) * 0.6)
save('overload', lp(x, 8000), 0.75)
d = 1.0; tt = t(d)
x = fit(sweep(140, 160, d, 'saw') * 0.4, sweep(280, 330, d, 'sq') * 0.15, bp(noise(d), 800, 6000) * 0.4) * np.minimum(1, tt * 20) * np.where(tt > 0.8, (d - tt) / 0.2, 1)
save('beam', lp(x, 6000), 0.75)
print('sfx ok')
