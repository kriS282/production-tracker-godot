extends Window

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

@onready var username_input = %UsernameInput
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

	%CreateBtn.pressed.connect(_on_create_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

func _on_create_pressed():
	if username_input.text.is_empty() or password_input.text.is_empty():
		show_error("Username and password required")
		return

	if role_dropdown.selected < 0:
		show_error("Please select a role")
		return

	# Collect selected tasks
	var selected_tasks = []
	for child in tasks_container.get_children():
		if child is CheckBox and child.button_pressed:
			var task_name = child.name.replace("Task_", "")
			selected_tasks.append(task_name)

	if is_admin_check.button_pressed:
		selected_tasks.append("admin")

	var user = DataStore.create_user(
		username_input.text,
		password_input.text,
		roles[role_dropdown.selected],
		selected_tasks,
		is_admin_check.button_pressed
	)

	get_parent().load_users()
	get_parent().show_notification("User created: %s" % user.username)
	reset_form()
	hide()

func _on_cancel_pressed():
	hide()

func reset_form():
	username_input.text = ""
	password_input.text = ""
	role_dropdown.selected = -1
	is_admin_check.button_pressed = false
	for child in tasks_container.get_children():
		if child is CheckBox:
			child.button_pressed = false

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
	await get_tree().create_timer(3.0).timeout
	%ErrorLabel.hide()
