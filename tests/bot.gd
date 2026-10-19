extends SceneTree
## Robot de test : joue chaque étape générée (marche, saut au bord, double saut, attente des dalles mobiles).
## Usage : godot --headless --path . --script tests/bot.gd -- <seed_debut> <seed_fin> [dbg <étape>]
## Modificateurs : variable d'environnement BOTMODS, ex. BOTMODS="gravity=2,mirror,crumble"
## Limites connues du robot : ne freine pas (vitesse x1.5, gravité lunaire) et ne sait pas jouer 'commandes inversées'.
var g
func _initialize():
	await process_frame
	await process_frame
	g = root.get_node("Global")
	var args = OS.get_cmdline_user_args()
	g.reset_mods(false)
	var bm := OS.get_environment('BOTMODS')
	for m in bm.split(',', false):
		if '=' in m: g.mods[m.split('=')[0]] = int(m.split('=')[1])
		else: g.mods[m] = true
	var s0 := int(args[0]); var s1 := int(args[1])
	Engine.physics_ticks_per_second = 600
	Engine.time_scale = 10.0
	Engine.max_physics_steps_per_frame = 40
	Engine.max_physics_steps_per_frame = 16
	var ok := 0; var tot := 0; var fails := []
	for sd in range(s0, s1):
		for st in 15:
			if args.size() > 3 and st != int(args[3]): continue
			var r = await run_stage(sd * 13 + 5, st)
			tot += 1
			if r["win"]: ok += 1
			else: fails.append(r)
			print("seed ", sd * 13 + 5, " stage ", st, " win=", r["win"], " t=", snappedf(r["t"], 0.1), " deaths=", r["deaths"], " cur=", r["cur"], "/", r["n"], " kind=", r["kind"])
	print("SUCCES ", ok, "/", tot)
	quit()

