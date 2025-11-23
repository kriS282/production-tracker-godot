extends Control

# Admin panel for user and task management

var current_user = {}
var users = []

@onready var users_list = %UsersList

func _ready():
	current_user = DataStore.get_current_user()

	if current_user.is_empty() or not current_user.is_admin:
		get_tree().change_scene_to_file("res://MainMenu.tscn")
		return

	connect_buttons()
	load_users()

func connect_buttons():
	%BackBtn.pressed.connect(_on_back_pressed)
	%NewUserBtn.pressed.connect(_on_new_user_pressed)
	%RefreshBtn.pressed.connect(_on_refresh_pressed)

func load_users():
	users = DataStore.get_all_users()
	update_users_list()

func update_users_list():
	# Clear existing
	for child in users_list.get_children():
		child.queue_free()

	# Add users
	for user in users:
		var user_panel = create_user_panel(user)
		users_list.add_child(user_panel)

func create_user_panel(user: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = "%s (%s)" % [user.username, user.role]
	name_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(name_label)

	var tasks_label = Label.new()
	var tasks_str = ", ".join(user.tasks) if user.tasks is Array else user.tasks
	tasks_label.text = "Tasks: %s" % tasks_str
	vbox.add_child(tasks_label)

	var admin_label = Label.new()
	admin_label.text = "Admin" if user.is_admin else "Staff"
	vbox.add_child(admin_label)

	# Edit button
	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.custom_minimum_size = Vector2(100, 60)
	edit_btn.pressed.connect(func(): edit_user(user))
	hbox.add_child(edit_btn)

	# Delete button (can't delete yourself)
	if user.id != current_user.id:
		var delete_btn = Button.new()
		delete_btn.text = "Delete"
		delete_btn.custom_minimum_size = Vector2(100, 60)
		delete_btn.pressed.connect(func(): delete_user(user))
		hbox.add_child(delete_btn)

	return panel

func edit_user(user: Dictionary):
	%EditUserPopup.populate_user(user)
	%EditUserPopup.popup_centered()

func delete_user(user: Dictionary):
	DataStore.delete_user(user.id)
	load_users()
	show_notification("User deleted: %s" % user.username)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_new_user_pressed():
	%NewUserPopup.popup_centered()

func _on_refresh_pressed():
	load_users()
	show_notification("Users refreshed")

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(2.0).timeout
	%NotificationLabel.hide()
