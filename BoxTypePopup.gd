extends Popup

var main_script

func _ready():
	main_script = get_parent()
	%CloseBtn.pressed.connect(_on_close_pressed)
	about_to_popup.connect(_on_about_to_popup)

func _on_about_to_popup():
	refresh_box_type_list()

func refresh_box_type_list():
	var box_type_list = %BoxTypeList
	
	# Clear existing buttons
	for child in box_type_list.get_children():
		child.queue_free()
	
	# Add box types
	for box_type in main_script.BOX_TYPES.keys():
		var per_pallet = main_script.BOX_TYPES[box_type]["per_pallet"]
		var btn = Button.new()
		btn.text = "%s\n(%d per pallet)" % [box_type, per_pallet]
		btn.custom_minimum_size = Vector2(0, 120)
		btn.add_theme_font_size_override("font_size", 36)
		btn.pressed.connect(func(): main_script.set_box_type(box_type); hide())
		box_type_list.add_child(btn)

func _on_close_pressed():
	hide()
