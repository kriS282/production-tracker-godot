extends Popup

var main_script
var operators = ["John", "Sarah", "Mike", "Emma", "David", "Lisa", "Tom", "Anna"]

func _ready():
	main_script = get_parent()
	%CloseBtn.pressed.connect(_on_close_pressed)
	about_to_popup.connect(_on_about_to_popup)

func _on_about_to_popup():
	refresh_operator_list()

func refresh_operator_list():
	var operator_list = %OperatorList
	
	# Clear existing buttons
	for child in operator_list.get_children():
		child.queue_free()
	
	# Add operators
	for op in operators:
		var btn = Button.new()
		btn.text = op
		btn.custom_minimum_size = Vector2(0, 100)
		btn.add_theme_font_size_override("font_size", 36)
		btn.pressed.connect(func(): main_script.set_operator(op); hide())
		operator_list.add_child(btn)

func _on_close_pressed():
	hide()
