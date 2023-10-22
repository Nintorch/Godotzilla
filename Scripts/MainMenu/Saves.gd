extends "res://Scripts/MainMenu/Menu.gd"

# Explanation of the save system:
# When the player gets on a board (using a save ofc)
# the board's name is saved in the save file.
# In this menu the needed BoardDescription is found by
# comparing the board names
#
# After the player completes the board, the next board
# the player is sent to is determined by "next_board"
# exported variable.

# TODO: save system

@export var initial_board: PackedScene
@export var boards: Array[BoardDescription]
