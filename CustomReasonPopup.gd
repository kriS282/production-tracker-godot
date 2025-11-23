extends Window

@onready var type_dropdown = %TypeDropdown
@onready var reason_input = %ReasonInput

func _ready():
	type_dropdown.add_item("Bad Product")
	type_dropdown.add_item("Bad Wrap")

	%AddBtn.pressed.connect(_on_add_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func _on_add_pressed():
	if type_dropdown.selected < 0:
		show_error("Please select type")
		return

	if reason_input.text.is_empty():
		show_error("Please enter reason")
		return

	var defect_type = "bad_product" if type_dropdown.selected == 0 else "bad_wrap"
	get_parent().add_custom_reason(defect_type, reason_input.text)

	reset_form()
	hide()

func _on_cancel_pressed():
	hide()

func reset_form():
	type_dropdown.selected = -1
	reason_input.text = ""

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
	await get_tree().create_timer(2.0).timeout
	%ErrorLabel.hide()
