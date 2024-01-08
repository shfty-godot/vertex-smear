class_name VertexSmearMaterial
extends ShaderMaterial
tool

const DATA_FLAGS = Texture.FLAG_FILTER | Texture.FLAG_VIDEO_SURFACE

export(Curve3D) var curve: Curve3D setget set_curve

export(ImageTexture) var _data: ImageTexture

func set_curve(new_curve: Curve3D) -> void:
	if curve != new_curve:
		if curve and curve.is_connected("changed", self, "_on_curve_changed"):
			curve.disconnect("changed", self, "_on_curve_changed")

		curve = new_curve

		if curve and not curve.is_connected("changed", self, "_on_curve_changed"):
			curve.connect("changed", self, "_on_curve_changed")

		_on_curve_changed()

var _smear_shader := preload("res://vertex_smear.shader") as Shader

func _init() -> void:
	_data = ImageTexture.new()
	_data.flags = DATA_FLAGS

	set_shader(_smear_shader)

	if not curve:
		set_curve(Curve3D.new())

func _on_curve_changed() -> void:
	if not curve:
		return

	var point_count = curve.get_point_count()
	if point_count == 0:
		return

	if _data.get_data() == null or _data.get_size().x != point_count or _data.get_size().y != 3:
		var image = Image.new()
		image.create(point_count, 3, false, Image.FORMAT_RGBF)
		_data.create_from_image(image, DATA_FLAGS)

	var image = _data.get_data()
	image.lock()
	for i in range(0, point_count):
		var position = vec_to_color(curve.get_point_position(i))
		var handle_in = vec_to_color(curve.get_point_in(i))
		var handle_out = vec_to_color(curve.get_point_out(i))
		image.set_pixel(i, 0, position)
		image.set_pixel(i, 1, handle_in)
		image.set_pixel(i, 2, handle_out)
	image.unlock()
	_data.set_data(image)

	set_shader_param("data", _data)

func vec_to_color(vec: Vector3, w: float = 1.0) -> Color:
	return Color(vec.x, vec.y, vec.z, w)
