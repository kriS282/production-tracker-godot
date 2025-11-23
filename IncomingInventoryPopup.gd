extends Window

@onready var pallets_input = %PalletsInput
@onready var crates_input = %CratesInput
@onready var harvest_date_input = %HarvestDateInput
@onready var parent_tracker = get_parent()

func _ready():
	# Set default harvest date to today
	harvest_date_input.text = Time.get_date_string_from_system()

	# Connect buttons
	%ConfirmBtn.pressed.connect(_on_confirm_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	var pallets = int(pallets_input.text) if pallets_input.text.is_valid_int() else 0
	var crates = int(crates_input.text) if crates_input.text.is_valid_int() else 0
	var harvest_date = harvest_date_input.text

	if pallets > 0 or crates > 0:
		parent_tracker.add_incoming_inventory(pallets, crates, harvest_date)
		# Reset inputs
		pallets_input.text = "0"
		crates_input.text = "0"
		harvest_date_input.text = Time.get_date_string_from_system()
		hide()

func _on_cancel_pressed():
	hide()
