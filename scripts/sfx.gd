extends RefCounted
## Sons et musiques synthétisés par code.

const RATE := 22050


static func _make(samples: PackedFloat32Array, rate: int = RATE) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w


## wave : 0 sinus, 1 carré, 2 triangle, 3 bruit
static func _tone(f0: float, f1: float, dur: float, vol: float = 0.5, wave: int = 0, rate: int = RATE) -> PackedFloat32Array:
	var n := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += lerpf(f0, f1, t) / float(rate)
		var s := 0.0
		match wave:
			0: s = sin(phase * TAU)
			1: s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			2: s = 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0
			_: s = randf() * 2.0 - 1.0
		out[i] = s * vol * minf(1.0, t * 25.0) * pow(1.0 - t, 1.6)
	return out


static func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


static func _mix_into(buf: PackedFloat32Array, start: int, note: PackedFloat32Array) -> void:
	for i in note.size():
		if start + i < buf.size():
			buf[start + i] += note[i]


static func build_all() -> Dictionary:
	var d := {}
	d["jump"] = _make(_tone(260, 560, 0.18, 0.35, 2))
	d["jump2"] = _make(_tone(420, 880, 0.2, 0.35, 2))
	d["coin"] = _make(_cat([_tone(988, 988, 0.07, 0.3, 1), _tone(1318, 1318, 0.2, 0.3, 1)]))
	d["bounce"] = _make(_tone(160, 720, 0.3, 0.45, 0))
	d["land"] = _make(_tone(110, 50, 0.12, 0.5, 0))
	d["checkpoint"] = _make(_cat([_tone(523, 523, 0.1, 0.3, 2), _tone(659, 659, 0.1, 0.3, 2), _tone(784, 784, 0.25, 0.3, 2)]))
	d["fall"] = _make(_tone(500, 90, 0.6, 0.35, 2))
	d["crumble"] = _make(_tone(0, 0, 0.35, 0.3, 3))
	d["click"] = _make(_tone(700, 500, 0.06, 0.3, 1))
	d["win"] = _make(_cat([
		_tone(523, 523, 0.12, 0.3, 2), _tone(659, 659, 0.12, 0.3, 2),
		_tone(784, 784, 0.12, 0.3, 2), _tone(1047, 1047, 0.5, 0.35, 2)]))
	d["lose"] = _make(_cat([_tone(392, 392, 0.2, 0.3, 2), _tone(330, 330, 0.2, 0.3, 2), _tone(262, 262, 0.5, 0.3, 2)]))
	return d


## Boucle musicale de 8 mesures, différente pour chaque thème.
static func music(theme: int) -> AudioStreamWAV:
	var rate := 11025
	var scales := [
		[0, 2, 4, 7, 9], [0, 3, 5, 7, 10], [0, 2, 3, 7, 8], [0, 1, 5, 7, 8], [0, 2, 7, 9, 12], [0, 4, 7, 11, 14],
	]
	var roots: Array[float] = [196.0, 174.6, 220.0, 207.7, 164.8, 174.6, 130.8, 196.0, 146.8, 146.8, 185.0, 233.1]
	var tempo: Array[float] = [0.16, 0.2, 0.17, 0.15, 0.22, 0.18, 0.13, 0.19, 0.24, 0.14, 0.12, 0.22]
	var theme_i := clampi(theme, 0, 11)
	var step: float = tempo[theme_i]
	var scale: Array = scales[theme_i % scales.size()]
	var root: float = roots[theme_i]
	var bars := 8
	var per_bar := 8
	var total := int(step * per_bar * bars * rate)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + theme_i
	var prog := [0, 3, 4, 0, 2, 3, 4, 0]
	for b in bars:
		var bar_start := int(b * per_bar * step * rate)
		var bass: float = root * 0.5 * pow(2.0, float(scale[prog[b] % scale.size()]) / 12.0)
		_mix_into(buf, bar_start, _tone(bass, bass, step * per_bar * 0.95, 0.22, 2, rate))
		for k in per_bar:
			if rng.randf() < 0.25:
				continue
			var deg: int = scale[rng.randi() % scale.size()]
			var oct := 2.0 if rng.randf() < 0.4 else 1.0
			var f: float = root * oct * pow(2.0, float(deg) / 12.0)
			_mix_into(buf, bar_start + int(k * step * rate), _tone(f, f, step * 1.6, 0.12, 0, rate))
	var w := _make(buf, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = total
	return w
