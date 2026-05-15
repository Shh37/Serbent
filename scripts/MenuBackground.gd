extends Node2D

# Scrolling background for the main menu.
# Draws grids, thorns, points, beams, and bombs identically to the real game.
# Everything slides towards bottom-right; off-screen chunks are recycled.

const CELL = GameConstants.CELL_SIZE       # 32
const CSIZE = GameConstants.CHUNK_SIZE     # 16
const CPIXEL = GameConstants.CHUNK_PIXEL_SIZE  # 512

var scroll_speed = 24.0  # pixels per second (slow drift)
var scroll_offset = Vector2.ZERO

# Chunk data: chunk_pos (Vector2i) -> { "thorns": [...], "points": [...] }
var chunks: Dictionary = {}

# Beams / Bombs (decorative, timed lifecycle)
var deco_beams: Array = []   # { orientation, index, thickness, zigzag, timer, warning_time, active_time, is_active, show, flicker_t }
var deco_diag_beams: Array = []
var deco_bombs: Array = []   # { center, radius, timer, warning_time, active_time, is_active, show, flicker_t }

func _get_flicker_speed(timer: float, warning_time: float) -> float:
	return lerp(0.04, 0.2, clamp(timer / warning_time, 0.0, 1.0))

var beam_timer = 0.0
var next_beam_time = 2.0
var bomb_timer = 0.0
var next_bomb_time = 3.5

var viewport_size = Vector2(1280, 720)

func _ready():
	z_index = -10
	randomize()
	viewport_size = get_viewport_rect().size
	_rebuild_chunks()

func _process(delta):
	viewport_size = get_viewport_rect().size
	scroll_offset += Vector2(-scroll_speed, -scroll_speed) * delta
	_rebuild_chunks()
	_update_beams(delta)
	_update_bombs(delta)
	queue_redraw()

func set_snake_color(_color: Color):
	# Optional: Change background elements to match skin flavor?
	# For now, just a stub to prevent errors or for future decorative snake.
	pass

# --- Chunk management ---

func _get_visible_chunk_range() -> Array:
	# Which chunk positions are visible (with 1-chunk margin)
	var top_left = -scroll_offset - Vector2(CPIXEL, CPIXEL)
	var bot_right = -scroll_offset + viewport_size + Vector2(CPIXEL, CPIXEL)
	var c_min = Vector2i(floor(top_left.x / CPIXEL), floor(top_left.y / CPIXEL))
	var c_max = Vector2i(floor(bot_right.x / CPIXEL), floor(bot_right.y / CPIXEL))
	return [c_min, c_max]

func _rebuild_chunks():
	var r = _get_visible_chunk_range()
	var c_min: Vector2i = r[0]
	var c_max: Vector2i = r[1]

	var needed = {}
	for cx in range(c_min.x, c_max.x + 1):
		for cy in range(c_min.y, c_max.y + 1):
			var cp = Vector2i(cx, cy)
			needed[cp] = true
			if not chunks.has(cp):
				chunks[cp] = _generate_chunk_data(cp)

	# Cull off-screen chunks
	var to_remove = []
	for cp in chunks.keys():
		if not needed.has(cp):
			to_remove.append(cp)
	for cp in to_remove:
		chunks.erase(cp)

func _generate_chunk_data(cp: Vector2i) -> Dictionary:
	var data = { "thorns": [], "points": [] }
	var base_seed = cp.x * 73856093 + cp.y * 19349663
	var rng = RandomNumberGenerator.new()
	rng.seed = base_seed
	var used = {}

	# Order matches Chunk.gd: clusters -> points -> single thorns

	# 1) Thorn clusters
	var num_clusters = 0
	var rc = rng.randf()
	if rc > 0.8: num_clusters = 2
	elif rc > 0.4: num_clusters = 1

	for _ci in range(num_clusters):
		for _a in range(20):
			var cx = rng.randi_range(2, CSIZE - 3)
			var cy = rng.randi_range(2, CSIZE - 3)
			var center = Vector2i(cx, cy)
			var offsets = []
			var type_r = rng.randf()
			if type_r > 0.9:
				offsets = _x_offsets(rng.randi_range(1, 2), false)
			elif type_r > 0.8:
				offsets = _cross_offsets(2, true)
			elif type_r > 0.65:
				var pn = "corner_5x5_1" if rng.randf() > 0.5 else "corner_5x5_2"
				offsets = _pattern_offsets(pn)
			elif type_r > 0.45:
				var pn = "diag_1" if rng.randf() > 0.5 else "diag_2"
				offsets = _pattern_offsets(pn)
			else:
				offsets = _diamond_offsets(rng.randi_range(1, 2))
			var can_place = true
			for off in offsets:
				if not _is_pos_safe(center + off, used, 1):
					can_place = false
					break
			if can_place:
				for off in offsets:
					var p = center + off
					used[p] = true
					data["thorns"].append(p)
				break

	# 2) Points (min_dist = 2, matching Chunk.gd)
	var num_points = rng.randi_range(2, 4)
	for _i in range(num_points):
		for _a in range(20):
			var lx = rng.randi_range(0, CSIZE - 1)
			var ly = rng.randi_range(0, CSIZE - 1)
			var key = Vector2i(lx, ly)
			if _is_pos_safe(key, used, 2):
				used[key] = true
				data["points"].append({"pos": key})

				break

	# 3) Single thorns (min_dist = 1, matching Chunk.gd)
	var num_thorns = rng.randi_range(3, 5)
	for _i in range(num_thorns):
		for _a in range(20):
			var lx = rng.randi_range(0, CSIZE - 1)
			var ly = rng.randi_range(0, CSIZE - 1)
			var key = Vector2i(lx, ly)
			if _is_pos_safe(key, used, 1):
				used[key] = true
				data["thorns"].append(key)
				break

	return data

