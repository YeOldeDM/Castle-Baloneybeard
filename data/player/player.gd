extends KinematicBody2D

# Movement
var tween = null # Moves the player from current to next tile smoothly
var is_moving = false # Prevents moving outside of tile positions

# Nodes
onready var ui_node = get_parent().get_node("ui")
onready var anim_node = get_node("animation_player")

# Ready
func _ready():
	update_total_baloneys()
	pass


# Using fixed process so player can hold down buttons for movement
func _fixed_process(delta):
	if(!is_moving && !is_sliding):
		if(Input.is_action_pressed("ui_left")):
			move(global.DIRECTION.LEFT)
		elif(Input.is_action_pressed("ui_right")):
			move(global.DIRECTION.RIGHT)
		elif(Input.is_action_pressed("ui_up")):
			move(global.DIRECTION.UP)
		elif(Input.is_action_pressed("ui_down")):
			move(global.DIRECTION.DOWN)

var facing = global.DIRECTION.RIGHT

# Move player with tween
func move(direction):
	# Do pre_move calculations
	if(pre_move(direction)):
		# Toggle to prevent unfinished movement before new movement
		is_moving = true
		
		# Play sound
		if(in_water):
			global.play_sound(global.SOUND.PLAYER_SWIM)
		else:
			global.play_sound(global.SOUND.PLAYER_MOVE)
		
		# Store facing direction
		facing = direction
		
		# Get current position
		var pos = get_pos()
		
		# Add directional change to position
		if(direction == global.DIRECTION.LEFT):
			if(in_water):
				anim_node.play("walk_left_in_water")
			else:
				anim_node.play("walk_left")
			pos.x -= global.config["tile_size"]
		
		elif(direction == global.DIRECTION.RIGHT):
			if(in_water):
				anim_node.play("walk_right_in_water")
			else:
				anim_node.play("walk_right")
			pos.x += global.config["tile_size"]
		
		elif(direction == global.DIRECTION.UP):
			if(in_water):
				anim_node.play("walk_up_in_water")
			else:
				anim_node.play("walk_up")
			pos.y -= global.config["tile_size"]
		
		elif(direction == global.DIRECTION.DOWN):
			if(in_water):
				anim_node.play("walk_right_in_water")
			else:
				anim_node.play("walk_right")
			pos.y += global.config["tile_size"]
		
		# Tween from original position to new position
		if(tween == null): # Create once
			tween = Tween.new()
			get_parent().add_child(tween)
			tween.connect("tween_complete", self, "_move_complete")
		tween.interpolate_property(self, "transform/pos", get_pos(), pos, global.player_speed, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		tween.start()


# Activated by Tween after movement is complete
func _move_complete(tween, key):
	# If we are sliding, and we are done moving, keep sliding
	if(is_sliding):
		is_moving = false
		slide()
		return
	
	if(on_ice):
		if(global.inventory.ITEMS.ANTI_ICE == 0):
			slide_ice()
			return
	
	last_move = false
	is_moving = false
	
	# Stop animation
	anim_node.stop_all()

	if(facing == global.DIRECTION.UP):
		if(in_water):
			anim_node.play("idle_up_in_water")
		else:
			anim_node.play("idle_up")
	if(facing == global.DIRECTION.DOWN):
		if(in_water):
			anim_node.play("idle_right_in_water")
		else:
			anim_node.play("idle_right") # TODO: Replace with idle down
	if(facing == global.DIRECTION.LEFT):
		if(in_water):
			anim_node.play("idle_left_in_water")
		else:
			anim_node.play("idle_left")
	if(facing == global.DIRECTION.RIGHT):
		if(in_water):
			anim_node.play("idle_right_in_water")
		else:
			anim_node.play("idle_right")



# Returns true if player can move in the requested direction
func pre_move(direction):
	if(!is_moving):
	
		var tile_pos = null
		var tilemap_world = get_parent().get_node("world")
		var tilemap_entity = get_parent().get_node("entities")
		
		if(tilemap_world != null):
			# Get tile coordinate of where you currently are
			tile_pos = tilemap_world.world_to_map(get_pos())
		
		# Check if we have a solid block in the next block
		if(direction == global.DIRECTION.LEFT):
			tile_pos.x -= 1
		elif(direction == global.DIRECTION.RIGHT):
			tile_pos.x += 1
		elif(direction == global.DIRECTION.UP):
			tile_pos.y -= 1
		elif(direction == global.DIRECTION.DOWN):
			tile_pos.y += 1
		
		# Check if tile is solid
		for t in global.SOLID_TILES["WORLD"]:
			if(t == tilemap_world.get_cellv(tile_pos)):
				return false
		
		for t in global.SOLID_TILES["ENTITIES"]:
			if(t == tilemap_entity.get_cellv(tile_pos)):
				# If it is a door, and we got the key, destroy door
				if(t == global.ENTITIES.DOOR.SPADE):
					if(global.inventory["KEYS"]["SPADE"] > 0):
						global.inventory["KEYS"]["SPADE"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
						global.play_sound(global.SOUND.PLAYER_OPEN_DOOR)
					else:
						return false
				elif(t == global.ENTITIES.DOOR.DIAMOND):
					if(global.inventory["KEYS"]["DIAMOND"] > 0):
						global.inventory["KEYS"]["DIAMOND"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
						global.play_sound(global.SOUND.PLAYER_OPEN_DOOR)
					else:
						return false
				elif(t == global.ENTITIES.DOOR.CLUB):
					if(global.inventory["KEYS"]["CLUB"] > 0):
						global.inventory["KEYS"]["CLUB"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
						global.play_sound(global.SOUND.PLAYER_OPEN_DOOR)
					else:
						return false
				elif(t == global.ENTITIES.DOOR.HEART):
					if(global.inventory["KEYS"]["HEART"] > 0):
						global.inventory["KEYS"]["HEART"] -= 1 # reduce by one
						tilemap_entity.set_cellv(tile_pos, -1)
						ui_node.update_keys()
						global.play_sound(global.SOUND.PLAYER_OPEN_DOOR)
					else:
						return false
				
				# We have a pushable block
				elif(t == global.ENTITIES.BLOCK.PUSHABLE_BLOCK):
					# Check if we have a solid block in the next block
					var move_to_pos = tile_pos
					if(direction == global.DIRECTION.LEFT):
						move_to_pos.x -= 1
					elif(direction == global.DIRECTION.RIGHT):
						move_to_pos.x += 1
					elif(direction == global.DIRECTION.UP):
						move_to_pos.y -= 1
					elif(direction == global.DIRECTION.DOWN):
						move_to_pos.y += 1
					
					# Making sure there is nothing else in the position where we want to move the block
					if(tilemap_entity.get_cellv(move_to_pos) == -1):
						# If there is something solid, we dont move
						var solid_tiles_with_misc = global.SOLID_TILES["WORLD"]
						for c in solid_tiles_with_misc:
							if(tilemap_world.get_cellv(move_to_pos) == c):
								return false # Something is in the way, we cannot move
						
						# Check for water
						if(tilemap_world.get_cellv(move_to_pos) == global.WORLD.WATER):
							# Remove pushing block
							tilemap_entity.set_cellv(tile_pos, -1)
			
							# Remove water instance
							for c in get_parent().get_node("world").get_children():
								# Remove water scene with same pos as the new tile pos
								if(c.get_pos() == tilemap_world.map_to_world(move_to_pos)):
									c.queue_free()
							
							# Add submerged block
							tilemap_world.set_cellv(move_to_pos, global.WORLD.SUBMERGED_BLOCK)
							
							# Play push sound in water
							global.play_sound(global.SOUND.PLAYER_PUSH_BLOCK_IN_WATER)
						else:
							# All clear! Moving block
							tilemap_entity.set_cellv(tile_pos, -1)
							tilemap_entity.set_cellv(move_to_pos, 10)
							
							# Play push sound
							global.play_sound(global.SOUND.PLAYER_PUSH_BLOCK)
					else:
						# TODO: Play sound to indicate failure to push
						# ..
						return false
				else:
					return false
		
		# Check if there are any items we can pickup
		var tile_id = tilemap_entity.get_cellv(tile_pos)
		
		# Diamond
		if(tile_id == global.ENTITIES.KEY.DIAMOND):
			global.inventory["KEYS"]["DIAMOND"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
			global.play_sound(global.SOUND.PLAYER_PICKUP_ITEM)
			
		# Spade
		elif(tile_id == global.ENTITIES.KEY.SPADE):
			global.inventory["KEYS"]["SPADE"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
			global.play_sound(global.SOUND.PLAYER_PICKUP_ITEM)
		
		# Club
		elif(tile_id == global.ENTITIES.KEY.CLUB):
			global.inventory["KEYS"]["CLUB"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
			global.play_sound(global.SOUND.PLAYER_PICKUP_ITEM)
		
		# Heart
		elif(tile_id == global.ENTITIES.KEY.HEART):
			global.inventory["KEYS"]["HEART"] += 1
			tilemap_entity.set_cellv(tile_pos, -1)
			ui_node.update_keys()
			global.play_sound(global.SOUND.PLAYER_PICKUP_ITEM)
		
		# Baloney
		elif(tile_id == global.ENTITIES.BALONEY):
			# Add to inventory
			global.inventory.BALONEY.CURRENT += 1
			
			# Update baloney in UI
			ui_node.update_baloney()
			
			# Add baloney on the sandwich!
			get_parent().get_parent().add_baloney()
			
			# Remove baloney
			tilemap_entity.set_cellv(tile_pos, -1)
			
			# Play pickup baloney
			global.play_sound(global.SOUND.PLAYER_PICKUP_BALONEY)
		
		# Anti Water Item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_WATER):
			# Add to inventory
			global.inventory.ITEMS.ANTI_WATER += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
			
			# Sound
			global.play_sound(global.SOUND.PLAYER_PICKUP_SPECIAL)
		
		# Anti Fire Item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_FIRE):
			# Add to inventory
			global.inventory.ITEMS.ANTI_FIRE += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
			
			# Sound
			global.play_sound(global.SOUND.PLAYER_PICKUP_SPECIAL)
		
		# Anti Ice Item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_ICE):
			# Add to inventory
			global.inventory.ITEMS.ANTI_ICE += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
			
			# Sound
			global.play_sound(global.SOUND.PLAYER_PICKUP_SPECIAL)
		
		# Anti Slide item
		elif(tile_id == global.ENTITIES.ITEM.ANTI_SLIDE):
			# Add to inventory
			global.inventory.ITEMS.ANTI_SLIDE += 1
			
			# Update UI
			ui_node.update_items()
			
			# Remove item
			tilemap_entity.set_cellv(tile_pos, -1)
			
			# Sound
			global.play_sound(global.SOUND.PLAYER_PICKUP_SPECIAL)
		return true

# Triggered by walking on a sandwich
func walked_on_goal():
	# If we have all baloneys
	if(global.inventory.BALONEY.CURRENT == global.inventory.BALONEY.TOTAL):
		# Inform level manager of victory
		get_parent().get_parent().victory()

# Triggered by walking on water
var in_water = false
func in_water():
	# Player is in water! Check if he has the item needed
	if(global.inventory.ITEMS.ANTI_WATER > 0):
		in_water = true
		pass
	else:
		# Death awaits us!
		get_parent().get_parent().death()
		pass

func out_of_water():
	in_water = false

func death():
	get_parent().get_parent().death()

# Player steps on fire
func in_fire(fire_node):
	# Player is in the fire! Check if he has the item needed to put it out
	if(global.inventory.ITEMS.ANTI_FIRE > 0):
		# TODO: Play some smoke animations (poof! Gone!)
		
		# Remove fire
		fire_node.queue_free()
	else:
		# Death awaits us!
		get_parent().get_parent().death()


# Counts and sets the total number of baloneys there is on the map
func update_total_baloneys():
	var tilemap_entities = get_parent().get_node("entities")
	var used_cells = tilemap_entities.get_used_cells()
	
	# For each baloney we find, increment total until we have counted them all
	for c in used_cells:
		if(tilemap_entities.get_cellv(c) == 9):
			global.inventory["BALONEY"]["TOTAL"] += 1
	
	ui_node.update_baloney()


# Slides to next tile
var is_sliding = false
var slide_to_pos = null
var slide_last = false

func slide_to_next(to_pos, has_next = true):
	# Keeps the player facing the same direction he had when he entered
	update_player_facing()
	
	if(global.inventory.ITEMS.ANTI_SLIDE > 0):
		pass
	else:
		# Store pos we are going to slide to
		slide_to_pos = to_pos
		
		# If we have another slide after this, it is NOT our last slide
		if(has_next):
			slide_last = false
		else:
			slide_last = true
		
		# Slide mode on
		is_sliding = true
		slide_count = 0
		

# TODO: Clean this mess up! Last minute code implementation. 
# This works. I dont know how or why, but it works. For now.
var slide_tween = null
var slide_count = 0
func slide():
	if(slide_count == 0):
		# Slide to new pos
		if(slide_tween == null):
			slide_tween = Tween.new()
			slide_tween.set_name("Slide tween")
			get_parent().add_child(slide_tween)
			slide_tween.connect("tween_complete", self, "_slide_complete")
		
		slide_tween.interpolate_property(self, "transform/pos", get_pos(), slide_to_pos, global.player_speed / 1.0, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		slide_tween.start()
		slide_count += 1
	else:
		is_sliding = false

func _slide_complete(var1, var2):
	slide()

# -- ICE --

var on_ice = false
var slide_ice_last = false
var slide_ice_to_pos = null

# 1:
func slide_on_ice():
	# On ice
	on_ice = true


var slide_ice_tween = null
var last_move = false
# after initial move is complete - 2:
func slide_ice():
	# Keeps the player facing the same direction he had when he entered
	update_player_facing()
	
	# Try to move
	var continue_sliding = try_to_move()
	
	if(continue_sliding):
		# Slide to new pos
		if(slide_ice_tween == null):
			slide_ice_tween = Tween.new()
			slide_ice_tween.set_name("Slide ice tween")
			get_parent().add_child(slide_ice_tween)
			slide_ice_tween.connect("tween_complete", self, "_slide_ice_complete")
		
		print("Current pos: " + str(get_pos()) + ", Next pos: " + str(slide_ice_to_pos))
		slide_ice_tween.interpolate_property(self, "transform/pos", get_pos(), slide_ice_to_pos, global.player_speed / 1.0, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		slide_ice_tween.start()

func _slide_ice_complete(var1, var2):
	if(!last_move):
		slide_ice()
	else:
		is_moving = false
		on_ice = false
	pass
	

func try_to_move():
	# Check if there is an ice tile there
	var tilemap_world = get_parent().get_node("world")
	var tile_pos = tilemap_world.world_to_map(get_pos())
	
	# Check if we have a solid block in the next block
	if(facing == global.DIRECTION.LEFT):
		# Solid ahead
		if(has_solid(tilemap_world, tile_pos + Vector2(-1, 0))):
			# Stop moving
			is_moving = false
			on_ice = false
			return false
		else:
			if(!has_ice(tilemap_world, tile_pos + Vector2(-1, 0))):
				last_move = true
			else:
				last_move = false
			tile_pos.x -= 1
	elif(facing == global.DIRECTION.RIGHT):
		# Solid ahead
		if(has_solid(tilemap_world, tile_pos + Vector2(1, 0))):
			# Stop moving
			is_moving = false
			on_ice = false
			return false
		else:
			if(!has_ice(tilemap_world, tile_pos + Vector2(1, 0))):
				last_move = true
			else:
				last_move = false
			tile_pos.x += 1
	
	elif(facing == global.DIRECTION.UP):
		# Solid ahead
		if(has_solid(tilemap_world, tile_pos + Vector2(0, -1))):
			# Stop moving
			is_moving = false
			on_ice = false
			return false
		else:
			if(!has_ice(tilemap_world, tile_pos + Vector2(0, -1))):
				last_move = true
			else:
				last_move = false
			tile_pos.y -= 1
			pass
	
	elif(facing == global.DIRECTION.DOWN):
		# Solid ahead
		if(has_solid(tilemap_world, tile_pos + Vector2(0, 1))):
			# Stop moving
			is_moving = false
			on_ice = false
			return false
		else:
			if(!has_ice(tilemap_world, tile_pos + Vector2(0, 1))):
				last_move = true
			else:
				last_move = false
			tile_pos.y += 1

	# Set the position we are moving to
	slide_ice_to_pos = tilemap_world.map_to_world(tile_pos)
	return true


func has_solid(tilemap, cell_pos):
	# Check if tile is solid
	for t in global.SOLID_TILES["WORLD"]:
		if(t == tilemap.get_cellv(cell_pos)):
			return true
	return false

func has_ice(tilemap, cell_pos):
	# Check if tile is solid
	if(global.WORLD.ICE == tilemap.get_cellv(cell_pos)):
		return true
	return false

func update_player_facing():
	# Keeps the player facing the same direction he had when he entered
	if(facing == global.DIRECTION.LEFT):
		anim_node.play("idle_left")
	elif(facing == global.DIRECTION.RIGHT):
		anim_node.play("idle_right")
	elif(facing == global.DIRECTION.UP):
		anim_node.play("idle_up")
	elif(facing == global.DIRECTION.DOWN):
		anim_node.play("idle_right")
