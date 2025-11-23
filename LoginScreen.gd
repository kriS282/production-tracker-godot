extends Control

@onready var username_input = %UsernameInput
@onready var password_input = %PasswordInput
@onready var error_label = %ErrorLabel

func _ready():
	%LoginBtn.pressed.connect(_on_login_pressed)
	password_input.secret = true

func _on_login_pressed():
	var username = username_input.text
	var password = password_input.text

	if username.is_empty() or password.is_empty():
		show_error("Please enter username and password")
		return

	var user = DataStore.authenticate_user(username, password)

	if user.is_empty():
		show_error("Invalid username or password")
		return

	# Login successful
	print("✅ Logged in as: %s (%s)" % [user.username, user.role])
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func show_error(message: String):
	error_label.text = message
	error_label.show()
	await get_tree().create_timer(3.0).timeout
	error_label.hide()
