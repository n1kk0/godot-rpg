extends Area2D

tool

enum Potion { HEALTH, MANA }
export(Potion) var type = Potion.HEALTH

func _process(_delta):
	if Engine.editor_hint:
		if type == Potion.MANA:
			$Sprite.region_rect.position.x = 8
		else:
			$Sprite.region_rect.position.x = 0

func _ready():
	if type == Potion.MANA:
		$Sprite.region_rect.position.x = 8
	else:
		$Sprite.region_rect.position.x = 0

func _on_Potion_body_entered(body):
	if body.name == "Player":
		body.add_potion(type)
		get_tree().queue_delete(self)
