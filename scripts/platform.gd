extends AnimatableBody3D
## Plateforme :
##   n normale | m mobile | f friable | c checkpoint | b trampoline | s tourniquet
##   k clignotante | v tapis roulant | o orbitale | l ascenseur
##   t canon | j lanceur directionnel | y interrupteur | z pont (activé par y) | p portail d'entrée | q portail de sortie

const Models = preload("res://scripts/models.gd")
const Textures = preload("res://scripts/textures.gd")
const Decor = preload("res://scripts/decor.gd")
const Fx = preload("res://scripts/fx.gd")
const Projectile = preload("res://scripts/projectile.gd")

const BLINK_ON := 1.8
const BLINK_OFF := 1.1
const CANNON_PERIOD := 2.4
const BRIDGE_TIME := 8.0

const SYMBOLS := {
	"m": "<>", "f": "x", "k": "~", "v": ">>", "o": "O", "l": "^v", "b": "^", "s": "*",
	"y": "SW", "z": "[]", "j": "=>", "t": "o=", "p": "()", "q": "()", "c": "CP",
}
## Palette adaptée au daltonisme (Okabe-Ito)
const CB_COLORS := {
	"m": Color(0.0, 0.45, 0.7), "f": Color(0.84, 0.37, 0.0), "c": Color(0.0, 0.62, 0.45), "b": Color(0.8, 0.47, 0.65),
	"k": Color(0.94, 0.89, 0.26), "v": Color(0.45, 0.45, 0.45), "o": Color(0.34, 0.71, 0.91), "l": Color(0.9, 0.62, 0.0),
	"t": Color(0.6, 0.15, 0.1), "j": Color(1.0, 0.9, 0.2), "y": Color(0.5, 0.5, 0.5), "z": Color(0.3, 0.8, 0.9),
	"p": Color(0.55, 0.3, 0.8), "q": Color(0.55, 0.3, 0.8),
}

var kind := "n"
var size := Vector3(4, 1, 4)
var top_color := Color.WHITE
var side_color := Color(0.5, 0.4, 0.3)
var theme_idx := 0
var prop_seed := 0
var move_axis := Vector3.RIGHT   # latéral (mobile, orbite, canon)
var forward := Vector3.FORWARD   # avant (orbite, tapis, lanceur)
var move_amp := 2.5
var move_speed := 1.1
var level = null
var partner = null               # y -> z (pont), p -> q (sortie du portail)

var _origin := Vector3.ZERO
var _t := 0.0
var _state := 0 # f : 0 repos, 1 tremble, 2 tombe, 3 disparue
var _state_t := 0.0
var _fall_speed := 0.0
var _activated := false
var _visual: Node3D
var _mat: StandardMaterial3D
var _body_mat: StandardMaterial3D
var _col: CollisionShape3D
var _beam: AnimatableBody3D
var _blink_phase := 0.0
var _solid := true
var _active := false       # z : pont actif
var _active_t := 0.0
var _fire_t := 0.0
var _cannon: Node3D
var _cannon_mat: StandardMaterial3D
var _cannon_dir := Vector3.RIGHT
var _button_mat: StandardMaterial3D


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
		"t": tcol = Color(0.75, 0.3, 0.3)
		"j": tcol = Color(1.0, 0.75, 0.1)
		"y": tcol = Color(0.55, 0.55, 0.6)
		"z": tcol = Color(0.4, 0.9, 1.0)
		"p", "q": tcol = Color(0.6, 0.35, 0.9)
	if Global.options["colorblind"] and CB_COLORS.has(kind):
		tcol = CB_COLORS[kind]

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
	_body_mat = bmat

	# dessus coloré
	var slab := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(size.x + 0.04, 0.18, size.z + 0.04)
	slab.mesh = sm
	_mat = Models.material(tcol, 0.0, 0.0, 0.8)
	_mat.albedo_texture = Textures.speckle(2)
	_mat.uv1_triplanar = true
	_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	if kind in ["b", "k", "o", "l", "j", "p", "q"]:
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

	_build_special()

	# symboles sur les dalles (aide pour le daltonisme)
	if (Global.options["symbols"] or Global.options["colorblind"]) and SYMBOLS.has(kind):
		var lab := Label3D.new()
		lab.text = SYMBOLS[kind]
		lab.font_size = 96
		lab.pixel_size = 0.012
		lab.modulate = Color(1, 1, 1)
		lab.outline_size = 16
		lab.outline_modulate = Color(0, 0, 0)
		lab.rotation_degrees.x = -90.0
		lab.position = Vector3(size.x * 0.5 - 0.9, size.y * 0.5 + 0.03, size.z * 0.5 - 0.7)
		_visual.add_child(lab)

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
	_col.disabled = kind == "z"
	add_child(_col)

	if kind in ["f", "c", "b", "j", "y", "p"]:
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		var ac := CollisionShape3D.new()
		var area_shape := BoxShape3D.new()
		area_shape.size = Vector3(size.x, 0.8, size.z)
		ac.position.y = size.y * 0.5 + 0.35
		if kind == "p":
			area_shape.size = Vector3(1.8, 2.4, 1.8)
			ac.position.y = size.y * 0.5 + 1.2
		ac.shape = area_shape
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


