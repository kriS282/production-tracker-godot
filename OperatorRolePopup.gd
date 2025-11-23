extends Window

# Roles available in the system
var roles = [
	"Manager",
	"Packing Supervisor",
	"Picking Supervisor",
	"General Staff",
	"Picker"
]

# Operators (can be edited later or loaded from database)
var operators = [
	"John",
	"Sarah",
	"Mike",
	"Emma",
	"David",
	"Lisa",
	"Tom",
	"Anna"
]

@onready var operator_dropdown = %OperatorDropdown
@onready var role_dropdown = %RoleDropdown
@onready var parent_tracker = get_parent()

func _ready():
	# Populate dropdowns
	for op in operators:
		operator_dropdown.add_item(op)

	for role in roles:
		role_dropdown.add_item(role)

	# Connect buttons
	%ConfirmBtn.pressed.connect(_on_confirm_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	if operator_dropdown.selected >= 0 and role_dropdown.selected >= 0:
		var operator = operators[operator_dropdown.selected]
		var role = roles[role_dropdown.selected]
		parent_tracker.set_operator(operator, role)
		hide()

func _on_cancel_pressed():
	hide()
