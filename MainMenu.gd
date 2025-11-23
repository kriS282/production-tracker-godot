extends Control

func _ready():
	%BoxFoldingBtn.pressed.connect(_on_box_folding_pressed)
	%WrappingBtn.pressed.connect(_on_wrapping_pressed)

func _on_box_folding_pressed():
	get_tree().change_scene_to_file("res://BoxFolding.tscn")

func _on_wrapping_pressed():
	get_tree().change_scene_to_file("res://WrappingTracker.tscn")
