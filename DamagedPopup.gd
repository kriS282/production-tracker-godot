extends Window

@onready var punnets_input = %PunnetsInput
@onready var parent_tracker = get_parent()

func _ready():
	%ConfirmBtn.pressed.connect(_on_confirm_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	var punnets = int(punnets_input.text) if punnets_input.text.is_valid_int() else 0
	if punnets > 0:
		parent_tracker.mark_damaged(punnets)
		punnets_input.text = "0"
		hide()

func _on_cancel_pressed():
	hide()