# Spacing check identical to Chunk.gd's is_pos_safe (without global/safe-zone checks)
func _is_pos_safe(pos: Vector2i, used_positions: Dictionary, min_dist: int) -> bool:
	for dx in range(-min_dist, min_dist + 1):
		for dy in range(-min_dist, min_dist + 1):
			if used_positions.has(pos + Vector2i(dx, dy)):
				return false
	return true

func _diamond_offsets(radius: int) -> Array:
	var offsets = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if abs(x) + abs(y) == radius:
				offsets.append(Vector2i(x, y))
	return offsets

func _cross_offsets(radius: int, hollow: bool = false) -> Array:
	var offsets = []
	for i in range(-radius, radius + 1):
		if i == 0:
			if not hollow:
				offsets.append(Vector2i(0, 0))
			continue
		offsets.append(Vector2i(i, 0))
		offsets.append(Vector2i(0, i))
	return offsets

func _x_offsets(radius: int, hollow: bool = false) -> Array:
	var offsets = []
	for i in range(-radius, radius + 1):
		if i == 0:
			if not hollow:
				offsets.append(Vector2i(0, 0))
			continue
		offsets.append(Vector2i(i, i))
		offsets.append(Vector2i(i, -i))
	return offsets

func _pattern_offsets(pattern_name: String) -> Array:
	var offsets = []
	match pattern_name:
		"diag_1":
			offsets = [
				Vector2i(0, -1), Vector2i(1, -1),
				Vector2i(-1, 0), Vector2i(1, 0),
				Vector2i(-1, 1), Vector2i(0, 1)
			]
		"diag_2":
			offsets = [
				Vector2i(-1, -1), Vector2i(0, -1),
				Vector2i(-1, 0), Vector2i(1, 0),
				Vector2i(0, 1), Vector2i(1, 1)
			]
		"corner_5x5_1":
			offsets = [
				Vector2i(2, -2), Vector2i(2, -1), Vector2i(1, -2),
				Vector2i(-2, 2), Vector2i(-2, 1), Vector2i(-1, 2)
			]
		"corner_5x5_2":
			offsets = [
				Vector2i(-2, -2), Vector2i(-2, -1), Vector2i(-1, -2),
				Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 2)
			]
	return offsets

# --- Beam management ---

func _update_beams(delta):
	beam_timer += delta
	if beam_timer >= next_beam_time:
		beam_timer = 0.0
		next_beam_time = clampf(randfn(6.0, 3.0), 0.5, 12.5)
		if randf() > 0.4:
			_spawn_beam()
		else:
			_spawn_diag_beam()

	# Update existing beams
	var to_remove = []
	for i in range(deco_beams.size()):
		var b = deco_beams[i]
		b["timer"] -= delta
		if not b["is_active"]:
			b["flicker_t"] += delta
			var f_speed = _get_flicker_speed(b["timer"], b["warning_time"])
			if b["flicker_t"] >= f_speed:
				b["flicker_t"] = 0.0
				b["show"] = not b["show"]
			if b["timer"] <= 0:
				b["is_active"] = true
				b["timer"] = b["active_time"]
				b["show"] = true
		else:
			if b["timer"] <= 0:
				to_remove.append(i)
	to_remove.reverse()
	for i in to_remove:
		deco_beams.remove_at(i)

	# Diagonal beams
	to_remove = []
	for i in range(deco_diag_beams.size()):
		var b = deco_diag_beams[i]
		b["timer"] -= delta
		if not b["is_active"]:
			b["flicker_t"] += delta
			var f_speed = _get_flicker_speed(b["timer"], b["warning_time"])
			if b["flicker_t"] >= f_speed:
				b["flicker_t"] = 0.0
				b["show"] = not b["show"]
			if b["timer"] <= 0:
				b["is_active"] = true
				b["timer"] = b["active_time"]
				b["show"] = true
		else:
			if b["timer"] <= 0:
				to_remove.append(i)
	to_remove.reverse()
	for i in to_remove:
		deco_diag_beams.remove_at(i)

