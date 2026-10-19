extends AnimatableBody3D
## Plateforme :
##   n normale | m mobile | f friable | c checkpoint | b trampoline | s tourniquet
##   k clignotante | v tapis roulant | o orbitale | l ascenseur

const Models = preload("res://scripts/models.gd")
const Textures = preload("res://scripts/textures.gd")
const Decor = preload("res://scripts/decor.gd")
const Fx = preload("res://scripts/fx.gd")

const BLINK_ON := 1.8
const BLINK_OFF := 1.1

var kind := "n"
var size := Vector3(4, 1, 4)
var top_color := Color.WHITE
var side_color := Color(0.5, 0.4, 0.3)
var theme_idx := 0
var prop_seed := 0
var move_axis := Vector3.RIGHT   # latéral (mobile, orbite)
var forward := Vector3.FORWARD   # avant (orbite, tapis)
var move_amp := 2.5
var move_speed := 1.1
var level = null

var _origin := Vector3.ZERO
var _t := 0.0
var _state := 0 # f : 0 repos, 1 tremble, 2 tombe, 3 disparue
var _state_t := 0.0
var _fall_speed := 0.0
var _activated := false
var _visual: Node3D
var _mat: StandardMaterial3D
var _col: CollisionShape3D
var _beam: AnimatableBody3D
var _blink_phase := 0.0
var _solid := true


func _ready() -> void:
	sync_to_physics = true
	_origin = position
	_blink_phase = float(absi(prop_seed) % 1000) / 1000.0 * (BLINK_ON + BLINK_OFF)
	_t = float(absi(prop_seed) % 628) / 100.0 if kind in ["m", "o", "l"] else 0.0

	var tcol := top_color
	match kind:
		"m": tcol = Color(0.35, 0.7, 1.0)
		"f": tcol = Color(1.0, 0.6, 0.25)
		"c": tcol = Color(0.3, 0.55, 1.0)
		"b": tcol = Color(1.0, 0.4, 0.75)
		"s": tcol = top_color.darkened(0.25)
		"k": tcol = Color(0.75, 0.45, 1.0)
		"v": tcol = Color(0.28, 0.28, 0.32)
		"o": tcol = Color(0.25, 0.85, 0.75)
		"l": tcol = Color(1.0, 0.85, 0.25)

	_visual = Node3D.new()
	add_child(_visual)

	# corps en pierre texturée
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, size.y - 0.18, size.z)
	body.mesh = bm
	var bmat := Models.material(side_color, 0.0, 0.0, 0.9)
	bmat.albedo_texture = Textures.stone(3)
	bmat.uv1_triplanar = true
	bmat.uv1_scale = Vector3(0.45, 0.45, 0.45)
	bmat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	body.material_override = bmat
	body.position.y = -0.09
	_visual.add_child(body)

	# dessus coloré
	var slab := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(size.x + 0.04, 0.18, size.z + 0.04)
	slab.mesh = sm
	_mat = Models.material(tcol, 0.0, 0.0, 0.8)
	_mat.albedo_texture = Textures.speckle(2)
	_mat.uv1_triplanar = true
	_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	if kind in ["b", "k", "o", "l"]:
		_mat.emission_enabled = true
		_mat.emission = tcol
		_mat.emission_energy_multiplier = 0.6
	slab.material_override = _mat
	slab.position.y = size.y * 0.5 - 0.09
	_visual.add_child(slab)

	# pointe rocheuse sous la dalle
	var under_root := Node3D.new()
	under_root.scale = Vector3(size.x, 1.6, size.z)
	under_root.position.y = -size.y * 0.5 - 0.8
	_visual.add_child(under_root)
	var under := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.7071
	cm.bottom_radius = 0.05
	cm.height = 1.0
	cm.radial_segments = 4
	cm.rings = 1
	under.mesh = cm
	under.rotation.y = PI * 0.25
	under.material_override = bmat
	under_root.add_child(under)

	# chevrons du tapis roulant
	if kind == "v":
		var dir := forward if int(absi(prop_seed) % 2) == 0 else -forward
		constant_linear_velocity = dir * 3.0
		var along_x := absf(dir.x) > 0.5
		for j in 3:
			var chev := MeshInstance3D.new()
			var cb := BoxMesh.new()
			cb.size = Vector3(0.25, 0.04, size.z * 0.8) if along_x else Vector3(size.x * 0.8, 0.04, 0.25)
			chev.mesh = cb
			chev.material_override = Models.material(Color(1.0, 0.85, 0.1), 1.0)
			var off := (j - 1) * 1.1
			chev.position = Vector3(off * signf(dir.x) if along_x else 0.0, size.y * 0.5 + 0.02, off * signf(dir.z) if not along_x else 0.0)
			_visual.add_child(chev)

	# accessoire décoratif sur les dalles fixes
	if kind in ["n", "c", "f"] and size.x >= 3.0 and size.z >= 3.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = prop_seed
		if rng.randf() < 0.65:
			var pr := Decor.prop(theme_idx, rng)
			var sx := 1.0 if rng.randf() < 0.5 else -1.0
			var sz := 1.0 if rng.randf() < 0.5 else -1.0
			pr.position = Vector3(sx * (size.x * 0.5 - 0.6), size.y * 0.5, sz * (size.z * 0.5 - 0.6))
			pr.rotation.y = rng.randf() * TAU
			_visual.add_child(pr)

	_col = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	_col.shape = bs
	add_child(_col)

	if kind in ["f", "c", "b"]:
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		var ac := CollisionShape3D.new()
		var area_shape := BoxShape3D.new()
		area_shape.size = Vector3(size.x, 0.8, size.z)
		ac.shape = area_shape
		ac.position.y = size.y * 0.5 + 0.35
		area.add_child(ac)
		add_child(area)
		area.body_entered.connect(_on_body_entered)

	if kind == "s":
		_beam = AnimatableBody3D.new()
		_beam.sync_to_physics = true
		_beam.position.y = size.y * 0.5 + 0.35
		var beam_len := minf(size.x, size.z) * 0.95
		var bmesh := MeshInstance3D.new()
		var bbox := BoxMesh.new()
		bbox.size = Vector3(beam_len, 0.5, 0.35)
		bmesh.mesh = bbox
		bmesh.material_override = Models.material(Color(0.9, 0.15, 0.15), 0.6)
		_beam.add_child(bmesh)
		var bc := CollisionShape3D.new()
		var bsh := BoxShape3D.new()
		bsh.size = bbox.size
		bc.shape = bsh
		_beam.add_child(bc)
		add_child(_beam)


