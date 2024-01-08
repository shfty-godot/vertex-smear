# A Path that tracks its world-space position using a rolling window

class_name PathTracker
extends Path
tool

export(int) var window_size := 10
export(bool) var eager := true

var _prev_origin := Vector3.ZERO

func _ready() -> void:
	curve.set_point_position(0, Vector3.ZERO)
	_prev_origin = global_transform.origin

func _process(dt: float) -> void:
	if not curve:
		return

	# Empty window if larger than target size
	while curve.get_point_count() > window_size:
		curve.remove_point(0)

	# Fill window if smaller than target size
	while curve.get_point_count() < window_size:
		curve.add_point(curve.interpolatef(curve.get_point_count() - 1))

	# Calculate motion
	var delta = global_transform.origin - _prev_origin

	if not eager and delta == Vector3.ZERO:
		return

	# Shift window
	for i in range(0, window_size - 1):
		# Iterate backwards
		i = (window_size - 1) - i

		# Overwrite current index with previous index, applying motion
		curve.set_point_position(i, curve.get_point_position(i - 1) - delta)

	# Cache origin for next frame
	_prev_origin = global_transform.origin

	# Force identity rotation
	global_transform.basis = Basis.IDENTITY
