extends Popup

var main_script
var current_value = ""

# Quick add presets
var presets = [10, 20, 40, 80]

func _ready():
	main_script = get_parent()
	
	# Create number buttons (1-9)
	for i in range(1, 10):
		var btn = Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(140, 120)
		btn.pressed.connect(func(): add_digit(str(i)))
		%KeypadGrid.add_child(btn)
	
	# Bottom row: Clear, 0, Backspace
	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.custom_minimum_size = Vector2(140, 120)
	clear_btn.pressed.connect(clear_display)
	%KeypadGrid.add_child(clear_btn)
	
	var zero_btn = Button.new()
	zero_btn.text = "0"
	zero_btn.custom_minimum_size = Vector2(140, 120)
	zero_btn.pressed.connect(func(): add_digit("0"))
	%KeypadGrid.add_child(zero_btn)
	
	var backspace_btn = Button.new()
	backspace_btn.text = "←"
	backspace_btn.custom_minimum_size = Vector2(140, 120)
	backspace_btn.pressed.connect(backspace)
	%KeypadGrid.add_child(backspace_btn)
	
	# Create preset buttons
	for preset in presets:
		var btn = Button.new()
		btn.text = "+%d" % preset
		btn.custom_minimum_size = Vector2(0, 80)
		btn.pressed.connect(func(): set_and_add(preset))
		%PresetContainer.add_child(btn)
	
	%AddBtn.pressed.connect(_on_add_pressed)
	%CloseBtn.pressed.connect(_on_close_pressed)
	about_to_popup.connect(_on_about_to_popup)

func _on_about_to_popup():
	current_value = ""
	update_display()

func add_digit(digit: String):
	if current_value.length() < 6:
		current_value += digit
		update_display()

func backspace():
	if current_value.length() > 0:
		current_value = current_value.substr(0, current_value.length() - 1)
		update_display()

func clear_display():
	current_value = ""
	update_display()

func update_display():
	%Display.text = current_value if not current_value.is_empty() else "0"

func set_and_add(amount: int):
	main_script.add_boxes(amount)
	hide()

func _on_add_pressed():
	var amount = int(current_value) if not current_value.is_empty() else 0
	if amount > 0:
		main_script.add_boxes(amount)
		hide()

func _on_close_pressed():
	hide()
