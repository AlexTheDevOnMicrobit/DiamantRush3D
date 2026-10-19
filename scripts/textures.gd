extends RefCounted
## Textures procédurales (niveaux de gris, teintées par l'albédo du matériau).

static var _cache := {}


static func stone(seed_v: int = 1) -> ImageTexture:
	if _cache.has(seed_v):
		return _cache[seed_v]
	var img := Image.create(64, 64, true, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for y in 64:
		for x in 64:
			var v := 0.84 + rng.randf() * 0.16
			var row := int(y / 16.0)
			var off := 16 if row % 2 == 1 else 0
			if y % 16 == 0 or (x + off) % 32 == 0:
				v *= 0.68
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[seed_v] = tex
	return tex


static func speckle(seed_v: int = 2) -> ImageTexture:
	var key := 1000 + seed_v
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(32, 32, true, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for y in 32:
		for x in 32:
			var v := 0.88 + rng.randf() * 0.12
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Grille néon (lignes claires sur fond noir).
static func grid() -> ImageTexture:
	if _cache.has(2000):
		return _cache[2000]
	var img := Image.create(64, 64, true, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var line := x < 2 or y < 2
			img.set_pixel(x, y, Color(1, 1, 1, 1) if line else Color(0.02, 0.02, 0.05, 1))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[2000] = tex
	return tex
