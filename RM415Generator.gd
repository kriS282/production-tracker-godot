extends Window

signal form_completed(form_data: Dictionary)

var current_form_data = {}
var signature_data = null

# Punnet label checklist items
var punnet_checks = [
	"Product Name",
	"Weight",
	"Quantity",
	"Use By Date",
	"Day Code (Lwwdd)",
	"PN"
]

# Box label checklist items
var box_checks = [
	"Product Name",
	"Weight",
	"Quantity per Box",
	"Day Code"
]

@onready var product_input = %ProductInput
@onready var supplier_input = %SupplierInput
@onready var batch_input = %BatchInput
@onready var punnet_checklist = %PunnetChecklist
@onready var box_checklist = %BoxChecklist
@onready var print_quality_check = %PrintQualityCheck
@onready var labels_match_check = %LabelsMatchCheck
@onready var signature_pad = %SignaturePad

func _ready():
	# Connect buttons
	%SignBtn.pressed.connect(_on_sign_pressed)
	%GenerateBtn.pressed.connect(_on_generate_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

	# Setup checklists
	setup_punnet_checklist()
	setup_box_checklist()

	# Connect signature pad
	signature_pad.signature_completed.connect(_on_signature_completed)

func setup_punnet_checklist():
	# Clear existing
	for child in punnet_checklist.get_children():
		child.queue_free()

	# Add checkboxes for each item
	for check_item in punnet_checks:
		var hbox = HBoxContainer.new()
		var checkbox = CheckBox.new()
		checkbox.text = check_item
		checkbox.name = "Punnet_" + check_item.replace(" ", "")
		hbox.add_child(checkbox)
		punnet_checklist.add_child(hbox)

func setup_box_checklist():
	# Clear existing
	for child in box_checklist.get_children():
		child.queue_free()

	# Add checkboxes for each item
	for check_item in box_checks:
		var hbox = HBoxContainer.new()
		var checkbox = CheckBox.new()
		checkbox.text = check_item
		checkbox.name = "Box_" + check_item.replace(" ", "")
		hbox.add_child(checkbox)
		box_checklist.add_child(hbox)

func _on_sign_pressed():
	signature_pad.popup_centered()

func _on_signature_completed(sig_image: Image):
	signature_data = sig_image
	%SignatureStatus.text = "✓ Signature captured"
	%SignatureStatus.add_theme_color_override("font_color", Color.GREEN)

func _on_generate_pressed():
	if not validate_form():
		show_error("Please complete all required fields")
		return

	# Collect form data
	current_form_data = {
		"date": Time.get_date_string_from_system(),
		"time": Time.get_time_string_from_system(),
		"product": product_input.text,
		"supplier": supplier_input.text,
		"batch": batch_input.text,
		"punnet_checks": collect_punnet_checks(),
		"box_checks": collect_box_checks(),
		"print_quality_good": print_quality_check.button_pressed,
		"labels_match_box": labels_match_check.button_pressed,
		"signature": signature_pad.get_signature_as_base64() if signature_data else null
	}

	# Generate the form
	generate_html_form()

	form_completed.emit(current_form_data)
	show_notification("RM415 form generated!")

func validate_form() -> bool:
	if product_input.text.is_empty():
		return false
	if supplier_input.text.is_empty():
		return false
	if batch_input.text.is_empty():
		return false
	if signature_data == null:
		return false
	return true

func collect_punnet_checks() -> Dictionary:
	var checks = {}
	for child in punnet_checklist.get_children():
		if child is HBoxContainer:
			var checkbox = child.get_child(0)
			if checkbox is CheckBox:
				var key = checkbox.text.replace(" ", "_").to_lower()
				checks[key] = checkbox.button_pressed
	return checks

func collect_box_checks() -> Dictionary:
	var checks = {}
	for child in box_checklist.get_children():
		if child is HBoxContainer:
			var checkbox = child.get_child(0)
			if checkbox is CheckBox:
				var key = checkbox.text.replace(" ", "_").to_lower()
				checks[key] = checkbox.button_pressed
	return checks

func generate_html_form():
	# Generate HTML version of RM415 form
	var html = """
<!DOCTYPE html>
<html>
<head>
	<title>RM415 - Label Retention and Check Sheet</title>
	<style>
		body { font-family: Arial, sans-serif; margin: 20px; }
		.header { text-align: center; border-bottom: 2px solid black; padding-bottom: 10px; }
		.section { margin: 20px 0; border: 1px solid #ccc; padding: 15px; }
		.checklist { margin: 10px 0; }
		.check-item { padding: 5px 0; }
		.signature { border: 1px solid black; height: 100px; margin: 10px 0; }
		table { border-collapse: collapse; width: 100%; }
		td, th { border: 1px solid black; padding: 8px; }
		.pass { color: green; font-weight: bold; }
		.fail { color: red; font-weight: bold; }
	</style>
</head>
<body>
	<div class="header">
		<h2>RM415 - Label Retention and Check Sheet</h2>
	</div>

	<table>
		<tr>
			<td><strong>Date:</strong> %s</td>
			<td><strong>Time:</strong> %s</td>
		</tr>
		<tr>
			<td><strong>Product:</strong> %s</td>
			<td><strong>Batch Code:</strong> %s</td>
		</tr>
		<tr>
			<td colspan="2"><strong>Supplier:</strong> %s</td>
		</tr>
	</table>

	<div class="section">
		<h3>First Punnet Label Check</h3>
		<div class="checklist">
%s
		</div>
	</div>

	<div class="section">
		<h3>Box Label Check</h3>
		<div class="checklist">
%s
		</div>
		<div class="check-item">✓ Print Quality Good: %s</div>
		<div class="check-item">✓ Product Name & Weight Match Box: %s</div>
	</div>

	<div class="section">
		<h3>Last Punnet Label Check</h3>
		<p><em>Same checks as first punnet</em></p>
	</div>

	<div class="section">
		<h3>Signature</h3>
		<div class="signature">
%s
		</div>
	</div>
</body>
</html>
""" % [
		current_form_data.date,
		current_form_data.time,
		current_form_data.product,
		current_form_data.batch,
		current_form_data.supplier,
		format_checklist(current_form_data.punnet_checks),
		format_checklist(current_form_data.box_checks),
		"PASS" if current_form_data.print_quality_good else "FAIL",
		"PASS" if current_form_data.labels_match_box else "FAIL",
		get_signature_html()
	]

	# Save to file
	var file_path = "user://rm415_%s_%s.html" % [current_form_data.batch, current_form_data.date]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(html)
		file.close()
		print("RM415 form saved to:", file_path)
		print("Full path:", ProjectSettings.globalize_path(file_path))

func format_checklist(checks: Dictionary) -> String:
	var result = ""
	for key in checks:
		var label = key.replace("_", " ").capitalize()
		var status = "✓ PASS" if checks[key] else "✗ FAIL"
		var css_class = "pass" if checks[key] else "fail"
		result += '\t\t\t<div class="check-item"><span class="%s">%s</span> %s</div>\n' % [css_class, status, label]
	return result

func get_signature_html() -> String:
	if current_form_data.signature:
		return '<img src="data:image/png;base64,%s" style="max-width: 100%%; height: auto;">' % current_form_data.signature
	return "<p>No signature</p>"

func _on_cancel_pressed():
	hide()

func show_error(message: String):
	%ErrorLabel.text = message
	%ErrorLabel.show()
	await get_tree().create_timer(3.0).timeout
	%ErrorLabel.hide()

func show_notification(message: String):
	%NotificationLabel.text = message
	%NotificationLabel.show()
	await get_tree().create_timer(3.0).timeout
	%NotificationLabel.hide()

func populate_from_wrapping_session(product: String, supplier: String, batch: String):
	product_input.text = product
	supplier_input.text = supplier
	batch_input.text = batch
