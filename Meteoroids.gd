extends Node2D

# Generic object that can be drawn in Meteoroids
class GameObject:
	var pos := Vector2.ZERO # Position
	var rot := 0.0 # Rotation
	
	var line := Color(1,1,1)
	var fill := Color(0,0,1)
	
	# An array of shapes (which in turn are arrays of Vector2s) that are
	# used for draw_object()
	var pts := []
	
	var polygon := false # Flag for connecting last point to first point
	
	func _init()->void:
		# Setup for "class" checks later
		set_meta("GameObject", 0)

class Ship extends GameObject:
	var velocity := Vector2.ZERO
	var max_vel := Vector2(50,50)
	
	var rot_speed := PI
	var speed := 5
	
	func _init()->void:
		# TODO: Change points so rotation is centered
		pts = [[
			Vector2(10, 0),
			Vector2(-10, 8),
			Vector2(-8, 4),
			Vector2(-8, -4),
			Vector2(-10, -8)
			]]
		
		polygon = true
		
		set_meta("Ship", 0)
	
	func process(delta : float)->void:
		if Input.is_action_pressed("turn_left"):
			rot -= rot_speed * delta
			
			if rot <= -2 * PI:
				rot += 2 * PI
		
		if Input.is_action_pressed("turn_right"):
			rot += rot_speed * delta
		
			if rot >= 2 * PI:
				rot -= 2 * PI
		
		if Input.is_action_pressed("boost"):
			velocity += Vector2.RIGHT.rotated(rot) * speed * delta
		
			if abs(velocity.x) > max_vel.x:
				velocity.x = sign(velocity.x) * max_vel.x
		
			if abs(velocity.y) > max_vel.y:
				velocity.y = sign(velocity.y) * max_vel.y
		
		if Input.is_action_just_pressed("shoot"):
			print("shoot")
		
		pos += velocity

class PlayField extends GameObject:
	var size := 600.0
	var buffer := 10.0
	
	func _init()->void:
		pts = [[
			Vector2(-size / 2, -size / 2),
			Vector2(size / 2, -size /2),
			Vector2(size / 2, size / 2),
			Vector2(-size / 2, size / 2)
			]]
		
		polygon = true
		
		set_meta("PlayField", 0)
	
	func warp_object(obj : GameObject)->void:
		if obj.pos.x < -(size / 2) - buffer:
			obj.pos.x = (size / 2) + buffer
		elif obj.pos.x > (size / 2) + buffer:
			obj.pos.x = -(size / 2) - buffer
		
		if obj.pos.y < -(size / 2) - buffer:
			obj.pos.y = (size / 2) + buffer
		elif obj.pos.y > (size / 2) + buffer:
			obj.pos.y = -(size / 2) - buffer

class TestSquare extends GameObject:
	func _init():
		pts = [[
			Vector2(-20, -20),
			Vector2(20, -20),
			Vector2(20, 20),
			Vector2(-20, 20)
			]]
		
		pos = Vector2(100, 0)

class Level:
	enum {PLAYFIELD, SHIP, SQUARE}
	
	var obj = [
		PlayField.new(),
		Ship.new(),
		TestSquare.new()
		]
	
	func _init():
		set_meta("Level", 0)
	
	func process(delta : float)->void:
		obj[SHIP].process(delta)
		
		obj[PLAYFIELD].warp_object(obj[SHIP])

var draw_offset := Vector2(OS.window_size.x / 2, OS.window_size.y / 2)
var draw_scale := 1.0
var line_width := 1.0
var antialiasing := true
var draw_fill := false

var level := Level.new()

func _ready():
	get_tree().get_root().connect("size_changed", self, "window_resize")

func _process(delta : float)->void:
	level.process(delta)
	
	for point in level.obj[level.SHIP].pts[0]:
		if check_point_in_polygon(
			point.rotated(level.obj[level.SHIP].rot) + level.obj[level.SHIP].pos, 
			level.obj[level.SQUARE].pts[0], 
			level.obj[level.SQUARE].pos, 
			level.obj[level.SQUARE].rot
			):
				level.obj[level.SHIP].line = Color(1,0,0)
				break
		else:
			level.obj[level.SHIP].line = Color(1,1,1)
	
	update()

func _draw():
	for obj in level.obj:
		draw_object(obj)

func draw_object(obj : GameObject)->void:
	for shape in obj.pts:
		var draw_shape = []
		
		for point in shape:
			draw_shape.append(
				(point.rotated(obj.rot) + obj.pos) * draw_scale + draw_offset
			)
		
		if draw_fill:
			draw_polygon(draw_shape, [obj.fill])
		
		for i in range(draw_shape.size()):
			if i == draw_shape.size() - 1:
				if obj.polygon:
					draw_line(
						draw_shape[i],
						draw_shape[0], 
						obj.line, 
						line_width, 
						antialiasing
						)
			else:
				draw_line(
					draw_shape[i],
					draw_shape[i + 1], 
					obj.line, 
					line_width, 
					antialiasing
					)

