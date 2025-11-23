extends Control

# Box types with pallet quantities
const BOX_TYPES = {
	"12kg Green (Big boxes)": {
		"weight": "12kg",
		"per_pallet": 40
	},
	"6kg Green (Small boxes)": {
		"weight": "6kg",
		"per_pallet": 80
	}
}

# UI References using unique names
@onready var operator_label = %OperatorLabel
@onready var box_type_label = %BoxTypeLabel
@onready var count_label = %CountLabel
@onready var pallet_count_label = %PalletCountLabel
@onready var timer_label = %TimerLabel
@onready var add_custom_popup = %AddCustomPopup

# State variables
var current_operator = ""
var current_box_type = ""
var box_count = 0
var session_time = 0.0
var timer_running = false
var pallets_completed = 0  # Track full pallets

func _ready():
	update_ui()
	
	# Connect buttons using unique names
	%BackBtn.pressed.connect(_on_back_pressed)
	%SelectOperatorBtn.pressed.connect(_on_select_operator_pressed)
	%SelectBoxTypeBtn.pressed.connect(_on_select_box_type_pressed)
	%AddCustomBtn.pressed.connect(_on_add_custom_pressed)
	%IncrementBtn.pressed.connect(_on_increment_pressed)
	%DecrementBtn.pressed.connect(_on_decrement_pressed)
	%StartStopBtn.pressed.connect(_on_start_stop_pressed)
	%ResetBtn.pressed.connect(_on_reset_pressed)
	%SaveSessionBtn.pressed.connect(_on_save_session_pressed)

func _process(delta):
	if timer_running:
		session_time += delta
		update_timer_display()

func update_timer_display():
	var hours = int(session_time) / 3600
	var minutes = (int(session_time) % 3600) / 60
	var seconds = int(session_time) % 60
	timer_label.text = "%02d:%02d:%02d" % [hours, minutes, seconds]

func update_ui():
	operator_label.text = current_operator if not current_operator.is_empty() else "No operator selected"
	box_type_label.text = current_box_type if not current_box_type.is_empty() else "No box type selected"
	count_label.text = "Count: %d" % box_count
	
	# Calculate and display pallets
	if not current_box_type.is_empty():
		var per_pallet = BOX_TYPES[current_box_type]["per_pallet"]
		var total_pallets = float(box_count) / per_pallet
		var full_pallets = int(box_count / per_pallet)
		var remainder = box_count % per_pallet
		
		# Show detailed pallet info
		pallet_count_label.text = "Pallets: %d full + %d boxes\n(Total: %.2f pallets)" % [full_pallets, remainder, total_pallets]
		
		# Enable custom add button
		%AddCustomBtn.disabled = false
	else:
		pallet_count_label.text = "Pallets: Select box type first"
		%AddCustomBtn.disabled = true

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_select_operator_pressed():
	%OperatorPopup.popup_centered()

func _on_select_box_type_pressed():
	%BoxTypePopup.popup_centered()

func _on_add_custom_pressed():
	add_custom_popup.popup_centered()

func _on_increment_pressed():
	add_boxes(1)

func _on_decrement_pressed():
	if box_count > 0:
		box_count -= 1
		update_ui()

func _on_start_stop_pressed():
	timer_running = not timer_running
	%StartStopBtn.text = "Stop Timer" if timer_running else "Start Timer"

func _on_reset_pressed():
	box_count = 0
	session_time = 0.0
	timer_running = false
	pallets_completed = 0
	update_ui()
	update_timer_display()
	%StartStopBtn.text = "Start Timer"

func _on_save_session_pressed():
	if current_operator.is_empty() or current_box_type.is_empty():
		print("Error: Select operator and box type first!")
		return
	
	# Save session data (TODO: send to server)
	var session_data = {
		"operator": current_operator,
		"box_type": current_box_type,
		"count": box_count,
		"time": session_time,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	print("Session saved:", session_data)
	print("TODO: Send to server for inventory tracking")
	
	# Show confirmation
	%SaveLabel.text = "✓ Saved!"
	%SaveLabel.show()
	await get_tree().create_timer(2.0).timeout
	%SaveLabel.hide()
	
	# Reset for next session
	_on_reset_pressed()

func add_boxes(amount: int):
	if not current_box_type.is_empty():
		var old_count = box_count
		box_count += amount
		
		# Check if we completed any pallets
		var per_pallet = BOX_TYPES[current_box_type]["per_pallet"]
		var old_pallets = int(old_count / per_pallet)
		var new_pallets = int(box_count / per_pallet)
		
		if new_pallets > old_pallets:
			# Completed a pallet!
			var completed = new_pallets - old_pallets
			pallets_completed += completed
			show_pallet_notification(completed)
		
		update_ui()

func show_pallet_notification(count: int):
	var msg = "🎉 Pallet Complete!" if count == 1 else "🎉 %d Pallets Complete!" % count
	%NotificationLabel.text = msg
	%NotificationLabel.show()
	await get_tree().create_timer(2.0).timeout
	%NotificationLabel.hide()

func set_operator(operator_name: String):
	current_operator = name
	update_ui()

func set_box_type(box_type: String):
	current_box_type = box_type
	update_ui()
