tool
extends Spatial

var meshes := []

export(Color) var color setget set_color

func _ready():
	meshes = get_meshes(self)

func set_color(color_in:Color):
	color = color_in
	for mesh in meshes:
		var m = (mesh as MeshInstance)
		m.mesh.surface_get_material(0).albedo_color = color

func get_meshes(node:Node)->Array:
	var ret := []
	for c in node.get_children():
		if c is MeshInstance:
			ret.append(c)
		ret.append_array(get_meshes(c))
	return(ret)
