extends Control

var current_user = {}

func _ready():
	current_user = DataStore.get_current_user()

	if current_user.is_empty():
		# Not logged in, go to login screen
		get_tree().change_scene_to_file("res://LoginScreen.tscn")
		return

	update_ui()
	connect_buttons()

func update_ui():
	%WelcomeLabel.text = "Welcome, %s" % current_user.username
	%RoleLabel.text = "Role: %s" % current_user.role

	# Show/hide buttons based on user tasks
	%BoxFoldingBtn.visible = "folding" in current_user.tasks
	%WrappingBtn.visible = "wrapping" in current_user.tasks
	%OrdersBtn.visible = "orders" in current_user.tasks
	%QualityControlBtn.visible = "quality_control" in current_user.tasks
	%AdminBtn.visible = current_user.is_admin

func connect_buttons():
	%BoxFoldingBtn.pressed.connect(_on_box_folding_pressed)
	%WrappingBtn.pressed.connect(_on_wrapping_pressed)
	%OrdersBtn.pressed.connect(_on_orders_pressed)
	%QualityControlBtn.pressed.connect(_on_quality_control_pressed)
	%AdminBtn.pressed.connect(_on_admin_pressed)
	%LogoutBtn.pressed.connect(_on_logout_pressed)

func _on_box_folding_pressed():
	get_tree().change_scene_to_file("res://BoxFolding.tscn")

func _on_wrapping_pressed():
	get_tree().change_scene_to_file("res://WrappingTrackerNew.tscn")

func _on_orders_pressed():
	get_tree().change_scene_to_file("res://OrdersManager.tscn")

func _on_quality_control_pressed():
	get_tree().change_scene_to_file("res://QualityControl.tscn")

func _on_admin_pressed():
	get_tree().change_scene_to_file("res://AdminPanel.tscn")

func _on_logout_pressed():
	DataStore.logout()
	get_tree().change_scene_to_file("res://LoginScreen.tscn")
