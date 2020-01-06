extends Node2D


# CUSTOM CLASSES ###############################################################
# Generic object that can be drawn in Meteoroids
class GameObject:
	# "GameManager" which allows us to use the functions outside of the class
	var gm : Node2D
	
	var position := Vector2.ZERO # Position
	var rotation := 0.0 # Rotation
	
	# warning-ignore:unused_class_variable
	var line := Color(1,1,1) # Color of outline for drawing
	# warning-ignore:unused_class_variable
	var fill := Color(0,0,1) # Color of internal shape for drawing
	
	# An array of shapes (which in turn are arrays of Vector2s) that are
	# used for draw_object()
	var pts := []
	
	var polygon := false # Flag for connecting last point to first point
	
	
	func _init(_gm : Node2D) -> void:
		gm = _gm
	
	func _draw() -> void:
		gm.draw_object(self)
	
	# For readability, gets the first shape in the points array. Most game
	# objects (like the Ship, Bullets, Meteors, etc) will only have this one
	# shape in the array, but I want the point array to be two dimensional
	# (i.e. be an array of shapes) so that drawing text and some other objects
	# which only appear as a collection of lines would be possible.
	func get_shape() -> PoolVector2Array:
		return pts[0]

# Class for the player's ship
class Ship extends GameObject:
	var velocity := Vector2.ZERO # Velocity
	var max_velocity := 25.0 # Limit for velocity
	
	var rotation_speed := PI # How fast the ship can turn
	var speed := 5 # How fast the ship can boost
	
	# Flag set when the player shoots, at which point the Level class will
	# check and spawn bullets into it's object array if needed. The Level
	# class will automatically disable this flag once a bullet is spawned.
	var spawn_bullet := false
	
	
	func _init(_gm : Node2D).(_gm) -> void:
		# TODO: Change points so rotation is centered (fixed?)
		pts = [gm.ship_shape]
		
		polygon = true
	
	func process(delta : float) -> void:
		# Input management
		if Input.is_action_pressed("turn_left"):
			rotation -= rotation_speed * delta
			
			if rotation <= -2 * PI:
				rotation += 2 * PI
		
		if Input.is_action_pressed("turn_right"):
			rotation += rotation_speed * delta
		
			if rotation >= 2 * PI:
				rotation -= 2 * PI
		
		if Input.is_action_pressed("boost"):
			velocity += Vector2.RIGHT.rotated(rotation) * speed * delta
		
		if Input.is_action_just_pressed("shoot"):
			spawn_bullet = true
		
		# Velocity cap enforced
		if abs(velocity.x) > max_velocity:
				velocity.x = sign(velocity.x) * max_velocity
		
		if abs(velocity.y) > max_velocity:
			velocity.y = sign(velocity.y) * max_velocity
		
		# Move the player
		position += velocity

# Class for player and enemy bullets
class Bullet extends GameObject:
	var velocity := Vector2.RIGHT * 500 # Velocity (rotated on initialization)
	
	var duration := 1.0 # Maximum duration a bullet can be active
	var time_counter := 0.0 # Current time of livespan
	
	var delete := false # Flag to delete after duration expired
	
	var player := true # True if player shoots; otherwise false
	
	
	func _init(_gm : Node2D).(_gm) -> void:
		pts = [[
				Vector2(-.5, -.5),
				Vector2(.5, -.5),
				Vector2(.5, .5),
				Vector2(-.5, .5)
				]]
	
	func process(delta : float) -> void:
		# Increment lifespan
		time_counter += delta
		
		# If lifespan expired, flag for deletion; otherwise move bullet
		if time_counter >= duration:
			delete = true
		else:
			position += velocity * delta