func run_stage(seed_v: int, stage: int) -> Dictionary:
	g.reset_run(seed_v)
	g.run["stages"] = [stage]
	g.run["mode"] = "free"
	var lv = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv)
	await physics_frame
	var pl = lv.player
	if OS.get_cmdline_user_args().size() > 2: print(lv.data['steps'].slice(0,4))
	var cur := 0
	var t := 0.0
	var jump_hold := 0
	var last_deaths := 0
	var pending := false
	var reached_arena := false
	var last_pp := Vector3.ZERO
	var kinds = lv.data["steps"]
	var plats = lv.platforms
	var n: int = lv.platforms.size()
	while lv.state == "play" and t < (60.0 if OS.get_cmdline_user_args().size() > 2 else 260.0):
		await physics_frame
		var dt := 1.0 / 60.0
		t += dt
		if pending:
			pending = false
			Input.action_press("jump"); jump_hold = 30
		elif jump_hold > 0:
			jump_hold -= 1
			if jump_hold == 0: Input.action_release("jump")
		var pp: Vector3 = pl.global_position
		if lv.deaths != last_deaths:
			last_deaths = lv.deaths
			if lv.deaths <= 3 and OS.get_cmdline_user_args().size() > 4:
				print('  DEATH #', lv.deaths, ' cur=', cur, ' prev_pp=', last_pp, ' steps=', kinds.slice(maxi(cur-1,0), cur+2), ' plat_cur=', lv.platforms[cur].global_position, lv.platforms[cur].size, ' plat_next=', lv.platforms[mini(cur+1,n-1)].global_position, lv.platforms[mini(cur+1,n-1)].size)
		last_pp = pp
		if cur == 0 and lv.deaths == 0 and t > 0.2 and t < 2.2 and int(t*60) % 3 == 0 and OS.get_cmdline_user_args().size() > 4:
			print('   tr t=', snappedf(t,0.01), ' pp=', pp, ' vy=', snappedf(pl.velocity.y,0.1), ' v=', Vector2(pl.velocity.x, pl.velocity.z), ' floor=', pl.is_on_floor(), ' fwd=', Input.is_action_pressed('forward'))
		if true:
			for i in range(n - 1, -1, -1):
				var p = lv.platforms[i]
				var loc = pp - p.global_position
				if (pl.is_on_floor() or p.kind == 'b') and absf(loc.x) <= p.size.x / 2.0 + 0.3 and absf(loc.z) <= p.size.z / 2.0 + 0.3 and (pp.y - (p.global_position.y + 0.5)) < (0.6 if (pl.is_on_floor() or p.kind != 'b') else (9.0 if cur == i else 1.3)) and (pp.y - (p.global_position.y + 0.5)) > -0.6:
					cur = i; break
		if lv.boss != null and cur == n - 1:
			reached_arena = true
			break
		var ti: int = mini(cur + 1, n - 1)
		if str(plats[cur].kind) == 'p':
			ti = cur # on marche jusqu'au centre pour déclencher le portail
		var tp: Vector3 = lv.platforms[ti].global_position + Vector3(0, 0.5, 0)
		# cible = dalle à bumper : on vise un couloir latéral (pas le centre qui repousse)
		if str(plats[ti].kind) == 'r' and ti != cur:
			var to_b := Vector3(tp.x - pp.x, 0, tp.z - pp.z).normalized()
			var perp_b := Vector3(-to_b.z, 0, to_b.x)
			tp = Vector3(tp.x + perp_b.x * 1.8, tp.y, tp.z + perp_b.z * 1.8)
		# bumper : on le contourne par le côté (waypoint) tant qu'on n'a pas dépassé son centre
		if str(plats[cur].kind) == 'r' and pl.is_on_floor():
			var pc: Vector3 = plats[cur].global_position
			var to_t := Vector3(tp.x - pc.x, 0, tp.z - pc.z).normalized()
			var perp := Vector3(-to_t.z, 0, to_t.x)
			if (pp - pc).dot(to_t) < 0.9:
				var side := perp if (pp - pc).dot(perp) >= 0.0 else -perp
				tp = Vector3(pc.x + side.x * 1.7 + to_t.x * 0.9, tp.y, pc.z + side.z * 1.7 + to_t.z * 0.9)
		var flat := Vector3(tp.x - pp.x, 0, tp.z - pp.z)
		var dist := flat.length()
		var dir := flat.normalized()
		pl.yaw = atan2(-dir.x, -dir.z)
		if false and OS.get_cmdline_user_args().size() > 2:
			print('  dbg t=', snappedf(t,0.1), ' pp=', pp, ' cur=', cur, ' tp=', tp, ' floor=', pl.is_on_floor(), ' vy=', pl.velocity.y, ' tgt_now=', lv.platforms[mini(cur+1,n-1)].global_position)
		var tkind: String = str(plats[ti].kind)
		var tpl = plats[ti]
		var move := true
		var want_jump := false
		if pl.is_on_floor():
			var cp = lv.platforms[cur]
			var nxt: Vector3 = pp + dir * 0.7
			var loc2 = nxt - cp.global_position
			var outside: bool = absf(loc2.x) > cp.size.x / 2.0 or absf(loc2.z) > cp.size.z / 2.0
			if str(cp.kind) == 'k' and cp.solid_time_left() < 0.5 and ti != cur:
				want_jump = true
			elif outside and ti != cur:
				var tg: float = 3.0 if ti == 0 else float(kinds[ti - 1][0])
				var nominal := Vector2(tpl._origin.x - pp.x, tpl._origin.z - pp.z).length()
				var stable: bool = str(cp.kind) in ['n', 'c', 's', 'v', 'b', 'y', 't', 'j', 'p', 'q', 'r', 'g']
				if not stable:
					want_jump = true # on n'attend pas sur une dalle instable
				elif tkind == "m" and dist > tg + 3.2:
					move = false
				elif tkind == "o" and dist > nominal + 0.3:
					move = false
				elif tkind == "l" and absf(tpl.global_position.y - tpl._origin.y) > 0.6:
					move = false
				elif (tkind == "k" or tkind == "z") and tpl.solid_time_left() < 1.1:
					move = false
				else:
					want_jump = true
		else:
			var cpl = lv.platforms[cur]
			var ctop: float = cpl.global_position.y + 0.5
			var loc3 = pp - cpl.global_position
			var beyond: bool = absf(loc3.x) > cpl.size.x / 2.0 + 0.25 or absf(loc3.z) > cpl.size.z / 2.0 + 0.25
			var thalf: float = 2.0
			if pl.velocity.y < 0.5 and pl.air_jumps > 0 and beyond and dist > thalf + 1.3 and pp.y < tp.y + 1.0:
				want_jump = true
			elif pl.velocity.y < -1.0 and pl.air_jumps > 0 and pp.y < tp.y + 0.8 and dist > 0.8 and (pp.y < ctop - 0.8 or beyond):
				want_jump = true
		# esquive : saute quand un projectile (canon) arrive tout près
		if pl.is_on_floor() and jump_hold == 0 and not pending:
			for c in lv.get_children():
				if c is Area3D and c.get("velocity") != null and c.velocity.length() > 1.0:
					var rel: Vector3 = c.global_position - pp
					if Vector2(rel.x, rel.z).length() < 3.2 and absf(rel.y - 1.0) < 1.6:
						want_jump = true
		if move: Input.action_press("forward")
		else: Input.action_release("forward")
		if want_jump and not pending:
			if Input.is_action_pressed("jump"):
				Input.action_release("jump"); jump_hold = 0; pending = true
			else:
				Input.action_press("jump"); jump_hold = 30
	Input.action_release("forward"); Input.action_release("jump")
	var res = {"win": lv.state == "won" or reached_arena, "t": t, "deaths": lv.deaths, "cur": cur, "n": n, "kind": ("n" if cur + 1 >= n else str(plats[mini(cur + 1, n - 1)].kind))}
	root.remove_child(lv); lv.free()
	return res
