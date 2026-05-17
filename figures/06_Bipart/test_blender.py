import bpy

# Efface tout
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Crée un parallélépipède en modifiant l'échelle d'un cube
bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0))
parallelepipede = bpy.context.active_object
parallelepipede.scale = (2, 1, 3)  # (x, y, z)

# Ajoute une lumière
bpy.ops.object.light_add(type='POINT', location=(5, -5, 5))
light = bpy.context.active_object
light.data.energy = 1000

# Place la caméra
cam_data = bpy.data.cameras.new(name="Camera")
cam_object = bpy.data.objects.new("Camera", cam_data)
bpy.context.collection.objects.link(cam_object)
cam_object.location = (8, -8, 6)
cam_object.rotation_euler = (1.1, 0, 0.9)  # en radians
bpy.context.scene.camera = cam_object

# Réglages caméra (perspective)
cam_data.lens = 35  # focal length
cam_data.type = 'PERSP'  # perspective

#blender --background --python test_blender.py

