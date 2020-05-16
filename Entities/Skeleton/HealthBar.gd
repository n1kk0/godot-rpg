extends ColorRect

func _on_Skeleton_skeleton_stats_changed(var skeleton):
	$Bar.rect_size.x = 18 * skeleton.health / skeleton.health_max
