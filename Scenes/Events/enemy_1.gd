extends KinematicBody2D

const GRAVITY = 3000.0

var vertical
export var velocity = 350
var v = Vector2(-velocity, 0)

onready var sprite = get_node("sprite")
onready var area_head = get_node("area_head")

onready var hit_single = get_node("hit_ray_particle")

export(bool) var dir_left = true;

export(int) var life = 2

export(int) var damage = 1

func reverse_direction():
	sprite.set_flip_h(v.x < 0)
	dir_left = !dir_left
	v = Vector2(-v.x,0)

func _ready():
	if (!dir_left):
		reverse_direction()
	#set_fixed_process(true)
	set_process(true)

func dissapear():
	sprite.set_opacity(0)
	set_fixed_process(false)
	set_layer_mask_bit(2,false)
	
	hit_single.set_emitting(true)
	var t = Timer.new()
	t.set_wait_time(hit_single.get_lifetime())
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	queue_free()

func die_by_jump():
	life = 0
	dissapear()

func die():
	dissapear()

func on_opacity_low ():
	sprite.set_modulate(Color("fb12e7"))

func on_opacity_high ():
	sprite.set_modulate(Color("00ffff"))

func decrease_life (value):
	hit_single.set_emitting(false)
	hit_single.set_emitting(true)
	var t1 = Timer.new()
	var t2 = Timer.new()
	t1.set_wait_time(0.07)
	t2.set_wait_time(0.07)
	t1.set_one_shot(true)
	t2.set_one_shot(true)
	t1.connect("timeout",self,"on_opacity_low")
	t2.connect("timeout",self,"on_opacity_high")
	add_child(t1)
	add_child(t2)
	t1.start()
	yield(t1, "timeout")
	t2.start()
	yield(t2, "timeout")	
	sprite.set_modulate(Color("ffffff"))
	if (life > 0):
		life -= value
		if (life <= 0):
			die()
	
func restore_velocity():
	if(dir_left):
		v.x = -velocity
	else:
		v.x = velocity

func change_velocity(amount, right):
	if (right == dir_left):
		v.x = ((!dir_left * -1) + (dir_left * 1)) * amount
	else:
		v.x += ((dir_left * -1) + (!dir_left * 1)) * amount
	

func _process(delta):
	var motion = v * delta
	motion = move(motion)
	v.y += delta * GRAVITY
    
	if (is_colliding()):
		var normal = get_collision_normal();
		
		if (normal.y < 0):
			if (normal.y > -1):
				v.y = -velocity
			var aux = v.x
			motion = normal.slide(motion)
			v = normal.slide(v)
			move(motion)
			v.x = aux
		if (normal.x < -0.9 or normal.x > 0.9):
			reverse_direction()

func _on_area_body_body_enter( body ):
	if (body.is_in_group("player") and life > 0):
		body.on_receive_damage(damage)

func _on_area_head_body_enter( body ):
	if (body.is_in_group("player")):
		if (body.foots.get_global_pos().y > area_head.get_global_pos().y and body.is_falling()):
			life = 0
			die_by_jump()