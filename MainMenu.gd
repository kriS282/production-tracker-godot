extends Control

func _ready():
	%BoxFoldingBtn.pressed.connect(_on_box_folding_pressed)

func _on_box_folding_pressed():
	get_tree().change_scene_to_file("res://BoxFolding.tscn")
