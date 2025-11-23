extends Window

@onready var crates_input = %CratesInput
@onready var parent_tracker = get_parent()

func _ready():
	%ConfirmBtn.pressed.connect(_on_confirm_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	var crates = int(crates_input.text) if crates_input.text.is_valid_int() else 0
	if crates > 0:
		parent_tracker.add_leftovers(crates)
		crates_input.text = "0"
		hide()

func _on_cancel_pressed():
	hide()