# Class for the "screen" on which the gameplay occurs
class PlayField extends GameObject:
	var size := Vector2(700,600)
	
	
	func _init(_gm : Node2D).(_gm) -> void:
		pts = [[
				Vector2(-size.x / 2, -size.y / 2),
				Vector2(size.x / 2, -size.y /2),
				Vector2(size.x / 2, size.y / 2),
				Vector2(-size.x / 2, size.y / 2)
				]]
		
		polygon = true
	
	# Function that is used to check when an object needs to be warped to the 
	# opposite side of the screen to do proper screen wrapping
	func warp_object(obj : GameObject) -> void:
		if obj.position.x < -(size.x / 2):
			obj.position.x += size.x
		elif obj.position.x > (size.x / 2):
			obj.position.x -= size.x
		
		if obj.position.y < -(size.y / 2):
			obj.position.y += size.y
		elif obj.position.y > (size.y / 2):
			obj.position.y -= size.y

# TODO: Make Big, Medium, and Small variations somehow. The smaller a
# meteor is the faster it should travel and spin
class Meteor extends GameObject:
	var meteor_size : int # gm.METEOR_SIZE {LARGE, MEDIUM, SMALL}
	
	var meteor_index : int # gm.meteor_shapes[i]
	var meteor_scale : float # Relative scale for drawing
	
	var velocity := Vector2.ZERO # Velocity
	var rotation_speed := 0.0
	
	
	func _init(
			_gm : Node2D,
			_meteor_size : int,
			_meteor_index : int,
			_pos : Vector2, 
			_vel : Vector2,
			_rot_speed : float
			).(_gm) -> void:
		meteor_size = _meteor_size
		meteor_index = _meteor_index
		meteor_scale = 1.0
		
		if meteor_size == gm.METEOR_SIZE.MEDIUM:
			meteor_scale = 0.5
		elif meteor_size == gm.METEOR_SIZE.SMALL:
			meteor_scale = 0.25
		
		pts = [[]]
		
		for point in gm.meteor_shapes[meteor_index]:
			pts[0].append(point * meteor_scale)
		
		polygon = true
		
		meteor_scale = 1.0
		
		if meteor_size == gm.METEOR_SIZE.MEDIUM:
			meteor_scale = 2
		elif meteor_size == gm.METEOR_SIZE.SMALL:
			meteor_scale = 4
		
		position = _pos
		velocity = _vel * meteor_scale
		rotation_speed = _rot_speed * meteor_scale
	
	func process(delta : float) -> void:
		# Move the meteor
		position += velocity * delta
		
		# Rotate the meteor
		rotation += rotation_speed * delta
		
		if rotation > 2 * PI:
			rotation -= 2 * PI
		elif rotation < - 2 * PI:
			rotation += 2 * PI

