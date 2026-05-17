from PIL import Image
import os

# Chemin du GIF
gif_path = "image192.gif"
output_folder = "frames"

# Crée le dossier de sortie s'il n'existe pas
os.makedirs(output_folder, exist_ok=True)

# Ouvre le GIF
gif = Image.open(gif_path)

frame_number = 0
try:
    while True:
        gif.seek(frame_number)
        frame = gif.convert("RGBA")  # ou "RGB" selon le besoin
        frame.save(f"{output_folder}/frame_{frame_number:03d}.png")
        frame_number += 1
except EOFError:
    print(f"Extraction terminée : {frame_number} frames sauvegardées dans '{output_folder}'")

