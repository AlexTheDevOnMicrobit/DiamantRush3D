extends RefCounted
## Maillages générés par code (aucun asset externe).


static func diamond_mesh() -> ArrayMesh:
	var h := 0.85
	var r := 0.55
	var y := 0.12
	var top := Vector3(0, h, 0)
	var bot := Vector3(0, -h, 0)
	var ring: Array[Vector3] = [
		Vector3(r, y, 0), Vector3(0, y, r), Vector3(-r, y, 0), Vector3(0, y, -r),
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		st.add_vertex(top)
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(bot)
		st.add_vertex(b)
		st.add_vertex(a)
	st.generate_normals()
	return st.commit()


static func material(color: Color, emission: float = 0.0, metallic: float = 0.0, rough: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m