func _spawn_beam():
	# Grid center of the visible area
	var center = (-scroll_offset + viewport_size * 0.5) / CELL
	var idx = int(center.y if randf() > 0.5 else center.x) + randi_range(-8, 8)
	var ori = 0 if randf() > 0.5 else 1  # 0=H, 1=V
	var thick = 1
	var zig = 0
	var vr = randf()
	if vr > 0.8: thick = 3
	elif vr > 0.65: zig = 3
	elif vr > 0.5: zig = 2
	elif vr > 0.35: zig = 1
	deco_beams.append({
		"orientation": ori, "index": idx,
		"thickness": thick, "zigzag": zig,
		"timer": 2.0, "warning_time": 2.0, "active_time": 0.5,
		"is_active": false, "show": true, "flicker_t": 0.0
	})

func _spawn_diag_beam():
	var center = (-scroll_offset + viewport_size * 0.5) / CELL
	var dtype = 0 if randf() > 0.5 else 1  # 0=forward, 1=back
	var k: int
	if dtype == 0:
		k = int(center.x + center.y) + randi_range(-8, 8)
	else:
		k = int(center.x - center.y) + randi_range(-8, 8)
	var thick = 1
	var zig = 0
	var vr = randf()
	if vr > 0.8: thick = 3
	elif vr > 0.65: zig = 3
	elif vr > 0.5: zig = 2
	elif vr > 0.35: zig = 1
	deco_diag_beams.append({
		"type": dtype, "k": k,
		"thickness": thick, "zigzag": zig,
		"timer": 2.0, "warning_time": 2.0, "active_time": 0.5,
		"is_active": false, "show": true, "flicker_t": 0.0
	})

# --- Bomb management ---

func _update_bombs(delta):
	bomb_timer += delta
	if bomb_timer >= next_bomb_time:
		bomb_timer = 0.0
		next_bomb_time = clampf(randfn(6.0, 3.0), 0.5, 12.5)
		_spawn_bomb()

	var to_remove = []
	for i in range(deco_bombs.size()):
		var b = deco_bombs[i]
		b["timer"] -= delta
		if not b["is_active"]:
			b["flicker_t"] += delta
			var f_speed = _get_flicker_speed(b["timer"], b["warning_time"])
			if b["flicker_t"] >= f_speed:
				b["flicker_t"] = 0.0
				b["show"] = not b["show"]
			if b["timer"] <= 0:
				b["is_active"] = true
				b["timer"] = b["active_time"]
				b["show"] = true
		else:
			if b["timer"] <= 0:
				to_remove.append(i)
	to_remove.reverse()
	for i in to_remove:
		deco_bombs.remove_at(i)

func _spawn_bomb():
	var center_grid = Vector2i((-scroll_offset + viewport_size * 0.5) / CELL)
	var offset = Vector2i(randi_range(-8, 8), randi_range(-8, 8))
	var c = center_grid + offset
	var r = 2
	var rv = randf()
	if rv < 0.5: r = 1
	elif rv < 0.85: r = 2
	else: r = 3
	deco_bombs.append({
		"center": c, "radius": r,
		"timer": 2.5, "warning_time": 2.5, "active_time": 0.5,
		"is_active": false, "show": true, "flicker_t": 0.0
	})

# --- Drawing ---

func _draw():
	# Apply scroll offset for all drawing
	draw_set_transform(scroll_offset)

	_draw_chunks()
	_draw_beams()
	_draw_diag_beams()
	_draw_bombs()

func _draw_chunks():
	for cp in chunks.keys():
		var origin = Vector2(cp) * CPIXEL

		# Background fill
		draw_rect(Rect2(origin, Vector2(CPIXEL, CPIXEL)), GameConstants.COLOR_BG)

		# Grid lines
		for i in range(CSIZE + 1):
			var p = i * CELL
			draw_line(origin + Vector2(p, 0), origin + Vector2(p, CPIXEL), GameConstants.COLOR_BLOCK_BORDER, 1.0)
			draw_line(origin + Vector2(0, p), origin + Vector2(CPIXEL, p), GameConstants.COLOR_BLOCK_BORDER, 1.0)

		# Chunk border
		draw_rect(Rect2(origin, Vector2(CPIXEL, CPIXEL)), GameConstants.COLOR_CHUNK_BORDER, false, 4.0)

		var data = chunks[cp]

		# Thorns
		for tpos in data["thorns"]:
			var rect = Rect2(origin + Vector2(tpos) * CELL, Vector2(CELL, CELL))
			draw_rect(rect, GameConstants.COLOR_DANGER)
			draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)

		# Points
		for pdata in data["points"]:
			var ppos = pdata["pos"]
			var color = GameConstants.COLOR_POINT_NORMAL

			var rect = Rect2(origin + Vector2(ppos) * CELL, Vector2(CELL, CELL))
			draw_rect(rect, color)
			draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)

