extends Control

# Quality control defect tracking

var current_user = {}
var defects = []
var bad_product_reasons = []
var bad_wrap_reasons = []

@onready var defects_list = %DefectsList
@onready var bad_product_count = %BadProductCount
@onready var bad_wrap_count = %BadWrapCount

func _ready():
	current_user = DataStore.get_current_user()

	if current_user.is_empty():
		get_tree().change_scene_to_file("res://LoginScreen.tscn")
		return

	connect_buttons()
	load_defect_reasons()
	load_today_defects()

func connect_buttons():
	%BackBtn.pressed.connect(_on_back_pressed)
	%AddBadProductBtn.pressed.connect(_on_add_bad_product_pressed)
	%AddBadWrapBtn.pressed.connect(_on_add_bad_wrap_pressed)
	%AddCustomReasonBtn.pressed.connect(_on_add_custom_reason_pressed)

func load_defect_reasons():
	bad_product_reasons = DataStore.get_defect_reasons("bad_product")
	bad_wrap_reasons = DataStore.get_defect_reasons("bad_wrap")

func load_today_defects():
	# In a full implementation, filter by today's date
	# For now, show all defects
	update_defects_display()

func update_defects_display():
	# Clear existing
	for child in defects_list.get_children():
		child.queue_free()

	var product_total = 0
	var wrap_total = 0

	# Count defects by type
	for defect in defects:
		if defect.defect_type == "bad_product":
			product_total += defect.quantity
		elif defect.defect_type == "bad_wrap":
			wrap_total += defect.quantity

		var defect_panel = create_defect_panel(defect)
		defects_list.add_child(defect_panel)

	bad_product_count.text = "Bad Product: %d" % product_total
	bad_wrap_count.text = "Bad Wrap: %d" % wrap_total

	if defects.is_empty():
		var label = Label.new()
		label.text = "No defects recorded today"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		defects_list.add_child(label)

func create_defect_panel(defect: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "%s - %s (×%d)" % [
		defect.defect_type.capitalize().replace("_", " "),
		defect.defect_reason,
		defect.quantity
	]
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	if defect.has("notes") and not defect.notes.is_empty():
		var notes = Label.new()
		notes.text = "Notes: %s" % defect.notes
		vbox.add_child(notes)

	var time = Label.new()
	time.text = defect.recorded_at
	time.add_theme_font_size_override("font_size", 14)
	vbox.add_child(time)

	return panel

func add_defect(defect_type: String, reason: String, quantity: int, notes: String = ""):
	var defect_data = {
		"session_id": -1,  # Can be linked to a session later
		"defect_type": defect_type,
		"defect_reason": reason,
		"quantity": quantity,
		"notes": notes,
		"user_id": current_user.id
	}

	DataStore.add_defect(defect_data)
	defects.append(defect_data)
	update_defects_display()
	show_notification("Defect recorded: %s - %s" % [defect_type.replace("_", " ").capitalize(), reason])

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_add_bad_product_pressed():
	%BadProductPopup.set_reasons(bad_product_reasons)
	%BadProductPopup.popup_centered()

func _on_add_bad_wrap_pressed():
	%BadWrapPopup.set_reasons(bad_wrap_reasons)
	%BadWrapPopup.popup_centered()

func _on_add_custom_reason_pressed():
	%CustomReasonPopup.popup_centered()

func add_custom_reason(defect_type: String, reason: String):
	DataStore.add_defect_reason(defect_type, reason)
	load_defect_reasons()
	show_notification("Custom reason added: %s" % reason)

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(2.0).timeout
	%NotificationLabel.hide()