# Object manager for a game level in Meteoroids.
class Level:
	# "GameManager" which allows us to use the functions outside of the class
	var gm : Node2D
	
	var playfield : PlayField
	var ship : Ship
	var meteors := []
	var bullets := []
	
	var meteor_count := 4
	
	func _init(_gm : Node2D) -> void:
		gm = _gm
		
		playfield = PlayField.new(gm)
		ship = Ship.new(gm)
		
		# warning-ignore:unused_variable
		for i in range(meteor_count):
			var rot_dir := 1
			
			if randi() % 2 == 0:
				rot_dir = -1
			
			var meteor = Meteor.new(
					gm,
					gm.METEOR_SIZE.LARGE,
					randi() % gm.meteor_shapes.size(),
					Vector2(
							randf() * playfield.size.x / 2.0, 
							randf() * playfield.size.y / 2.0
							),
					Vector2(50.0, 0).rotated(randf() * 2 * PI),
					PI / 4 * rot_dir
					)
			
			meteors.append(meteor)
	
	func process(delta : float) -> void:
		# Process all ship controls and movement
		ship.process(delta)
		
		# Check to see if player attempted to shoot; if so spawn a bullet
		if ship.spawn_bullet:
			ship.spawn_bullet = false
			
			var bullet := Bullet.new(gm)
			
			bullet.position = \
					ship.get_shape()[0].rotated(ship.rotation) + \
					ship.position
			bullet.velocity = bullet.velocity.rotated(ship.rotation)
			#bullet.player = false
			
			bullets.append(bullet)
		
		# Process all bullets in the level. Go through steps to see which need
		# to be deleted based on their lifespan running out or from hitting a
		# valid object
		if !bullets.empty():
			var bullet_delete_list = []
			
			for i in range(bullets.size()):
				bullets[i].process(delta)
				
				# This is the flag used when their lifespan runs out
				if bullets[i].delete:
					bullet_delete_list.append(i)
					break # No further checks are needed
				
				# Check all meteors in the level to see if a player's bullet
				# has hit any of them. If so, that meteor must be destroyed
				# (and if applicable, replaced with two smaller meteors) as
				# well as the bullet that collided with it.
				if !meteors.empty() && bullets[i].player:
					var meteor_delete_list = []
					
					for j in range(meteors.size()):
						if gm.check_point_in_polygon(
								bullets[i].position, 
								meteors[j].get_shape(), 
								meteors[j].position, 
								meteors[j].rotation
								):
								
								bullet_delete_list.append(i)
								meteor_delete_list.append(j)
					
					# Process removing meteors from object list
					for idx in meteor_delete_list:
						# TODO: Add spawning smaller meteors
						meteors.remove(idx)
				
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
			
			# Process removing bullets from object list
			for idx in bullet_delete_list:
				bullets.remove(idx)
		
		# Process meteor movement in the level
		if !meteors.empty():
			for meteor in meteors:
				meteor.process(delta)
		
		# Check to see if object has crossed the buffer zone of the playfield. 
		# If so, it needs to be warped to the opposite side buffer to create the
		# illusion of screen wrapping.
		playfield.warp_object(ship)
		
		if !bullets.empty():
			for bullet in bullets:
				playfield.warp_object(bullet)
		
		if !meteors.empty():
			for meteor in meteors:
				playfield.warp_object(meteor)
		
		# TODO: Do proper shape calculations here
		
		# TODO: Move collision checks down here
		
		# TODO: Then win state check
	
	func draw():
		ship._draw()
		
		if !bullets.empty():
			for bullet in bullets:
				bullet._draw()
		
		if !meteors.empty():
			for meteor in meteors:
				meteor._draw()
		
		playfield._draw()


# GAME DATA CONTAINERS #########################################################
enum METEOR_SIZE {LARGE, MEDIUM, SMALL}
# warning-ignore:unused_class_variable
var ship_shape := [
		Vector2(12, 0),
		Vector2(-8, 8),
		Vector2(-6, 4),
		Vector2(-6, -4),
		Vector2(-8, -8)
		]
# warning-ignore:unused_class_variable
var meteor_shapes := [
		[
				Vector2(-40, -40),
				Vector2(40, -40),
				Vector2(40, 40),
				Vector2(-40, 40)
				],
		[
				Vector2(-30, -30),
				Vector2(30, -30),
				Vector2(30, 30),
				Vector2(-30, 30)
				]
		]


# GLOBAL GAME VARIABLES ########################################################
var level := Level.new(self)

var draw_offset := Vector2(OS.window_size.x / 2, OS.window_size.y / 2)
var draw_scale := 1.0
var line_width := 1.0
var antialiasing := true
var draw_fill := false


# CORE OVERRIDE FUNCTIONS ######################################################
func _ready() -> void:
	# warning-ignore:return_value_discarded
	get_tree().get_root().connect("size_changed", self, "window_resize")

func _process(delta : float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	level.process(delta)
	
	update()

func _draw() -> void:
	level.draw()


# CUSTOM GAME LOGIC FUNCTIONS (DRAW, COLLISION, ETC) ###########################
func draw_object(obj : GameObject) -> void:
	for shape in obj.pts:
		var draw_shape = []
		
		for point in shape:
			draw_shape.append(
					(point.rotated(obj.rotation) + obj.position) * draw_scale \
							+ draw_offset
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
		) -> bool:
	var XMin : float
	var XMax : float
	var YMin : float
	var YMax : float
	
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
		) -> bool:
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

func window_resize() -> void:
	# Always set to the absolute center of the current window size
	draw_offset = Vector2(OS.window_size.x / 2, OS.window_size.y / 2)
	
	# Keeps the game in a square aspect ratio
	if OS.window_size.x > OS.window_size.y:
		draw_scale = OS.window_size.y / 720
	else:
		draw_scale = OS.window_size.x / 720