# Tests to see if a point is inside of a polygon
# NOTE: Point should be passed with rotation and offset already applied
# if applicable
# https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon
func check_point_in_polygon(
	point : Vector2,
	polygon : PoolVector2Array,
	poly_pos : Vector2,
	poly_rot : float
	)->bool:
		var XMin : float; var XMax : float; var YMin : float; var YMax : float
		
		var intersections := 0
		var ray : Vector2
		
		# Find a simple AABB limit for the polygon to do a quick broad test
		for i in range(polygon.size()):
			var cur_x = polygon[i].rotated(poly_rot).x + poly_pos.x
			var cur_y = polygon[i].rotated(poly_rot).y + poly_pos.y
			
			if i == 0:
				XMin = cur_x
				XMax = cur_x
				YMin = cur_y
				YMax = cur_y
			else:
				if cur_x < XMin:
					XMin = cur_x
				elif cur_x > XMax:
					XMax = cur_x
				
				if cur_y < YMin:
					YMin = cur_y
				elif cur_y > YMax:
					YMax = cur_y
		
		# If the point is not inside the AABB then there is no way a
		# collision occurred
		if point.x < XMin || point.x > XMax || point.y < YMin || point.y > YMax:
			return false
		
		# Make a beginning point for a raycast outside the AABB found above,
		# with a buffer of 1 pixel (for 2D stuff this is more than enough).
		ray = Vector2(XMin - 1.0, point.y)
		
		# We check and see how many sides of the polygon intersect with the
		# raycast
		for i in range(polygon.size()):
			var lineB_start : Vector2
			var lineB_end : Vector2
			
			if i == polygon.size() - 1:
				lineB_start = polygon[i].rotated(poly_rot) + poly_pos
				lineB_end = polygon[0].rotated(poly_rot) + poly_pos
			else:
				lineB_start = polygon[i].rotated(poly_rot) + poly_pos
				lineB_end = polygon[i + 1].rotated(poly_rot) + poly_pos
			
			if check_line_intersection(ray, point, lineB_start, lineB_end):
				intersections += 1
		
		# If the number of intersections is odd, then the point is inside the
		# polygon. Otherwise it is not. This should work for convex, concave,
		# and polygons with holes in them.
		if intersections % 2 != 0:
			return true
		else:
			return false

# Checks if line A intersects with line B
# https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon
func check_line_intersection(
	line_a_start : Vector2,
	line_a_end : Vector2,
	line_b_start : Vector2,
	line_b_end : Vector2
	)->bool:
	# Converts line A into an infinitely long line. We can then use the
	# linear equation standard form to check for intersections with line B:
	# A * x + B * y + C = 0
	# http://en.wikipedia.org/wiki/Linear_equation
	var a1 = line_a_end.y - line_a_start.y
	var b1 = line_a_start.x - line_a_end.x
	var c1 = (line_a_end.x * line_a_start.y) - (line_a_start.x * line_a_end.y)
	
	
	var d1 = (a1 * line_b_start.x) + (b1 * line_b_start.y) + c1
	var d2 = (a1 * line_b_end.x) + (b1 * line_b_end.y) + c1
	
	if d1 > 0 && d2 > 0: return false
	if d1 < 0 && d2 < 0: return false
	
	# Now we reverse the process and make line B into an infinitely long line to
	# confirm that line A still intersects even when it is not infinitely long
	# itself. Once we can confirm this that means there is a very likely chance
	# that the two lines are properly intersecting.
	var a2 = line_b_end.y - line_b_start.y
	var b2 = line_b_start.x - line_b_end.x
	var c2 = (line_b_end.x * line_b_start.y) - (line_b_start.x * line_b_end.y)
	
	d1 = (a2 * line_a_start.x) + (b2 * line_a_start.y) + c2
	d2 = (a2 * line_a_end.x) + (b2 * line_a_end.y) + c2
	
	if d1 > 0 && d2 > 0: return false
	if d1 < 0 && d2 < 0: return false
	
	# NOTE: In this case, the two lines are actually "collinear" which
	# means they intersect at multiple points along the same line, potentially
	# even being the SAME line. Depending on the use case this could
	# either be a third return condition or even return true, but for
	# the sake of keeping the collision for this game simple I am just not
	# going to count it.
	if (a1 * b2) - (a2 * b1) == 0.0: return false
	
	# Otherwise, the two lines properly intersect
	return true

func window_resize()->void:
	draw_offset = Vector2(OS.window_size.x / 2, OS.window_size.y / 2)
	
	if OS.window_size.x > OS.window_size.y:
		draw_scale = OS.window_size.y / 720
	else:
		draw_scale = OS.window_size.x / 720