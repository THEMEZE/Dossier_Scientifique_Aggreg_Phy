from manim import *

class ParallelepipedScene(ThreeDScene):
    def construct(self):
        self.set_camera_orientation(phi=60 * DEGREES, theta=-45 * DEGREES)
        cube = Cube(side_length=1)
        cube.stretch(2, 0)  # X
        cube.stretch(1.5, 1)  # Y
        cube.stretch(0.7, 2)  # Z
        cube.set_fill(RED, opacity=0.5)
        cube.set_stroke(WHITE, width=1)
        self.add(cube)
        self.wait()
#brew install cairo pango ffmpeg
#brew install pkg-config

#pip install manim
#manim -pql test_manim.py ParallelepipedScene

#python3 -m venv manim_env
#source manim_env/bin/activate
#pip install --upgrade pip
#pip install manim

