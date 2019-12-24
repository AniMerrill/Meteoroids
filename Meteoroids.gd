extends Node2D

# Generic object that can be drawn in Meteoroids
class GameObject:
	# "GameManager" which allows us to use the functions outside of the class
	var gm : Node2D
	
	var pos := Vector2.ZERO # Position
	var rot := 0.0 # Rotation
	
	var line := Color(1,1,1)
	var fill := Color(0,0,1)
	
	# An array of shapes (which in turn are arrays of Vector2s) that are
	# used for draw_object()
	var pts := []
	
	var polygon := false # Flag for connecting last point to first point
	
	func _init(_gm : Node2D)->void:
		gm = _gm
	
	func draw()->void:
		gm.draw_object(self)
	
	func get_shape()->PoolVector2Array:
		return pts[0]

class Ship extends GameObject:
	var vel := Vector2.ZERO
	var max_vel := Vector2(25,25)
	
	var rot_speed := PI
	var speed := 5
	
	var spawn_bullet := false
	
	func _init(_gm : Node2D).(_gm)->void:
		# TODO: Change points so rotation is centered
		pts = [[
			Vector2(12, 0),
			Vector2(-8, 8),
			Vector2(-6, 4),
			Vector2(-6, -4),
			Vector2(-8, -8)
			]]
		
		polygon = true
	
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
			vel += Vector2.RIGHT.rotated(rot) * speed * delta
		
		if Input.is_action_just_pressed("shoot"):
			spawn_bullet = true
		
		if abs(vel.x) > max_vel.x:
				vel.x = sign(vel.x) * max_vel.x
		
		if abs(vel.y) > max_vel.y:
			vel.y = sign(vel.y) * max_vel.y
		
		pos += vel

class Bullet extends GameObject:
	var vel := Vector2.RIGHT * 500
	
	var dur := 1.0
	var time := 0.0
	
	var delete := false
	
	var player := true
	
	#var target
	
	func _init(_gm : Node2D).(_gm)->void:
		pts = [[
			Vector2(-1, -1),
			Vector2(1, -1),
			Vector2(1, 1),
			Vector2(-1, 1)
			]]
		
		#target = _target
	
	func process(delta : float)->void:
		time += delta
		
		if time >= dur:
			delete = true
		else:
			pos += vel * delta

class PlayField extends GameObject:
	var size := 600.0
	var buffer := 40.0
	var buffer_color := Color(0,0,0)
	
	func _init(_gm : Node2D).(_gm)->void:
		pts = [[
			Vector2(-size / 2, -size / 2),
			Vector2(size / 2, -size /2),
			Vector2(size / 2, size / 2),
			Vector2(-size / 2, size / 2)
			]]
		
		polygon = true
	
	func draw()->void:
		var buffer_thickness := buffer * 4
		var buffer_width := size / 2
		
		# Top
		gm.draw_rect(
			Rect2(
				(-buffer_width - buffer_thickness) * gm.draw_scale + gm.draw_offset.x, 
				(-buffer_thickness - buffer_width) * gm.draw_scale + gm.draw_offset.y, 
				(size + buffer_thickness * 2) * gm.draw_scale, 
				buffer_thickness * gm.draw_scale
				),
			buffer_color,
			true
		)

		# Bottom
		gm.draw_rect(
			Rect2(
				(-buffer_width - buffer_thickness) * gm.draw_scale + gm.draw_offset.x, 
				(buffer_width) * gm.draw_scale + gm.draw_offset.y, 
				(size + buffer_thickness * 2) * gm.draw_scale, 
				buffer_thickness * gm.draw_scale
				),
			buffer_color,
			true
		)
		
		# Left
		gm.draw_rect(
			Rect2(
				(-buffer_width - buffer_thickness) * gm.draw_scale + gm.draw_offset.x, 
				(-buffer_width) * gm.draw_scale + gm.draw_offset.y, 
				buffer_thickness * gm.draw_scale, 
				(size) * gm.draw_scale
				),
			buffer_color,
			true
		)
		
		# Right
		gm.draw_rect(
			Rect2(
				(buffer_width) * gm.draw_scale + gm.draw_offset.x, 
				(-buffer_width) * gm.draw_scale + gm.draw_offset.y, 
				buffer_thickness * gm.draw_scale, 
				(size) * gm.draw_scale
				),
			buffer_color,
			true
		)
		
		.draw()
	
	func warp_object(obj : GameObject)->void:
		if obj.pos.x < -(size / 2) - buffer:
			obj.pos.x = (size / 2) + buffer
		elif obj.pos.x > (size / 2) + buffer:
			obj.pos.x = -(size / 2) - buffer
		
		if obj.pos.y < -(size / 2) - buffer:
			obj.pos.y = (size / 2) + buffer
		elif obj.pos.y > (size / 2) + buffer:
			obj.pos.y = -(size / 2) - buffer

