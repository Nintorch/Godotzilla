class_name AttackDescription
extends Resource

enum Type {
	ONE_TIME,
	CONTINUOUS,
	LASTS_FOREVER,
}

@export var name: String
@export var type: Type
@export var damage_amount: float
@export var hitbox_name: String
@export var sfx: AudioStream
@export var other_information: Array[String]
@export_group("Animation and timing")
## Use -1.0 for the default value
@export var hurt_time: float = -1.0
## Use this if you want the attack to first start the animation and
## after this amount of seconds start attacking the enemy 
@export var start_time_offset: float
## Other information about the attack, for example, if this is a
## poison attack and the objects have to react to it differently
@export var animation_name: String
## The second animation name is used for animataion variation,
## leave it empty if you don't need animation variation for this attack
@export var animation_name2: String
## Use -1.0 to use the animation's length
@export var time_length: float = -1.0
## Specifies if the attack animation player should play the "RESET"
## animation after the attack ends
@export var reset_animation_after := true
