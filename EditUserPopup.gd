extends Window

var current_user_id = -1

var roles = [
	"Manager",
	"Packing Supervisor",
	"Picking Supervisor",
	"General Staff",
	"Picker"
]

var available_tasks = [
	"wrapping",
	"folding",
	"orders",
	"quality_control"
]

@onready var username_label = %UsernameLabel
@onready var password_input = %PasswordInput
@onready var role_dropdown = %RoleDropdown
@onready var tasks_container = %TasksContainer
@onready var is_admin_check = %IsAdminCheck

func _ready():
	# Populate role dropdown
	for role in roles:
		role_dropdown.add_item(role)

	# Create task checkboxes
	for task in available_tasks:
		var checkbox = CheckBox.new()
		checkbox.text = task.capitalize()
		checkbox.name = "Task_" + task
		tasks_container.add_child(checkbox)

	%SaveBtn.pressed.connect(_on_save_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func populate_user(user: Dictionary):
	current_user_id = user.id
	username_label.text = "Editing: %s" % user.username
	password_input.text = ""
	password_input.placeholder_text = "Leave empty to keep current"

	# Set role
	var role_idx = roles.find(user.role)
	if role_idx >= 0:
		role_dropdown.selected = role_idx

	# Set tasks
	var user_tasks = user.tasks if user.tasks is Array else []
	for child in tasks_container.get_children():
		if child is CheckBox:
			var task_name = child.name.replace("Task_", "")
			child.button_pressed = task_name in user_tasks

	is_admin_check.button_pressed = user.get("is_admin", false)

func _on_save_pressed():
	var updates = {}

	if role_dropdown.selected >= 0:
		updates["role"] = roles[role_dropdown.selected]

	# Collect tasks
	var selected_tasks = []
	for child in tasks_container.get_children():
		if child is CheckBox and child.button_pressed:
			var task_name = child.name.replace("Task_", "")
			selected_tasks.append(task_name)

	if is_admin_check.button_pressed:
		selected_tasks.append("admin")

	updates["tasks"] = selected_tasks
	updates["is_admin"] = is_admin_check.button_pressed

	# Update password if provided
	if not password_input.text.is_empty():
		updates["password_hash"] = password_input.text.sha256_text()

	DataStore.update_user(current_user_id, updates)
	get_parent().load_users()
	get_parent().show_notification("User updated")
	hide()

func _on_cancel_pressed():
	hide()
