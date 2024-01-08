extends MeshInstance
tool

export(int) var window_size := 10

var _position_window := []
var _normal := Vector3.FORWARD

func _process(dt: float) -> void:
	# Empty window if larger than target size
	while _position_window.size() > window_size:
		_position_window.remove(0)

	# Fill window if smaller than target size
	while _position_window.size() < window_size:
		_position_window.append(global_transform.origin)

	# Shift window left
	for i in range(0, _position_window.size() - 1):
		_position_window[i] = _position_window[i + 1]

	# Write global transform to end of window
	_position_window[_position_window.size() - 1] = global_transform.origin


	var v1 = _position_window[0] - global_transform.origin

	var o0 = _position_window[(_position_window.size() - 1) / 2] - global_transform.origin

	if v1 != Vector3.ZERO:
		_normal = v1.normalized()
		if v1.length() <= 0.5:
			v1 = _normal * 0.5
		material_override.set_shader_param("endpoint", v1)
	else:
		material_override.set_shader_param("endpoint", _normal * 0.5)

	material_override.set_shader_param("handle", o0)
