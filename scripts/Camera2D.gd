extends Camera2D

var target = null

func _physics_process(delta):
	if target:
		if get_node("/root/main").camerafollow == 1:
        	global_position = target.global_position
