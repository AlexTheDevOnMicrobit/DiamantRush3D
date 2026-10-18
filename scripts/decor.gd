extends RefCounted
## Décors par thème : accessoires sur les plateformes et paysage lointain.

const Models = preload("res://scripts/models.gd")


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
	s.rings = seg / 2
	return s


# ---------------------------------------------------------------- accessoires de plateforme

## Petit objet décoratif posé sur la plateforme (sans collision), à l'origine = dessus de la dalle.
static func prop(theme_idx: int, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	match theme_idx:
		0:
			if rng.randf() < 0.6:
				var trunk := _mi(_cyl(0.1, 0.14, 0.7), Color(0.45, 0.3, 0.18))
				trunk.position.y = 0.35
				n.add_child(trunk)
				var leaves := _mi(_cyl(0.0, 0.5, 0.9, 6), Color(0.2, 0.62, 0.28))
				leaves.position.y = 1.0
				n.add_child(leaves)
				var leaves2 := _mi(_cyl(0.0, 0.38, 0.7, 6), Color(0.25, 0.7, 0.32))
				leaves2.position.y = 1.5
				n.add_child(leaves2)
			else:
				var stem := _mi(_cyl(0.02, 0.02, 0.4, 4), Color(0.2, 0.6, 0.25))
				stem.position.y = 0.2
				n.add_child(stem)
				var flower := _mi(_sphere(0.14, 6), Color.from_hsv(rng.randf(), 0.5, 1.0), 0.2)
				flower.position.y = 0.45
				n.add_child(flower)
		1:
			if rng.randf() < 0.6:
				var body := _mi(CapsuleMesh.new(), Color(0.3, 0.6, 0.3))
				(body.mesh as CapsuleMesh).radius = 0.17
				(body.mesh as CapsuleMesh).height = 1.0
				body.position.y = 0.5
				n.add_child(body)
				var arm := _mi(CapsuleMesh.new(), Color(0.3, 0.6, 0.3))
				(arm.mesh as CapsuleMesh).radius = 0.1
				(arm.mesh as CapsuleMesh).height = 0.45
				arm.position = Vector3(0.25, 0.6, 0)
				n.add_child(arm)
			else:
				var rock := _mi(_sphere(0.35, 6), Color(0.72, 0.55, 0.38))
				rock.scale = Vector3(1.2, 0.7, 1.0)
				rock.position.y = 0.2
				n.add_child(rock)
		2:
			for i in 3:
				var cm := Models.diamond_mesh()
				var c := _mi(cm, Color(0.55, 0.45, 1.0) if i % 2 == 0 else Color(0.4, 0.95, 1.0), 0.9)
				c.scale = Vector3(0.35, 0.4 + rng.randf() * 0.5, 0.35)
				c.position = Vector3(i * 0.28 - 0.28, c.scale.y * 0.85, rng.randf_range(-0.1, 0.1))
				n.add_child(c)
		3:
			var rock2 := _mi(_sphere(0.4, 5), Color(0.18, 0.14, 0.14))
			rock2.scale = Vector3(1.0, 0.8, 1.0 + rng.randf() * 0.4)
			rock2.position.y = 0.25
			n.add_child(rock2)
			var ember := _mi(BoxMesh.new(), Color(1.0, 0.45, 0.1), 2.0)
			(ember.mesh as BoxMesh).size = Vector3(0.12, 0.12, 0.12)
			ember.position = Vector3(0.15, 0.55, 0)
			n.add_child(ember)
		_:
			var pole := _mi(_cyl(0.03, 0.05, 0.9, 5), Color(0.7, 0.8, 1.0))
			pole.position.y = 0.45
			n.add_child(pole)
			var orb := _mi(_sphere(0.12, 6), Color(0.6, 0.9, 1.0), 2.5)
			orb.position.y = 0.95
			n.add_child(orb)
	return n


# ---------------------------------------------------------------- paysage

## center / extent : boîte englobant le parcours ; obstacles : positions des plateformes (Vector3)
static func scenery(parent: Node3D, theme_idx: int, center: Vector3, extent: Vector3, min_y: float, obstacles: Array, rng: RandomNumberGenerator) -> void:
	var span := maxf(extent.x, extent.z) + 70.0

	# îlots rocheux flottants
	for i in 26:
		var p := Vector3(
			center.x + rng.randf_range(-span, span),
			center.y + rng.randf_range(-35.0, 30.0),
			center.z + rng.randf_range(-span, span))
		if _too_close(p, obstacles, 12.0):
			continue
		var s := rng.randf_range(2.5, 8.0)
		var island := Node3D.new()
		island.position = p
		var top := _mi(_cyl(s, s * 0.95, 0.8, 7), _theme_top(theme_idx).darkened(0.1))
		island.add_child(top)
		var under := _mi(_cyl(s * 0.95, 0.2, s * 1.2, 7), _theme_side(theme_idx))
		under.position.y = -0.4 - s * 0.6
		island.add_child(under)
		var tree := prop(theme_idx, rng)
		tree.position.y = 0.4
		tree.scale = Vector3.ONE * rng.randf_range(2.0, 4.0)
		island.add_child(tree)
		parent.add_child(island)

	match theme_idx:
		0:
			for i in 14:
				var c := _mi(_sphere(1.0, 8), Color(1, 1, 1))
				c.scale = Vector3(rng.randf_range(6, 14), rng.randf_range(1.5, 3), rng.randf_range(4, 8))
				c.position = Vector3(center.x + rng.randf_range(-span, span), center.y + rng.randf_range(15.0, 45.0), center.z + rng.randf_range(-span, span))
				c.material_override = Models.material(Color(1, 1, 1, 1), 0.3)
				parent.add_child(c)
			_sun(parent, center, Color(1.0, 0.95, 0.7), 14.0)
		1:
			for i in 8:
				var pyr := _mi(_cyl(0.0, 1.0, 1.0, 4), Color(0.85, 0.65, 0.35))
				var h := rng.randf_range(8.0, 22.0)
				pyr.scale = Vector3(h * 1.2, h, h * 1.2)
				pyr.position = Vector3(center.x + rng.randf_range(-span, span), center.y + rng.randf_range(-45.0, -25.0), center.z + rng.randf_range(-span, span))
				pyr.rotation.y = rng.randf() * TAU
				parent.add_child(pyr)
			_sun(parent, center, Color(1.0, 0.7, 0.3), 20.0)
		2:
			for i in 30:
				var cr := _mi(Models.diamond_mesh(), Color(0.55, 0.45, 1.0) if i % 2 == 0 else Color(0.4, 0.95, 1.0), 1.2)
				var h2 := rng.randf_range(4.0, 14.0)
				cr.scale = Vector3(h2 * 0.4, h2, h2 * 0.4)
				cr.position = Vector3(center.x + rng.randf_range(-span, span), center.y + rng.randf_range(-35.0, 25.0), center.z + rng.randf_range(-span, span))
				if _too_close(cr.position, obstacles, 8.0):
					cr.free()
					continue
				cr.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
				parent.add_child(cr)
		3:
			var sea := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(1200, 1200)
			sea.mesh = pm
			sea.material_override = Models.material(Color(1.0, 0.35, 0.05), 1.6)
			sea.position = Vector3(center.x, min_y - 28.0, center.z)
			parent.add_child(sea)
			var sea_light := OmniLight3D.new()
			sea_light.light_color = Color(1.0, 0.45, 0.15)
			sea_light.omni_range = 120.0
			sea_light.light_energy = 3.0
			sea_light.position = Vector3(center.x, min_y - 22.0, center.z)
			parent.add_child(sea_light)
			for i in 14:
				var sp := _mi(_cyl(0.0, 1.0, 1.0, 5), Color(0.15, 0.1, 0.1))
				var h3 := rng.randf_range(15.0, 40.0)
				sp.scale = Vector3(h3 * 0.3, h3, h3 * 0.3)
				sp.position = Vector3(center.x + rng.randf_range(-span, span), min_y - 28.0 + h3 * 0.5, center.z + rng.randf_range(-span, span))
				parent.add_child(sp)
		_:
			for i in 220:
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


static func _theme_top(theme_idx: int) -> Color:
	var tc: Array = [Color(0.35, 0.8, 0.38), Color(0.95, 0.8, 0.45), Color(0.62, 0.5, 0.98), Color(0.5, 0.32, 0.28), Color(0.85, 0.92, 1.0)]
	return tc[theme_idx]


static func _theme_side(theme_idx: int) -> Color:
	var sc: Array = [Color(0.5, 0.35, 0.22), Color(0.7, 0.45, 0.25), Color(0.25, 0.2, 0.45), Color(0.2, 0.15, 0.15), Color(0.3, 0.38, 0.6)]
	return sc[theme_idx]
