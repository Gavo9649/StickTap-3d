extends Node3D



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if transform.origin.x > 12 or transform.origin.x < -12 or transform.origin.z > 26 or transform.origin.z < -26 or transform.origin.y < -1:
		transform.origin.x = 0
		transform.origin.y = 1
		transform.origin.z = 0 
