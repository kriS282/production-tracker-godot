extends Window

var reasons = []

@onready var reason_dropdown = %ReasonDropdown
@onready var quantity_input = %QuantityInput
@onready var notes_input = %NotesInput

func _ready():
	%AddBtn.pressed.connect(_on_add_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func set_reasons(reasons_list: Array):
	reasons = reasons_list
	reason_dropdown.clear()
	for reason in reasons:
		reason_dropdown.add_item(reason)

func _on_add_pressed():
	if reason_dropdown.selected < 0:
		show_error("Please select a reason")
		return

	var qty = int(quantity_input.text) if quantity_input.text.is_valid_int() else 1
	if qty <= 0:
		qty = 1

	get_parent().add_defect(
		"bad_product",
		reasons[reason_dropdown.selected],
		qty,
		notes_input.text
	)

	reset_form()
	hide()

func _on_cancel_pressed():
	hide()

func reset_form():
	reason_dropdown.selected = -1
	quantity_input.text = "1"
	notes_input.text = ""

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
	await get_tree().create_timer(2.0).timeout
	%ErrorLabel.hide()
