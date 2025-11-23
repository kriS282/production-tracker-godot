extends Window

signal signature_completed(signature_data: Image)

var drawing = false
var signature_image: Image
var last_point = Vector2.ZERO
var line_color = Color.BLACK
var line_width = 3.0

@onready var draw_area = %DrawArea
@onready var canvas = %Canvas

func _ready():
	# Initialize signature image (white background)
	signature_image = Image.create(800, 400, false, Image.FORMAT_RGB8)
	signature_image.fill(Color.WHITE)

	# Connect buttons
	%ClearBtn.pressed.connect(_on_clear_pressed)
	%SaveBtn.pressed.connect(_on_save_pressed)
	%CancelBtn.pressed.connect(_on_cancel_pressed)

	# Set up draw area
	draw_area.gui_input.connect(_on_draw_area_input)

func _on_draw_area_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drawing = true
				last_point = event.position
			else:
				drawing = false

	elif event is InputEventMouseMotion and drawing:
		var current_point = event.position
		draw_line_on_image(last_point, current_point)
		last_point = current_point
		canvas.queue_redraw()

func draw_line_on_image(from: Vector2, to: Vector2):
	# Draw line on the signature image
	var steps = int(from.distance_to(to))
	for i in range(steps + 1):
		var t = float(i) / float(steps) if steps > 0 else 0.0
		var point = from.lerp(to, t)

		# Draw circle for smooth line
		for dx in range(-int(line_width), int(line_width) + 1):
			for dy in range(-int(line_width), int(line_width) + 1):
				if dx * dx + dy * dy <= line_width * line_width:
					var px = int(point.x) + dx
					var py = int(point.y) + dy
					if px >= 0 and px < signature_image.get_width() and py >= 0 and py < signature_image.get_height():
						signature_image.set_pixel(px, py, line_color)

func _on_clear_pressed():
	signature_image.fill(Color.WHITE)
	canvas.queue_redraw()

func _on_save_pressed():
	signature_completed.emit(signature_image)
	hide()

func _on_cancel_pressed():
	hide()

func get_signature_as_base64() -> String:
	# Convert image to PNG and encode as base64
	var png_data = signature_image.save_png_to_buffer()
	return Marshalls.raw_to_base64(png_data)

func reset():
	signature_image.fill(Color.WHITE)
	canvas.queue_redraw()
	drawing = false
