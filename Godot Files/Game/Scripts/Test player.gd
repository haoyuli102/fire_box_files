extends KinematicBody2D


# export var moveLeft = KEY_LEFT
# export var moveRight = KEY_RIGHT
# export var kick = KEY_DOWN
# export var jump = KEY_UP

var controler = preload("res://Game/AnimatedPlayer/test/Controler.gd")

#export var moveLeft = KEY_LEFT
#export var moveRight = KEY_RIGHT
var moveLeft = KEY_LEFT
var moveRight = KEY_RIGHT
var other
var flipped = false

# Movement Values
var friction = 0.5
var motion = Vector2(0, 0)
var dashing = false
var dF = false
var dB = false

#export(int) var forwardSpeed = 50000
#export(int) var backwardSpeed = 30000
var forwardSpeed = 35000
var backwardSpeed = 25000
var dashingSpeed = 200000
var fMotion
var bMotion
export(int) var jumpMultiplier = 900
export(float) var airSpeedMultiplier = 0.8
export(int) var gravityMultiplier = 1000


# FireBall Values
var fireball
var fireball_scene = load("Game/FireBall.tscn")
var fireBallCheck
var infireball = false

var fireballStartup = 30
export(int) var fireballLag = 30

#Kick Values
export(int) var kickEndLag = 30

#timers
var timer = 0
var dashTimer = 0
var lagTimer = 0



# Returns true if play is on the left
func onLeft():
	
	if self.name == "P1":
		if get_parent().get_node("P2").get_position().x > self.get_position().x:
			return true
		else:
			return false
	else:
		if get_parent().get_node("P1").get_position().x > self.get_position().x:
			return true
		else:
			return false
	

func hasFliped():
	if get_position().x < get_parent().get_node(str(other)).get_position().x and is_on_floor():
		if !flipped:
			flipped = true
			return true
	elif get_position().x > get_parent().get_node(str(other)).get_position().x and is_on_floor():
		if flipped:
			flipped = false
			return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready():
	if self.name == "P1":
		other = "P2"
	else:
		other = "P1"
	fMotion = "move_left"
	bMotion = "move_right"
	controler = controler.new()
	moveLeft = controler._get_left(self.name)
	moveRight = controler._get_right(self.name)
	pass


func _physics_process(delta):
	
	timer += 1

	#Checking if the sprite just flipped
	if hasFliped():
		if flipped:
			get_node("PlayerSprite").offset = Vector2(110, 0)
			get_node("PlayerSprite").flip_h = true
			fMotion = "move_right"
			bMotion = "move_left"
			dashingSpeed = -dashingSpeed
			var tmp = forwardSpeed
			forwardSpeed = backwardSpeed
			backwardSpeed = tmp
		else:
			get_node("PlayerSprite").offset = Vector2(0, 0)
			get_node("PlayerSprite").flip_h = false
			fMotion = "move_left"
			bMotion = "move_right"
			dashingSpeed = -dashingSpeed
			var tmp = forwardSpeed
			forwardSpeed = backwardSpeed
			backwardSpeed = tmp

	if Input.is_action_pressed("%smove_left" % self.name) and lagTimer == 0:
		motion.x = -forwardSpeed
	if Input.is_action_pressed("%smove_right" % self.name) and lagTimer == 0:
		motion.x = backwardSpeed

	# There is some funny bugs with the way this works
	# This is some attrocious code and this should never made it into our finished
	# project ;)
	fireBallCheck = lagTimer == 0 and is_on_floor()
	fireBallCheck = fireBallCheck and Input.is_action_pressed("%s_Attack" % self.name)
	if fireBallCheck:
		if onLeft():
			fireBallCheck = fireBallCheck and Input.is_key_pressed(moveRight)
		else:
			fireBallCheck = fireBallCheck and Input.is_key_pressed(moveLeft)
	
	if fireBallCheck:
		lagTimer = fireballLag
		fireball = fireball_scene.instance()
		get_parent().add_child(fireball)
		fireball.init(self.position, onLeft(), self)
		
	# is_on_floor() is a function that just works ig

	#kick
	if Input.is_action_pressed("%s_Attack" % self.name) and is_on_floor() and lagTimer == 0:
		self.get_node("kickBox/kickAnimation").play("kick")
		lagTimer =  kickEndLag
		self.get_node("kickBox/kickHitbox").disabled = false
	elif lagTimer == 0:
		self.get_node("kickBox/kickHitbox").disabled = true
	
	#dashing
	if Input.is_action_just_pressed(self.name + str(fMotion)) and lagTimer == 0:
		if timer < dashTimer:
			dashing = true
			lagTimer = 12
			dashTimer = timer
			dF = true
		dashTimer = timer + 20
	
	if Input.is_action_just_pressed(self.name + str(bMotion)) and lagTimer == 0:
		if timer < dashTimer:
			dashing = true
			lagTimer = 12
			dashTimer = timer
			dB = true
		dashTimer = timer + 20
		
	if lagTimer == 0 and dashing:
		friction = 0.5
		dashing = false
		dF = false
		dB = false
		lagTimer = 2
		
		
	if dashing:
		if dF:
			motion.x = -dashingSpeed
			motion.y = 0
		if dB:
			motion.x = dashingSpeed - (10^(12-lagTimer))
			motion.y = 0

	#end of dashing
	
	if fireBallCheck: 
		infireball = true
		lagTimer = fireballStartup + fireballLag
		
	if infireball:
		
		$fireballAnim/fireballAnimation.play("fire")
		
		if lagTimer == fireballStartup:
			fireball = fireball_scene.instance()
			get_parent().add_child(fireball)
			fireball.init(self.position, onLeft(), self)
		
		if lagTimer == 0: infireball = false
		
	# is_on_floor() is a function that just works ig

	#kick
	if Input.is_action_pressed("%s_Attack" % self.name) and is_on_floor() and lagTimer == 0:
		$kickBox.visible = true
		$kickBox/kickAnimation.play("kick")
		lagTimer =  kickEndLag
		#$kickBox/kickHitbox.disabled = false
	elif lagTimer == 0:
		$kickBox.visible = false
		#$kickBox/kickHitbox.disabled = true
	
	
	
	# Jumping
	if Input.is_action_pressed("%s_Jump" % self.name) and is_on_floor() and lagTimer == 0:
		motion.y = -jumpMultiplier
		
	motion.y += gravityMultiplier * delta
		
	motion.x *= friction
	
	if not is_on_floor():
		motion.x *= airSpeedMultiplier
		
	motion.x *= delta
	
	if lagTimer > 0:
		lagTimer -= 1
	
	move_and_slide(motion, Vector2.UP)


# THIS IS WHERE WE WILL HANDLE BEING HIT
func _on_HurtBox_area_entered(area):
	print(self.name + " is hit!")