func _beam_zigzag_offset(pos_along: int, amplitude: int) -> int:
	if amplitude == 0: return 0
	if amplitude == 1:
		var p = pos_along % 2
		if p < 0: p += 2
		return p
	elif amplitude == 2:
		var p = pos_along % 4
		if p < 0: p += 4
		var seq = [0, 1, 2, 1]
		return seq[p] - 1
	elif amplitude == 3:
		var p = pos_along % 6
		if p < 0: p += 6
		var seq = [0, 1, 2, 3, 2, 1]
		return seq[p] - 1
	return 0

func _draw_beams():
	for b in deco_beams:
		var color = GameConstants.COLOR_DANGER
		if b["is_active"]:
			var flash_ratio = clamp(b["timer"] / b["active_time"], 0.0, 1.0)
			var boost = flash_ratio * 1.5
			color = Color(color.r + boost, color.g + boost * 0.2, color.b + boost * 0.2)
			color.a = flash_ratio
		else:
			color.a = 0.5 if b["show"] else 0.15
		var center_grid = Vector2i((-scroll_offset + viewport_size * 0.5) / CELL)
		var range_val = 40
		for i in range(-range_val, range_val):
			var pos_along: int
			if b["orientation"] == 0:  # H
				pos_along = center_grid.x + i
			else:
				pos_along = center_grid.y + i
			var z_off = _beam_zigzag_offset(pos_along, b["zigzag"])
			for t_off in range(-b["thickness"] / 2, b["thickness"] / 2 + 1):
				var rect: Rect2
				if b["orientation"] == 0:
					var gy = b["index"] + z_off + t_off
					rect = Rect2(pos_along * CELL, gy * CELL, CELL, CELL)
				else:
					var gx = b["index"] + z_off + t_off
					rect = Rect2(gx * CELL, pos_along * CELL, CELL, CELL)
				draw_rect(rect, color)

func _is_on_diag_beam(grid_pos: Vector2i, b: Dictionary) -> bool:
	var u: int
	var v_base: int
	if b["type"] == 0:  # forward slash
		u = grid_pos.x - grid_pos.y
		v_base = grid_pos.x + grid_pos.y - b["k"]
	else:
		u = grid_pos.x + grid_pos.y
		v_base = grid_pos.x - grid_pos.y - b["k"]
	var z_off = _beam_zigzag_offset(u, b["zigzag"])
	return abs(v_base - z_off) <= b["thickness"] / 2

func _draw_diag_beams():
	for b in deco_diag_beams:
		var color = GameConstants.COLOR_DANGER
		if b["is_active"]:
			var flash_ratio = clamp(b["timer"] / b["active_time"], 0.0, 1.0)
			var boost = flash_ratio * 1.5
			color = Color(color.r + boost, color.g + boost * 0.2, color.b + boost * 0.2)
			color.a = flash_ratio
		else:
			color.a = 0.5 if b["show"] else 0.15
		var center_grid = Vector2i((-scroll_offset + viewport_size * 0.5) / CELL)
		var range_val = 40
		for i in range(-range_val, range_val):
			var x = center_grid.x + i
			var base_y: int
			if b["type"] == 0:
				base_y = b["k"] - x
			else:
				base_y = x - b["k"]
			for dy in range(-b["zigzag"] - b["thickness"] - 2, b["zigzag"] + b["thickness"] + 3):
				var y = base_y + dy
				if _is_on_diag_beam(Vector2i(x, y), b):
					var rect = Rect2(x * CELL, y * CELL, CELL, CELL)
					draw_rect(rect, color)

func _draw_bombs():
	for b in deco_bombs:
		var color = GameConstants.COLOR_DANGER
		if b["is_active"]:
			var flash_ratio = clamp(b["timer"] / b["active_time"], 0.0, 1.0)
			var boost = flash_ratio * 1.5
			color = Color(color.r + boost, color.g + boost * 0.2, color.b + boost * 0.2)
			color.a = flash_ratio
		else:
			color.a = 0.5 if b["show"] else 0.15
		var c = b["center"]
		var rad = b["radius"]
		for x in range(-rad, rad + 1):
			for y in range(-rad, rad + 1):
				if abs(x) + abs(y) <= rad:
					var draw_pos = Vector2(c + Vector2i(x, y)) * CELL
					draw_rect(Rect2(draw_pos, Vector2(CELL, CELL)), color)
					draw_rect(Rect2(draw_pos, Vector2(CELL, CELL)), GameConstants.COLOR_BLOCK_BORDER, false, 1.0)