class Meteor extends GameObject:
	var vel := Vector2.ZERO
	
	func _init(_gm : Node2D, _pos : Vector2, _vel : Vector2).(_gm):
		pts = [[
			Vector2(-40, -40),
			Vector2(40, -40),
			Vector2(40, 40),
			Vector2(-40, 40)
			]]
		
		polygon = true
		
		pos = _pos
		vel = _vel
	
	func process(delta : float)->void:
		pos += vel * delta

class Level:
	var gm : Node2D
	var obj := {}
	
	func _init(_gm : Node2D):
		obj = {
			"playfield" : PlayField.new(_gm),
			"ship" : Ship.new(_gm),
			"meteors" : [
				Meteor.new(_gm, Vector2(-100,-100), Vector2.RIGHT * 50),
				Meteor.new(_gm, Vector2(100,-100), Vector2.RIGHT * 50),
				Meteor.new(_gm, Vector2(100,100), Vector2.RIGHT * 50),
				Meteor.new(_gm, Vector2(-100,100), Vector2.RIGHT * 50),
				],
			"bullets" : []
			}
		
		gm = _gm
	
	func process(delta : float)->void:
		obj.ship.process(delta)
		
		if obj.ship.spawn_bullet:
			obj.ship.spawn_bullet = false
			
			var bullet := Bullet.new(gm)
			
			bullet.pos = obj.ship.get_shape()[0].rotated(obj.ship.rot) + obj.ship.pos
			bullet.vel = bullet.vel.rotated(obj.ship.rot)
			#bullet.player = false
			
			obj.bullets.append(bullet)
		
		if !obj.bullets.empty():
			var bullet_delete_list = []
			
			for i in range(obj.bullets.size()):
				obj.bullets[i].process(delta)
				
				if obj.bullets[i].delete:
					bullet_delete_list.append(i)
					break
				
				if !obj.meteors.empty() && obj.bullets[i].player:
					var meteor_delete_list = []
					
					for j in range(obj.meteors.size()):
						if gm.check_point_in_polygon(
							obj.bullets[i].pos, 
							obj.meteors[j].get_shape(), 
							obj.meteors[j].pos, 
							obj.meteors[j].rot
							):
								bullet_delete_list.append(i)
								meteor_delete_list.append(j)
					
					for idx in meteor_delete_list:
						# TODO: Add spawning smaller meteors
						obj.meteors.remove(idx)
				
				# TODO
				# if !obj.bullets[i].player:
				# 	####do collision check w/ player####
	#				if obj.has("square"):
	#					if gm.check_point_in_polygon(
	#						obj.bullets[i].pos, 
	#						obj.square.get_shape(), 
	#						obj.square.pos, 
	#						obj.square.rot
	#						):
	#							obj.erase("square")
			
			for idx in bullet_delete_list:
				obj.bullets.remove(idx)
		
		if !obj.meteors.empty():
			for meteor in obj.meteors:
				meteor.process(delta)
		
		obj.playfield.warp_object(obj.ship)
		
		if !obj.bullets.empty():
			for bullet in obj.bullets:
				obj.playfield.warp_object(bullet)
		
		if !obj.meteors.empty():
			for meteor in obj.meteors:
				obj.playfield.warp_object(meteor)
	
	func draw():
		obj.ship.draw()
		
		if !obj.bullets.empty():
			for bullet in obj.bullets:
				bullet.draw()
		
		if !obj.meteors.empty():
			for meteor in obj.meteors:
				meteor.draw()
		
		obj.playfield.draw()

var draw_offset := Vector2(OS.window_size.x / 2, OS.window_size.y / 2)
var draw_scale := 1.0
var line_width := 1.0
var antialiasing := true
var draw_fill := false

var level := Level.new(self)

func _ready():
	get_tree().get_root().connect("size_changed", self, "window_resize")
	

func _process(delta : float)->void:
	level.process(delta)
	
	update()

func _draw():
	level.draw()

func draw_object(obj : GameObject)->void:
	for shape in obj.pts:
		var draw_shape = []
		
		for point in shape:
			draw_shape.append(
				(point.rotated(obj.rot) + obj.pos) * draw_scale + draw_offset
			)
		
		if draw_fill && obj.polygon:
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
			var line_b_start : Vector2
			var line_b_end : Vector2
			
			if i == polygon.size() - 1:
				line_b_start = polygon[i].rotated(poly_rot) + poly_pos
				line_b_end = polygon[0].rotated(poly_rot) + poly_pos
			else:
				line_b_start = polygon[i].rotated(poly_rot) + poly_pos
				line_b_end = polygon[i + 1].rotated(poly_rot) + poly_pos
			
			if check_line_intersection(ray, point, line_b_start, line_b_end):
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