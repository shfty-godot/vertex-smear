extends Spatial
tool

export(bool) var running := true
export(Vector3) var delta := Vector3.ZERO

func _process(dt: float) -> void:
    if running:
        rotation_degrees += delta * dt
