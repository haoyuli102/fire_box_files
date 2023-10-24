extends KinematicBody2D


export(float) var MAX_HEALTH = 3
var health: float = MAX_HEALTH

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

export(int) var fireballLag = 30
export(int) var kickEndLag = 30

#timers
var timer = 0
var dashTimer = 0
var lagTimer = 0

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
	
func _ready():
	##target = $"../P1"
	##is_ai_controlled = true
	setup_ai_think_time_timer()
	._onready()
	
	
func ai_get_direction():
			##return target.position - self.position
	var direction = 500

func ai_move():
	var direction = ai_get_direction()
	var motion = direction.normalized() * forwardSpeed
	move_and_slide(motion)

func setup_ai_think_time_timer():
	ai_think_time_timer = Timer.new()
	ai_think_time_timer.set_one_shot(true)
	ai_think_time_timer.set_wait_time(ai_think_time)
	ai_think_time_timer.connect("timeout", self, "on_ai_thinktime_timeout_complete")
	add_child(ai_think_time_timer)
	
	
#need to detect the health state of the player
## need to add a get_state() func in player script
	
func decide_to_attack():
	ai_think_time_timer.start()

func on_ai_thinktime_timeout_complete():
	if is_in_range && state == 0 && target.get_state() == 0:
			attack()
		
func _process(delta):
	if state == 0 && target.get_state() == 0:
		if is_in_range && ai_think_time_timer.time_left == 0:
			decide_to_attack()
		else:
			ai_move()
func _physics_process(delta):
	
	timer += 1

	#Checking if the sprite just flipped
	if hasFliped():
		if flipped:
			# player things
			$PlayerSprite.offset = Vector2(110, 0)
			$PlayerSprite.flip_h = true
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
