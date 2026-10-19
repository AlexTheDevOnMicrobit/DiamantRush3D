extends RefCounted
## Décors par monde : accessoires sur les plateformes et paysage lointain.

const Models = preload("res://scripts/models.gd")
const LevelData = preload("res://scripts/level_data.gd")
const Textures = preload("res://scripts/textures.gd")


static func _mi(mesh: Mesh, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = Models.material(color, emission, 0.0, 0.8)
	return m


static func _cyl(top: float, bottom: float, h: float, seg: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	return c


static func _sphere(r: float, seg: int = 8) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = maxi(seg / 2, 2)
	return s


static func _box(sx: float, sy: float, sz: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(sx, sy, sz)
	return b


static func _at(n: Node3D, p: Vector3) -> Node3D:
	n.position = p
	return n


# ---------------------------------------------------------------- accessoires de plateforme

## Petit objet décoratif posé sur la plateforme (sans collision), à l'origine = dessus de la dalle.
static func prop(theme_idx: int, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	var alt := rng.randf() < 0.5
	match theme_idx:
		0:
			if alt:
				n.add_child(_at(_mi(_cyl(0.1, 0.14, 0.7), Color(0.45, 0.3, 0.18)), Vector3(0, 0.35, 0)))
				n.add_child(_at(_mi(_cyl(0.0, 0.5, 0.9, 6), Color(0.2, 0.62, 0.28)), Vector3(0, 1.0, 0)))
				n.add_child(_at(_mi(_cyl(0.0, 0.38, 0.7, 6), Color(0.25, 0.7, 0.32)), Vector3(0, 1.5, 0)))
			else:
				n.add_child(_at(_mi(_cyl(0.02, 0.02, 0.4, 4), Color(0.2, 0.6, 0.25)), Vector3(0, 0.2, 0)))
				n.add_child(_at(_mi(_sphere(0.14, 6), Color.from_hsv(rng.randf(), 0.5, 1.0), 0.2), Vector3(0, 0.45, 0)))
		1:
			if alt:
				n.add_child(_at(_mi(_cyl(0.08, 0.12, 0.6), Color(0.3, 0.2, 0.12)), Vector3(0, 0.3, 0)))
				for k in 3:
					n.add_child(_at(_mi(_cyl(0.0, 0.5 - k * 0.12, 0.7, 6), Color(0.1, 0.45, 0.3)), Vector3(0, 0.8 + k * 0.5, 0)))
			else:
				n.add_child(_at(_mi(_cyl(0.05, 0.07, 0.3, 6), Color(0.9, 0.9, 0.8)), Vector3(0, 0.15, 0)))
				n.add_child(_at(_mi(_sphere(0.25, 8), Color(0.5, 1.0, 0.7), 1.2), Vector3(0, 0.38, 0)))
		2:
			if alt:
				var body := _mi(CapsuleMesh.new(), Color(0.3, 0.6, 0.3))
				(body.mesh as CapsuleMesh).radius = 0.17
				(body.mesh as CapsuleMesh).height = 1.0
				n.add_child(_at(body, Vector3(0, 0.5, 0)))
				var arm := _mi(CapsuleMesh.new(), Color(0.3, 0.6, 0.3))
				(arm.mesh as CapsuleMesh).radius = 0.1
				(arm.mesh as CapsuleMesh).height = 0.45
				n.add_child(_at(arm, Vector3(0.25, 0.6, 0)))
			else:
				var rock := _mi(_sphere(0.35, 6), Color(0.72, 0.55, 0.38))
				rock.scale = Vector3(1.2, 0.7, 1.0)
				n.add_child(_at(rock, Vector3(0, 0.2, 0)))
		3:
			var cols := [Color(1.0, 0.4, 0.45), Color(1.0, 0.7, 0.3), Color(0.9, 0.4, 0.9)]
			var col: Color = cols[rng.randi() % 3]
			if alt:
				n.add_child(_at(_mi(_cyl(0.05, 0.1, 0.8, 5), col, 0.4), Vector3(0, 0.4, 0)))
				var b1 := _mi(_cyl(0.04, 0.07, 0.5, 5), col, 0.4)
				b1.rotation_degrees.z = 35.0
				n.add_child(_at(b1, Vector3(0.2, 0.7, 0)))
				var b2 := _mi(_cyl(0.04, 0.07, 0.5, 5), col, 0.4)
				b2.rotation_degrees.z = -35.0
				n.add_child(_at(b2, Vector3(-0.2, 0.65, 0)))
			else:
				var shell := _mi(_sphere(0.3, 8), Color(1.0, 0.9, 0.85))
				shell.scale = Vector3(1.0, 0.6, 1.0)
				n.add_child(_at(shell, Vector3(0, 0.15, 0)))
		4:
			if alt:
				for k in 3:
					var sp := _mi(_cyl(0.0, 0.18, 0.5 + k * 0.35, 5), Color(0.7, 0.9, 1.0), 0.3)
					n.add_child(_at(sp, Vector3(k * 0.22 - 0.22, (0.5 + k * 0.35) * 0.5, 0)))
			else:
				var mound := _mi(_sphere(0.45, 8), Color(1, 1, 1))
				mound.scale = Vector3(1.2, 0.6, 1.0)
				n.add_child(_at(mound, Vector3(0, 0.2, 0)))
		5:
			for i in 3:
				var c := _mi(Models.diamond_mesh(), Color(0.55, 0.45, 1.0) if i % 2 == 0 else Color(0.4, 0.95, 1.0), 0.9)
				c.scale = Vector3(0.35, 0.4 + rng.randf() * 0.5, 0.35)
				n.add_child(_at(c, Vector3(i * 0.28 - 0.28, c.scale.y * 0.85, rng.randf_range(-0.1, 0.1))))
		6:
			if alt:
				var gear := _mi(_cyl(0.45, 0.45, 0.12, 8), Color(0.75, 0.55, 0.25), 0.1)
				gear.rotation_degrees.x = 90.0
				n.add_child(_at(gear, Vector3(0, 0.45, 0)))
				var hub := _mi(_cyl(0.12, 0.12, 0.2, 6), Color(0.3, 0.3, 0.33))
				hub.rotation_degrees.x = 90.0
				n.add_child(_at(hub, Vector3(0, 0.45, 0)))
			else:
				n.add_child(_at(_mi(_cyl(0.14, 0.14, 0.9, 8), Color(0.4, 0.4, 0.45)), Vector3(0, 0.45, 0)))
				n.add_child(_at(_mi(_cyl(0.2, 0.2, 0.1, 8), Color(0.75, 0.55, 0.25)), Vector3(0, 0.92, 0)))
		7:
			n.add_child(_at(_mi(_cyl(0.28, 0.32, 0.9, 8), Color(0.85, 0.78, 0.6)), Vector3(0, 0.45, 0)))
			if alt:
				n.add_child(_at(_mi(_box(0.8, 0.16, 0.8), Color(0.8, 0.72, 0.55)), Vector3(0, 0.98, 0)))
			else:
				var broken := _mi(_box(0.5, 0.25, 0.5), Color(0.75, 0.68, 0.5))
				broken.rotation_degrees.y = 25.0
				n.add_child(_at(broken, Vector3(0.5, 0.12, 0.2)))
		8:
			if alt:
				n.add_child(_at(_mi(_cyl(0.04, 0.12, 1.3, 5), Color(0.18, 0.15, 0.12)), Vector3(0, 0.65, 0)))
				var br := _mi(_cyl(0.02, 0.05, 0.6, 4), Color(0.18, 0.15, 0.12))
				br.rotation_degrees.z = 50.0
				n.add_child(_at(br, Vector3(0.25, 1.1, 0)))
			else:
				n.add_child(_at(_mi(_sphere(0.14, 8), Color(0.6, 1.0, 0.7), 3.0), Vector3(0, 0.7, 0)))
				n.add_child(_at(_mi(_cyl(0.02, 0.02, 0.6, 4), Color(0.2, 0.2, 0.18)), Vector3(0, 0.3, 0)))
		9:
			var rock2 := _mi(_sphere(0.4, 5), Color(0.18, 0.14, 0.14))
			rock2.scale = Vector3(1.0, 0.8, 1.0 + rng.randf() * 0.4)
			n.add_child(_at(rock2, Vector3(0, 0.25, 0)))
			n.add_child(_at(_mi(_box(0.12, 0.12, 0.12), Color(1.0, 0.45, 0.1), 2.0), Vector3(0.15, 0.55, 0)))
		10:
			var neon: Color = Color(1.0, 0.2, 0.8) if alt else Color(0.1, 0.9, 1.0)
			n.add_child(_at(_mi(_box(0.14, 1.1, 0.14), neon, 3.0), Vector3(0, 0.55, 0)))
			n.add_child(_at(_mi(_box(0.4, 0.06, 0.4), neon, 2.0), Vector3(0, 0.03, 0)))
		_:
			n.add_child(_at(_mi(_cyl(0.03, 0.05, 0.9, 5), Color(0.7, 0.8, 1.0)), Vector3(0, 0.45, 0)))
			n.add_child(_at(_mi(_sphere(0.12, 6), Color(0.6, 0.9, 1.0), 2.5), Vector3(0, 0.95, 0)))
	return n


# ---------------------------------------------------------------- paysage

## center / extent : boîte englobant le parcours ; obstacles : positions des plateformes (Vector3)
## quality : 0 bas, 1 moyen, 2 élevé
static func scenery(parent: Node3D, theme_idx: int, center: Vector3, extent: Vector3, min_y: float, obstacles: Array, rng: RandomNumberGenerator, quality: int = 2) -> void:
	var span := maxf(extent.x, extent.z) + 70.0
	var theme: Dictionary = LevelData.get_themes()[theme_idx]
	var top_c: Color = theme["top"]
	var side_c: Color = theme["side"]
	var qf: float = [0.35, 0.7, 1.0][clampi(quality, 0, 2)]

	# îlots rocheux flottants
	for i in int(26 * qf):
		var p := Vector3(
			center.x + rng.randf_range(-span, span),
			center.y + rng.randf_range(-35.0, 30.0),
			center.z + rng.randf_range(-span, span))
		if _too_close(p, obstacles, 12.0):
			continue
		var s := rng.randf_range(2.5, 8.0)
		var island := Node3D.new()
		island.position = p
		island.add_child(_mi(_cyl(s, s * 0.95, 0.8, 7), top_c.darkened(0.1)))
		island.add_child(_at(_mi(_cyl(s * 0.95, 0.2, s * 1.2, 7), side_c), Vector3(0, -0.4 - s * 0.6, 0)))
		if quality > 0:
			var tree := prop(theme_idx, rng)
			tree.position.y = 0.4
			tree.scale = Vector3.ONE * rng.randf_range(2.0, 4.0)
			island.add_child(tree)
		parent.add_child(island)

	var rnd := func(r: float) -> Vector3:
		return Vector3(center.x + rng.randf_range(-r, r), 0.0, center.z + rng.randf_range(-r, r))

	match theme_idx:
		0:
			for i in int(14 * qf):
				var c := _mi(_sphere(1.0, 8), Color(1, 1, 1), 0.3)
				c.scale = Vector3(rng.randf_range(6, 14), rng.randf_range(1.5, 3), rng.randf_range(4, 8))
				var q: Vector3 = rnd.call(span)
				c.position = Vector3(q.x, center.y + rng.randf_range(15.0, 45.0), q.z)
				parent.add_child(c)
			_sun(parent, center, Color(1.0, 0.95, 0.7), 14.0)
		1:
			for i in int(26 * qf):
				var q2: Vector3 = rnd.call(span)
				var h := rng.randf_range(12.0, 30.0)
				var pine := _mi(_cyl(0.0, h * 0.25, h, 6), Color(0.05, 0.3, 0.22))
				pine.position = Vector3(q2.x, center.y + rng.randf_range(-45.0, -20.0) + h * 0.5, q2.z)
				if not _too_close(pine.position, obstacles, 10.0):
					parent.add_child(pine)
				else:
					pine.free()
		2:
			for i in int(8 * qf) + 2:
				var pyr := _mi(_cyl(0.0, 1.0, 1.0, 4), Color(0.85, 0.65, 0.35))
				var h2 := rng.randf_range(8.0, 22.0)
				pyr.scale = Vector3(h2 * 1.2, h2, h2 * 1.2)
				var q3: Vector3 = rnd.call(span)
				pyr.position = Vector3(q3.x, center.y + rng.randf_range(-45.0, -25.0), q3.z)
				pyr.rotation.y = rng.randf() * TAU
				parent.add_child(pyr)
			_sun(parent, center, Color(1.0, 0.7, 0.3), 20.0)
		3:
			_plane(parent, Vector2(1400, 1400), Color(0.1, 0.55, 0.8), 0.8, Vector3(center.x, min_y - 30.0, center.z))
			for i in int(30 * qf):
				var b := _mi(_sphere(rng.randf_range(0.6, 2.5), 8), Color(0.7, 0.95, 1.0), 0.4)
				var q4: Vector3 = rnd.call(span)
				b.position = Vector3(q4.x, center.y + rng.randf_range(-30.0, 30.0), q4.z)
				if not _too_close(b.position, obstacles, 6.0):
					parent.add_child(b)
				else:
					b.free()
		4:
			for i in int(14 * qf) + 2:
				var mt := _mi(_cyl(0.0, 1.0, 1.0, 6), Color(0.9, 0.97, 1.0))
				var h3 := rng.randf_range(20.0, 50.0)
				mt.scale = Vector3(h3 * 0.8, h3, h3 * 0.8)
				var q5: Vector3 = rnd.call(span)
				mt.position = Vector3(q5.x, center.y - 45.0 + h3 * 0.5, q5.z)
				parent.add_child(mt)
		5:
			for i in int(30 * qf):
				var cr := _mi(Models.diamond_mesh(), Color(0.55, 0.45, 1.0) if i % 2 == 0 else Color(0.4, 0.95, 1.0), 1.2)
				var h4 := rng.randf_range(4.0, 14.0)
				cr.scale = Vector3(h4 * 0.4, h4, h4 * 0.4)
				var q6: Vector3 = rnd.call(span)
				cr.position = Vector3(q6.x, center.y + rng.randf_range(-35.0, 25.0), q6.z)
				if _too_close(cr.position, obstacles, 8.0):
					cr.free()
					continue
				cr.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
				parent.add_child(cr)
		6:
			for i in int(10 * qf) + 2:
				var gear := _mi(_cyl(1.0, 1.0, 0.2, 12), Color(0.65, 0.5, 0.25))
				var g := rng.randf_range(6.0, 18.0)
				gear.scale = Vector3(g, 1.0, g)
				var q7: Vector3 = rnd.call(span)
				gear.position = Vector3(q7.x, center.y + rng.randf_range(-40.0, -10.0), q7.z)
				gear.rotation = Vector3(PI * 0.5, 0.0, rng.randf() * TAU)
				parent.add_child(gear)
			for i in int(10 * qf):
				var ch := _mi(_cyl(1.5, 2.0, 1.0, 8), Color(0.3, 0.3, 0.33))
				var hh := rng.randf_range(20.0, 40.0)
				ch.scale = Vector3(1.0, hh, 1.0)
				var q8: Vector3 = rnd.call(span)
				ch.position = Vector3(q8.x, min_y - 25.0 + hh * 0.5, q8.z)
				parent.add_child(ch)
		7:
			for i in int(24 * qf):
				var colm := _mi(_cyl(1.2, 1.4, 1.0, 10), Color(0.9, 0.82, 0.62))
				var hc := rng.randf_range(10.0, 28.0)
				colm.scale = Vector3(1.0, hc, 1.0)
				var q9: Vector3 = rnd.call(span)
				colm.position = Vector3(q9.x, center.y + rng.randf_range(-45.0, -20.0) + hc * 0.5, q9.z)
				if _too_close(colm.position, obstacles, 10.0):
					colm.free()
					continue
				parent.add_child(colm)
			_sun(parent, center, Color(1.0, 0.85, 0.5), 12.0)
		8:
			_plane(parent, Vector2(1400, 1400), Color(0.2, 0.6, 0.35), 0.4, Vector3(center.x, min_y - 12.0, center.z))
			for i in int(22 * qf):
				var w := _mi(_sphere(0.35, 6), Color(0.6, 1.0, 0.7), 3.0)
				var qa: Vector3 = rnd.call(span * 0.6)
				w.position = Vector3(qa.x, center.y + rng.randf_range(-15.0, 20.0), qa.z)
				if not _too_close(w.position, obstacles, 4.0):
					parent.add_child(w)
				else:
					w.free()
		9:
			_plane(parent, Vector2(1200, 1200), Color(1.0, 0.35, 0.05), 1.6, Vector3(center.x, min_y - 28.0, center.z))
			var sea_light := OmniLight3D.new()
			sea_light.light_color = Color(1.0, 0.45, 0.15)
			sea_light.omni_range = 120.0
			sea_light.light_energy = 3.0
			sea_light.position = Vector3(center.x, min_y - 22.0, center.z)
			parent.add_child(sea_light)
			for i in int(14 * qf) + 2:
				var sp2 := _mi(_cyl(0.0, 1.0, 1.0, 5), Color(0.15, 0.1, 0.1))
				var h5 := rng.randf_range(15.0, 40.0)
				sp2.scale = Vector3(h5 * 0.3, h5, h5 * 0.3)
				var qb: Vector3 = rnd.call(span)
				sp2.position = Vector3(qb.x, min_y - 28.0 + h5 * 0.5, qb.z)
				parent.add_child(sp2)
		10:
			var grid := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(1400, 1400)
			grid.mesh = pm
			var gm := Models.material(Color(0.1, 0.9, 1.0), 1.5)
			gm.albedo_texture = Textures.grid()
			gm.uv1_scale = Vector3(120, 120, 1)
			gm.texture_repeat = true
			gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			grid.material_override = gm
			grid.position = Vector3(center.x, min_y - 30.0, center.z)
			parent.add_child(grid)
			for i in int(26 * qf):
				var nc: Color = Color(1.0, 0.2, 0.8) if i % 2 == 0 else Color(0.1, 0.9, 1.0)
				var tw := _mi(_box(1.0, 1.0, 1.0), Color(0.06, 0.04, 0.14), 0.0)
				var th := rng.randf_range(20.0, 70.0)
				var tww := rng.randf_range(4.0, 9.0)
				tw.scale = Vector3(tww, th, tww)
				var qc: Vector3 = rnd.call(span)
				tw.position = Vector3(qc.x, min_y - 30.0 + th * 0.5, qc.z)
				parent.add_child(tw)
				var strip := _mi(_box(1.0, 1.0, 1.0), nc, 3.0)
				strip.scale = Vector3(tww + 0.3, 0.4, tww + 0.3)
				strip.position = Vector3(qc.x, min_y - 30.0 + th * rng.randf_range(0.4, 0.95), qc.z)
				parent.add_child(strip)
		_:
			for i in int(220 * qf):
				var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1), rng.randf_range(-1, 1)).normalized()
				var st := _mi(_sphere(rng.randf_range(0.2, 0.6), 4), Color(1, 1, 1), 3.0)
				st.position = center + d * rng.randf_range(160.0, 230.0)
				parent.add_child(st)
			var planet := _mi(_sphere(40.0, 16), Color(0.45, 0.35, 0.8))
			planet.position = center + Vector3(-140, 40, -120)
			parent.add_child(planet)
			var planet2 := _mi(_sphere(18.0, 12), Color(0.9, 0.5, 0.4))
			planet2.position = center + Vector3(150, 10, 90)
			parent.add_child(planet2)


static func _plane(parent: Node3D, size: Vector2, color: Color, emission: float, pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	m.mesh = pm
	m.material_override = Models.material(color, emission)
	m.position = pos
	parent.add_child(m)


static func _sun(parent: Node3D, center: Vector3, color: Color, size: float) -> void:
	var s := _mi(_sphere(size, 12), color, 3.0)
	s.position = center + Vector3(120, 90, -160)
	parent.add_child(s)


static func _too_close(p: Vector3, obstacles: Array, dist: float) -> bool:
	for o in obstacles:
		var ov: Vector3 = o
		if Vector2(ov.x - p.x, ov.z - p.z).length() < dist and absf(ov.y - p.y) < dist * 0.9:
			return true
	return false
