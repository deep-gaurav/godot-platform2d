extends StaticBody2D

export(bool) var MovingPlatform = false setget set_moving_platform
var last_position = null

func _ready():
	if MovingPlatform:
		set_physics_process(true)  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
		last_position = get_global_position()  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review

func set_moving_platform(b):
	MovingPlatform = b
	set_physics_process(MovingPlatform)  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	if is_inside_tree():
		last_position=global_position
	else:
		last_position=position
func _physics_process(delta):  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	var position = get_global_position()  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	set_constant_linear_velocity((position - last_position) / delta)
	last_position = position

func aligned(p1, p2, p3):
	return (p2-p1).normalized().dot((p2-p3).normalized()) > 0.999

func baked_points_and_length(curve):
	#return { points = curve.get_baked_points(), length = curve.get_baked_length() }
	var points = PoolVector2Array()  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	var length = 0
	for i in range(curve.get_point_count()-1):
		var subcurve = Curve2D.new()
		subcurve.add_point(curve.get_point_position(i), curve.get_point_in(i), curve.get_point_out(i))  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
		subcurve.add_point(curve.get_point_position(i+1), curve.get_point_in(i+1), curve.get_point_out(i+1))  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
		subcurve.set_bake_interval(curve.get_bake_interval())
		points.append_array(subcurve.get_baked_points())
		if i < curve.get_point_count()-2:
			points.remove(points.size()-1)  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
		length += subcurve.get_baked_length()
	if points.size() >= 5:
		var i = 2
		while i < points.size() - 2:
			if    aligned(points[i-2], points[i+2], points[i-1]) \
			   && aligned(points[i-2], points[i+2], points[i]) \
			   && aligned(points[i-2], points[i+2], points[i+1]):
				points.remove(i)  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
			else:
				i += 1
	return { points = points, length = length }

func baked_points(curve):
	return baked_points_and_length(curve).points

func baked_length(curve):
	return baked_points_and_length(curve).length

func draw_border(point_array, thickness, position, sections, left_overflow = 0.0):
	var point_count = point_array.size()
	var points = PoolVector2Array()  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	points.push_back(Vector2(0, 0))
	points.push_back(Vector2(0, 0))
	points.push_back(Vector2(0, 0))
	points.push_back(Vector2(0, 0))
	var colors = PoolColorArray()  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	colors.push_back(Color(1.0, 1.0, 1.0))
	colors.push_back(Color(1.0, 1.0, 1.0))
	colors.push_back(Color(1.0, 1.0, 1.0))
	colors.push_back(Color(1.0, 1.0, 1.0))
	var uvs = PoolVector2Array()  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 0))
	var normal = PoolVector2Array()  #-- NOTE: Automatically converted by Godot 2 to 3 converter, please review
	for i in range(point_count):
		var i0 = i-1
		if i0 == -1:
			i0 = 0
		var i2 = i+1
		if i2 == point_count:
			i2 = point_count-1
		normal.append((point_array[i2] - point_array[i0]).rotated(-PI/2).normalized() * thickness)
	var u = left_overflow
	var texture_index = 0
	var texture = sections[0].texture
	var limit   = sections[0].limit
	var scale   = sections[0].scale
	if u != 0.0:
		points[3] = point_array[0] + normal[0] * position
		points[2] = point_array[0] - normal[0] * (1-position)
		var overflow = normal[0].rotated(-PI/2).normalized() * left_overflow / scale
		points[0] = points[3] + overflow
		points[1] = points[2] + overflow
		uvs[0] = Vector2(0, 1)
		uvs[1] = Vector2(0, 0)
		uvs[2] = Vector2(u, 0)
		uvs[3] = Vector2(u, 1)
		draw_polygon(points, colors, uvs, texture)
	for i in range(point_count-1):
		var interval = (point_array[i+1] - point_array[i]).length()
		if i == 0:
			points[0] = point_array[i] + normal[i] * position
			points[1] = point_array[i] - normal[i] * (1-position)
		else:
			points[0] = points[3]
			points[1] = points[2]
		uvs[0] = Vector2(u, 1)
		uvs[1] = Vector2(u, 0)
		var length = (point_array[i+1] - point_array[i]).length()
		var next_u = u + length * scale
		if next_u >= limit:
			var r = (limit - u) / (next_u - u)
			var p = point_array[i] + r * (point_array[i+1] - point_array[i])
			var n = (normal[i] + r * (normal[i+1] - normal[i])).normalized() * thickness
			points[2] = p - n * (1-position)
			points[3] = p + n * position
			uvs[2] = Vector2(limit, 0)
			uvs[3] = Vector2(limit, 1)
			draw_polygon(points, colors, uvs, texture)
			texture_index = texture_index + 1
			if texture_index >= sections.size():
				u = next_u
				break
			texture = sections[texture_index].texture
			limit   = sections[texture_index].limit
			scale   = sections[texture_index].scale
			points[0] = points[3]
			points[1] = points[2]
			uvs[0] = Vector2(0, 1)
			uvs[1] = Vector2(0, 0)
			u = length * (1 - r) * scale
			points[2] = point_array[i+1] - normal[i+1] * (1-position)
			points[3] = point_array[i+1] + normal[i+1] * position
			uvs[2] = Vector2(u, 0)
			uvs[3] = Vector2(u, 1)
			draw_polygon(points, colors, uvs, texture)
		else:
			points[2] = point_array[i+1] - normal[i+1] * (1-position)
			points[3] = point_array[i+1] + normal[i+1] * position
			uvs[2] = Vector2(next_u, 0)
			uvs[3] = Vector2(next_u, 1)
			draw_polygon(points, colors, uvs, texture)
			u = next_u
	if u < limit:
		points[0] = points[3]
		points[1] = points[2]
		var overflow = normal[point_count-2].rotated(PI/2).normalized() * (limit - u) / scale
		points[2] = points[2] + overflow
		points[3] = points[3] + overflow
		uvs[0] = Vector2(u, 1)
		uvs[1] = Vector2(u, 0)
		uvs[2] = Vector2(limit, 0)
		uvs[3] = Vector2(limit, 1)
		draw_polygon(points, colors, uvs, texture)