func is_solid() -> bool:
	return _solid


## Temps restant avant que la dalle clignotante ne disparaisse (grand si non clignotante).
func solid_time_left() -> float:
	if kind != "k":
		return 99.0
	var c := fposmod(_t + _blink_phase, BLINK_ON + BLINK_OFF)
	return (BLINK_ON - c) if c < BLINK_ON else 0.0


func _physics_process(delta: float) -> void:
	match kind:
		"m":
			_t += delta
			position = _origin + move_axis * sin(_t * move_speed) * move_amp
		"o":
			_t += delta
			var a := _t * 0.9
			position = _origin + move_axis * cos(a) * 2.0 + forward * sin(a) * 2.0
		"l":
			_t += delta
			position = _origin + Vector3(0, sin(_t * 0.8) * 1.6, 0)
		"f":
			_update_fall(delta)
		"s":
			_beam.rotation.y += delta * 1.8
		"k":
			_t += delta
			var c := fposmod(_t + _blink_phase, BLINK_ON + BLINK_OFF)
			var on := c < BLINK_ON
			if on != _solid:
				_solid = on
				_col.disabled = not on
				_visual.visible = on
			if on and c > BLINK_ON - 0.45:
				_visual.visible = int(c * 14.0) % 2 == 0 # avertissement : la dalle clignote vite


func _update_fall(delta: float) -> void:
	match _state:
		1:
			_state_t -= delta
			_visual.position = Vector3(randf_range(-0.06, 0.06), 0.0, randf_range(-0.06, 0.06))
			if _state_t <= 0.0:
				_state = 2
				_state_t = 2.5
				_fall_speed = 0.0
				_visual.position = Vector3.ZERO
		2:
			_fall_speed += 22.0 * delta
			position.y -= _fall_speed * delta
			_state_t -= delta
			if _state_t <= 0.0:
				_state = 3
				_state_t = 2.0
				_col.disabled = true
				_visual.visible = false
		3:
			_state_t -= delta
			if _state_t <= 0.0:
				position = _origin
				_col.disabled = false
				_visual.visible = true
				_state = 0


func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"f":
			if _state == 0:
				_state = 1
				_state_t = 0.8 if Global.mods["crumble"] else 0.6
				Global.play_sfx("crumble", 1.0, -6.0)
		"c":
			if not _activated:
				_activated = true
				_mat.albedo_color = Color(0.3, 1.0, 0.45)
				_mat.emission_enabled = true
				_mat.emission = Color(0.3, 1.0, 0.45)
				_mat.emission_energy_multiplier = 0.6
				Global.play_sfx("checkpoint")
				Fx.burst(get_parent(), global_position + Vector3(0, 1.0, 0), Color(0.4, 1.0, 0.5), 16, 3.5, false)
				if level:
					level.set_checkpoint(global_position + Vector3(0, size.y * 0.5 + 0.3, 0))
		"b":
			body.bounce(17.0)
