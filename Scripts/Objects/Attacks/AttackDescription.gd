class_name AttackDescription extends Resource

enum Type {
	ONE_TIME,
	CONTINUOUS,
	LASTS_FOREVER,
}

@export var name: String
@export_enum("Simple:0", "Advanced:1", "Simple & Advanced:2")
var simple_or_advanced: int
@export var other_information: Array[String]

@export_group("Simple Attack")
@export var type: Type
@export var damage_amount: float
@export var hitbox_name: String
@export_node_path("CollisionShape2D") var hitbox_node: NodePath
@export var sfx: AudioStream
@export var sfx_db: float
@export var sfx_offset: float

@export_group("Simple Attack/Animation And Timing")
## Use -1.0 for the default value
@export var hurt_time: float = -1.0
@export var invincibility_time: float = -1.0
## Use this if you want the attack to first start the animation and
## after this amount of seconds start attacking the enemy 
@export var start_time_offset: float
## -1 for default speed
@export var hurt_speed: float = -1.0
@export_node_path("AnimationPlayer") var animation_player: NodePath
## Other information about the attack, for example, if this is a
## poison attack and the objects have to react to it differently
@export var animation_name: String
## The second animation name is used for animataion variation,
## leave it empty if you don't need animation variation for this attack
@export var animation_name2: String
@export var animation_repeat_times := 1
## Use -1.0 to use the animation's length
@export var time_length: float = -1.0
## Specifies if the attack animation player should play the "RESET"
## animation before the attack starts
@export var reset_animation_before := true
## Specifies if the attack animation player should play the "RESET"
## animation after the attack ends
@export var reset_animation_after := true

@export_group("Advanced Attack")
## When the code calls for this attack and it is advanced,
## the usual attack component code will *not* be called, but instead
## this function inside of "Attack Function Node" from "Callbacks" section
## of attack component is called.
## The usual attack component code *will* be called though if the attack
## is selected as "Simple & Advanced".
## Example of when this is useful: Godzilla's Heat Beam, since it needs
## to have special treatment instead of being a simple animation with damage.
@export var function_name: String
