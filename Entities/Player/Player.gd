extends KinematicBody2D

# Player movement speed
export var speed = 75

# Player dragging flag
var drag_enabled = false

var last_direction = Vector2(0, 1)
var attack_playing = false

# Player stats
var health = 100
var health_max = 100
var health_regeneration = 1
var mana = 100
var mana_max = 100
var mana_regeneration = 2

# Attack variables
var attack_cooldown_time = 1000
var next_attack_time = 0
var attack_damage = 30

var fireball_scene = preload("res://Entities/Fireball.tscn")

# Fireball variables
var fireball_damage = 50
var fireball_cooldown_time = 1000
var next_fireball_time = 0

# Player inventory
enum Potion { HEALTH, MANA }
var health_potions = 0
var mana_potions = 0

var xp = 0;
var xp_next_level = 100;
var level = 1;

signal player_stats_changed
signal player_level_up

func _ready():
	emit_signal("player_stats_changed", self)

func _process(delta):
	# Regenerates mana
	var new_mana = min(mana + mana_regeneration * delta, mana_max)

	if new_mana != mana:
		mana = new_mana
		emit_signal("player_stats_changed", self)

	# Regenerates health
	var new_health = min(health + health_regeneration * delta, health_max)

	if new_health != health:
		health = new_health
		emit_signal("player_stats_changed", self)

func _physics_process(delta):
	var direction: Vector2

	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if abs(direction.x) == 1 and abs(direction.y) == 1:
		direction = direction.normalized()

	var movement = speed * direction * delta

	# If dragging is enabled, use mouse position to calculate movement
	if drag_enabled:
		var new_position = get_global_mouse_position()

		movement = new_position - position;

		if movement.length() > (speed * delta):
			movement = speed * delta * movement.normalized()

	if attack_playing:
		movement = 0.3 * movement
	else:
		# Animate player based on direction
		animates_player(direction)

	# Turn RayCast2D toward movement direction
	if direction != Vector2.ZERO:
		$RayCast2D.cast_to = direction.normalized() * 8

	return move_and_collide(movement)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.pressed:
			drag_enabled = false
	if event.is_action_pressed("Attack"):
		# Check if player can attack
		var now = OS.get_ticks_msec()

		if now >= next_attack_time:
			# What's the target?
			var target = $RayCast2D.get_collider()

			if target != null:
				if target.name.find("Skeleton") >= 0:
					# Skeleton hit!
					target.hit(attack_damage)

				if target.is_in_group("NPCs"):
					# Talk to NPC
					target.talk()
					return

				if target.name == "Bed":
					# Sleep
					$AnimationPlayer.play("Sleep")
					yield(get_tree().create_timer(1), "timeout")
					health = health_max
					mana = mana_max
					emit_signal("player_stats_changed", self)
					return

			# Play attack animation
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_attack"
			$AnimatedSprite.play(animation)

			# Play attack sound
			$SoundAttack.play()

			# Add cooldown time to current time
			next_attack_time = now + attack_cooldown_time
	elif event.is_action_pressed("Fireball"):
		var now = OS.get_ticks_msec()

		if mana >= 25 and now >= next_fireball_time:
			# Update mana
			mana = mana - 25
			emit_signal("player_stats_changed", self)

			# Play fireball animation
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_fireball"
			$AnimatedSprite.play(animation)

			# Play fireball sound
			$SoundFireball.play()

			# Add cooldown time to current time
			next_fireball_time = now + fireball_cooldown_time
	elif event.is_action_pressed("drink_health"):
		if health_potions > 0:
			health_potions = health_potions - 1
			health = min(health + 50, health_max)
			emit_signal("player_stats_changed", self)

			# Play sound
			$SoundObject.play()
	elif event.is_action_pressed("drink_mana"):
		if mana_potions > 0:
			mana_potions = mana_potions - 1
			mana = min(mana + 50, mana_max)
			emit_signal("player_stats_changed", self)

			# Play sound
			$SoundObject.play()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			drag_enabled = event.pressed

func animates_player(direction: Vector2):
	if direction != Vector2.ZERO:
		# gradually update last_direction to counteract the bounce of the analog stick
		last_direction = 0.5 * last_direction + 0.5 * direction

		# Choose walk animation based on movement direction
		var animation = get_animation_direction(last_direction) + "_walk"

		$AnimatedSprite.frames.set_animation_speed(animation, 2 + 8 * direction.length())

		# Play the walk animation
		$AnimatedSprite.play(animation)
	else:
		# Choose idle animation based on last movement direction and play it
		var animation = get_animation_direction(last_direction) + "_idle"
		$AnimatedSprite.play(animation)

func get_animation_direction(direction: Vector2):
	var norm_direction = direction.normalized()

	if norm_direction.y >= 0.707:
		return "down"
	elif norm_direction.y <= -0.707:
		return "up"
	elif norm_direction.x <= -0.707:
		return "left"
	elif norm_direction.x >= 0.707:
		return "right"

	return "down"

func hit(damage):
	health -= damage
	emit_signal("player_stats_changed", self)

	if health > 0:
		$AnimationPlayer.play("Hit")
	else:
		set_process(false)
		$AnimationPlayer.play("Game Over")
		$Music.stop()
		$MusicGameOver.play()

func add_potion(type):
	if type == Potion.HEALTH:
		health_potions = health_potions + 1
	else:
		mana_potions = mana_potions + 1

	emit_signal("player_stats_changed", self)

	# Play sound
	$SoundObject.play()

func add_xp(value):
	xp += value

	# Has the player reached the next level?
	if xp >= xp_next_level:
		level += 1
		xp_next_level *= 2
		emit_signal("player_level_up")

	emit_signal("player_stats_changed", self)

func _on_AnimatedSprite_animation_finished():
	attack_playing = false

	if $AnimatedSprite.animation.ends_with("_fireball"):
		# Instantiate Fireball
		var fireball = fireball_scene.instance()
		fireball.attack_damage = fireball_damage
		fireball.direction = last_direction.normalized()
		fireball.position = position + last_direction.normalized() * 4
		get_tree().root.get_node("Root").add_child(fireball)
