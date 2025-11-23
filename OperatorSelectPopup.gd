extends Window

# Popup for selecting wrapping operator

func _ready():
	%CancelBtn.pressed.connect(_on_cancel_pressed)
	populate_operators()

func populate_operators():
	# Clear existing buttons
	for child in %OperatorList.get_children():
		child.queue_free()

	# Get list of operators from DataStore
	var operators = DataStore.get_all_users()

	# Create button for each operator
	for operator in operators:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 120)
		btn.add_theme_font_size_override("font_size", 36)
		btn.text = "%s (%s)" % [operator.username, operator.role.capitalize()]
		btn.pressed.connect(func(): select_operator(operator.username))
		%OperatorList.add_child(btn)

func select_operator(operator_name: String):
	get_parent().set_operator(operator_name)
	hide()

func _on_cancel_pressed():
	hide()

func _on_close_requested():
	hide()