## Éléments visuels propres à chaque type (chevrons, canon, anneau de portail…).
func _build_special() -> void:
	match kind:
		"v":
			var dir := forward if int(absi(prop_seed) % 2) == 0 else -forward
			constant_linear_velocity = dir * 3.0
			_chevrons(dir, Color(1.0, 0.85, 0.1))
		"j":
			_chevrons(forward, Color(1.0, 0.95, 0.3))
		"z":
			_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mat.albedo_color.a = 0.25
			_body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_body_mat.albedo_color.a = 0.2
		"y":
			var btn := MeshInstance3D.new()
			var bc := CylinderMesh.new()
			bc.top_radius = 0.7
			bc.bottom_radius = 0.8
			bc.height = 0.15
			btn.mesh = bc
			_button_mat = Models.material(Color(1.0, 0.2, 0.15), 1.5)
			btn.material_override = _button_mat
			btn.position = Vector3(0, size.y * 0.5 + 0.08, 0)
			_visual.add_child(btn)
		"p", "q":
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.95
			tm.outer_radius = 1.15
			tm.rings = 16
			tm.ring_segments = 8
			ring.mesh = tm
			ring.rotation_degrees.x = 90.0
			ring.position = Vector3(0, size.y * 0.5 + 1.2, 0)
			ring.material_override = Models.material(Color(0.7, 0.4, 1.0), 2.5)
			_visual.add_child(ring)
			var disc := MeshInstance3D.new()
			var dm := CylinderMesh.new()
			dm.top_radius = 0.95
			dm.bottom_radius = 0.95
			dm.height = 0.02
			disc.mesh = dm
			disc.rotation_degrees.x = 90.0
			disc.position = ring.position
			var dmat := Models.material(Color(0.8, 0.5, 1.0, 0.35), 1.5)
			dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			disc.material_override = dmat
			_visual.add_child(disc)
		"t":
			var sgn := 1.0 if int(absi(prop_seed) % 2) == 0 else -1.0
			var half_r := (size.x if absf(move_axis.x) > 0.5 else size.z) * 0.5
			_cannon_dir = -move_axis * sgn
			_cannon = Node3D.new()
			_cannon.position = move_axis * sgn * (half_r - 0.4) + Vector3(0, size.y * 0.5, 0)
			_visual.add_child(_cannon)
			var base := MeshInstance3D.new()
			var bb := BoxMesh.new()
			bb.size = Vector3(0.9, 0.7, 0.9)
			base.mesh = bb
			base.material_override = Models.material(Color(0.25, 0.25, 0.28), 0.0, 0.5, 0.5)
			base.position.y = 0.35
			_cannon.add_child(base)
			var barrel := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.28
			cyl.bottom_radius = 0.34
			cyl.height = 1.1
			barrel.mesh = cyl
			_cannon_mat = Models.material(Color(0.5, 0.15, 0.12), 0.3, 0.5, 0.4)
			barrel.material_override = _cannon_mat
			barrel.quaternion = Quaternion(Vector3.UP, _cannon_dir)
			barrel.position = Vector3(0, 0.95, 0) + _cannon_dir * 0.45
			_cannon.add_child(barrel)
			_fire_t = float(absi(prop_seed) % 100) / 100.0 * CANNON_PERIOD


