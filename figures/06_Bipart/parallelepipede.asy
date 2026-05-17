import three;
settings.render=0; // pour un rendu plus rapide
size(8cm);

// Taille du parallélépipède
real dx = 4;
real dy = 2;
real dz = 3;

// Couleurs des faces
pen frontFace = rgb(1, 0.6, 0.6);
pen backFace  = rgb(0.8, 0.8, 0.8);
pen topFace   = rgb(0.6, 0.9, 0.6);
pen bottomFace= rgb(0.6, 0.6, 1);
pen leftFace  = rgb(0.9, 0.9, 0.4);
pen rightFace = rgb(0.8, 0.5, 0.9);

// Sommets
triple O = (0,0,0);
triple A = (dx,0,0);
triple B = (dx,dy,0);
triple C = (0,dy,0);
triple D = (0,0,dz);
triple E = (dx,0,dz);
triple F = (dx,dy,dz);
triple G = (0,dy,dz);

// Fonction d'affichage du parallélépipède
void drawBox() {
  draw(surface(O--A--B--C--cycle), backFace);
  draw(surface(D--E--F--G--cycle), topFace);
  draw(surface(O--A--E--D--cycle), rightFace);
  draw(surface(B--C--G--F--cycle), leftFace);
  draw(surface(O--C--G--D--cycle), bottomFace);
  draw(surface(A--B--F--E--cycle), frontFace);

  pen edge = black+0.7bp;
  draw(O--A^^A--B^^B--C^^C--O, edge);
  draw(D--E^^E--F^^F--G^^G--D, edge);
  draw(O--D^^A--E^^B--F^^C--G, edge);
}

// Animation orbitale
int frames = 60;
for (int i = 0; i < frames; ++i) {
  real angle = 2pi * i / frames;
  real R = 10; // distance caméra
  triple cam = (R*cos(angle), R*sin(angle), 5);
  currentprojection = perspective(
    camera = cam,
    up = Z,
    target = (dx/2, dy/2, dz/2),
    angle = 45
  );

  drawBox();

  // Export chaque image
  string name = format("animation/frame_%03d", i);
  shipout(name);
  erase(); // nettoie la scène pour la frame suivante
}
