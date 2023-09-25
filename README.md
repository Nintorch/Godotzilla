# Godotzilla
Godotzilla is a Godzilla: Monster of Monsters-styled framework made for Godot 4.1.

This framework can be used for anything you want, from GMoM remakes to NES Godzilla Creepypasta remakes to playable fan stories.

## Usage
The boards scenes should inherit from "Scenes/Boards/Board.tscn" and levels from "Scenes/Levels/TestLevel.tscn".
The player scene is "Objects/Player.tscn", and it shouldn't be too hard to find the meaning and usage of all the other scenes.

"Scenes/Main.tscn" is the one that surrounds other scenes (to include some objects that are needed on every scene, such as music player and fade objects) and also to provide flexibility for managing scenes at runtime (with that you can literally save the current scene node to a variable, return to it later and the original scene won't have any changes or even be restarted). But it's not limited to just saving the scene to a variable and loading it from a saved node, you can change the current scene at runtime to a PackedScene and the code will instantiate a node out of it.

Default input map is from keyboard to "NES controller" is:
- Arrow keys - direction buttons
- Z - B
- X - A
- Enter - Start
- Space - Select
And all the input actions are accurate to the original game.