func _chevrons(dir: Vector3, color: Color) -> void:
	var along_x := absf(dir.x) > 0.5
	for j in 3:
		var chev := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.28, 0.04, size.z * 0.8) if along_x else Vector3(size.x * 0.8, 0.04, 0.28)
		chev.mesh = cb
		chev.material_override = Models.material(color, 1.5)
		var off := (j - 1) * 1.0
		var px := off * signf(dir.x) if along_x else 0.0
		var pz := off * signf(dir.z) if not along_x else 0.0
		chev.position = Vector3(px, size.y * 0.5 + 0.03, pz)
		_visual.add_child(chev)


func is_solid() -> bool:
	return _solid


## Temps restant avant que la dalle ne disparaisse (grand si elle est stable).
func solid_time_left() -> float:
	if kind == "z":
		return _active_t if _active else 0.0
	if kind != "k":
		return 99.0
	var c := fposmod(_t + _blink_phase, BLINK_ON + BLINK_OFF)
	return (BLINK_ON - c) if c < BLINK_ON else 0.0


## Interrupteur : fait apparaître le pont (z) pendant 8 secondes.
func activate() -> void:
	if kind != "z":
		return
	_active = true
	_active_t = BRIDGE_TIME
	_col.set_deferred("disabled", false)
	_visual.visible = true
	_mat.albedo_color.a = 1.0
	_body_mat.albedo_color.a = 1.0


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
		"t":
			_fire_t += delta
			if _fire_t >= CANNON_PERIOD - 0.5:
				_cannon_mat.emission_energy_multiplier = 3.0 # avertissement avant le tir
			if _fire_t >= CANNON_PERIOD:
				_fire_t = 0.0
				_cannon_mat.emission_energy_multiplier = 0.3
				_shoot()
		"z":
			if _active:
				_active_t -= delta
				if _active_t < 1.5:
					_visual.visible = int(_active_t * 12.0) % 2 == 0
				if _active_t <= 0.0:
					_active = false
					_col.disabled = true
					_visual.visible = true
					_mat.albedo_color.a = 0.25
					_body_mat.albedo_color.a = 0.2
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


func _shoot() -> void:
	var shot := Projectile.new()
	shot.velocity = _cannon_dir * 7.5
	shot.radius = 0.38
	shot.life = ((size.x if absf(_cannon_dir.x) > 0.5 else size.z) + 4.0) / 7.5
	shot.position = global_position + _cannon_dir * 1.2 + Vector3(0, size.y * 0.5 + 0.95, 0) + _cannon.position * Vector3(1, 0, 1)
	get_parent().add_child(shot)
	Global.play_sfx("cannon")


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
		"j":
			var sg := sqrt(Global.gravity_scale())
			body.launch(forward * 11.0 * sg + Vector3(0, 9.5 * sg, 0))
		"y":
			if partner:
				partner.activate()
				Global.play_sfx("checkpoint", 1.3)
				if _button_mat:
					_button_mat.albedo_color = Color(0.2, 1.0, 0.3)
					_button_mat.emission = Color(0.2, 1.0, 0.3)
					get_tree().create_timer(BRIDGE_TIME).timeout.connect(_reset_button)
		"p":
			if partner:
				var dest: Vector3 = partner.global_position + Vector3(0, partner.size.y * 0.5 + 0.3, 0)
				Fx.burst(get_parent(), global_position + Vector3(0, 1.2, 0), Color(0.8, 0.5, 1.0), 20, 5.0, false)
				body.teleport(dest)
				Fx.burst(get_parent(), dest + Vector3(0, 1.0, 0), Color(0.8, 0.5, 1.0), 20, 5.0, false)
				Global.play_sfx("portal")
				Global.vibrate(40)


func _reset_button() -> void:
	if _button_mat:
		_button_mat.albedo_color = Color(1.0, 0.2, 0.15)
		_button_mat.emission = Color(1.0, 0.2, 0.15)
