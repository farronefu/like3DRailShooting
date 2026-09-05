"""Generate original short PCM effects using Python's standard library."""
import math
import pathlib
import random
import struct
import wave

DEST = pathlib.Path(__file__).resolve().parents[1] / 'assets' / 'audio'
DEST.mkdir(parents=True, exist_ok=True)
random.seed(64)
RATE = 22050

def save(name, duration, sample):
    with wave.open(str(DEST / (name + '.wav')), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        frames = []
        for i in range(int(duration * RATE)):
            t = i / RATE
            envelope = min(1, t * 180) * (1 - t / duration) ** 2
            value = max(-1, min(1, sample(t) * envelope))
            frames.append(struct.pack('<h', int(value * 16000)))
        out.writeframes(b''.join(frames))

save('laser', 0.12, lambda t: math.sin(math.tau * (1400 * t - 4200 * t*t)) * 0.6)
save('hit', 0.13, lambda t: math.sin(math.tau * 180 * t) * 0.5 + random.uniform(-0.3, 0.3))
save('damage', 0.35, lambda t: math.sin(math.tau * 60 * t) * 0.6 + random.uniform(-0.4, 0.4))
save('repair', 0.65, lambda t: math.sin(math.tau * (520 * t + 420 * t*t)) * 0.6)
save('clear', 1.6, lambda t: sum(math.sin(math.tau * f * t) for f in (523.25, 659.25, 783.99)) / 3)
print('Generated five original sound effects.')
