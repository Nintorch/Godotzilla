class_name AttackDescription
extends Resource

enum Type {
	ONE_TIME,
	CONTINUOUS,
}

@export var name: String
@export var type: Type
@export var damage_amount: float
## Use -1.0 for the default value
@export var hurt_time: float = -1.0
@export var animation_name: String
## The second animation name is used for animataion variation,
## leave it empty if you don't need animation variation for this attack
@export var animation_name2: String
@export var hitbox_name: String
## Use this if you want the attack to first start the animation and
## after this amount of seconds start attacking the enemy 
@export var start_time_offset: float
