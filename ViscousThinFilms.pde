//Definition des shaders
PShader quadThin;
PShader quadNormal;
PShader quadBlur;
PShader quadPass;
PShader quadHeight;
PShader quadGradient;
PShader quadSpray;
PShader quadDewet;
PShader quadRefract;
PShader quadCaustics;
PShader quadBlack;
ArrayList<PShader> shaders;

//Definition des programmes (equivalent OpenGL)
PGraphics currentProgram;
PGraphics thinFilms;
PGraphics normal;
PGraphics blur;
PGraphics pass;
PGraphics heightMap;
PGraphics gradient;
PGraphics spray;
PGraphics dewet;
PGraphics refract;
PGraphics caustics;
PGraphics black;

Background back;
Fluid fluid;
PImage u0; //Conditions initiales;
PImage viridis;
PImage work1;
PImage work2;
PImage fluidTex;
PImage caustics1;
PImage caustics2;
PImage caustics3;
PImage caustics4;
PImage normals;
PImage normalsWork;

PImage[] causticTextures = {caustics1, caustics2, caustics3, caustics4};

String mode; //Mode d'affichage
int s = 1;
int simRes;
int simWidth;
int simHeight;

PImage empty;

int parity = 0;
float angle = 0;
float steepness = 1;
float G = -9.81;
float diffusion = 2;
int mobility = 0;

int iterations = 1;
boolean dynamicTimeStep = false;
float estimatedFrameTime = 0.02;
float[] logTimeStep = {-5, -1};
float tau = dynamicTimeStep ? min(10 * (estimatedFrameTime / iterations), pow(10, logTimeStep[1])) : pow(10, logTimeStep[1]);
boolean periodic = false;

public void setup() {
  size(800, 800, P2D);
  mode = "gradient";

  //Differents programmes
  thinFilms = createGraphics(width, height, P2D);
  normal = createGraphics(width, height, P2D);
  blur = createGraphics(width, height, P2D);
  pass = createGraphics(width, height, P2D);
  heightMap = createGraphics(width, height, P2D);
  gradient = createGraphics(width, height, P2D);
  spray = createGraphics(width, height, P2D);
  dewet = createGraphics(width, height, P2D);
  refract = createGraphics(width, height, P2D);
  caustics = createGraphics(width, height, P2D);
  black = createGraphics(width, height, P2D);

  u0 = loadImage("emptiest.png");
  viridis = loadImage("viridis.png");
  empty = loadImage("empty.png"); //Image en cas de composante diffuse ou bump nulle

  work1 = createImage(simWidth, simHeight, ARGB);
  work2 = createImage(simWidth, simHeight, ARGB);
  fluidTex = createImage(simWidth, simHeight, ARGB);
  caustics1 = createImage(width, height, ARGB);
  caustics2 = createImage(width, height, ARGB);
  caustics3 = createImage(width, height, ARGB);
  caustics4 = createImage(width, height, ARGB);
  normals = createImage(width, height, ARGB);
  normalsWork = createImage(width, height, ARGB);

  back = new Background("brick", "bricks.diffuse.jpg", "bricks.bump.jpg", 2); //Chargement du fond
  fluid = new Fluid("wine", 1.33, color(.4, 0., .05), 0., 1., 5);
  simRes = 512;
  simWidth = simRes;
  simHeight = simRes * (height/width);

  //Chargement des différents shaders
  quadThin = loadShader("shaders/thin_films.frag", "shaders/quad.vert");
  quadNormal = loadShader("shaders/normal.frag", "shaders/quad.vert");
  quadBlur = loadShader("shaders/blur.frag", "shaders/quad.vert");
  quadPass = loadShader("shaders/pass.frag", "shaders/quad.vert");
  quadHeight= loadShader("shaders/heightmap.frag", "shaders/quad.vert");
  quadGradient = loadShader("shaders/gradient.frag", "shaders/quad.vert");
  quadSpray = loadShader("shaders/spray.frag", "shaders/quad.vert");
  quadDewet = loadShader("shaders/dewet.frag", "shaders/quad.vert");
  quadRefract = loadShader("shaders/refraction.frag", "shaders/quad.vert");
  quadCaustics = loadShader("shaders/caustics.frag", "shaders/quad.vert");
  quadBlack = loadShader("shaders/black.frag", "shaders/quad.vert");

  shaders = new ArrayList<>() {
    {
      add(quadThin);
      add(quadNormal);
      add(quadBlur);
      add(quadPass);
      add(quadHeight);
      add(quadGradient);
      add(quadSpray);
      add(quadDewet);
      add(quadRefract);
      add(quadCaustics);
      add(quadBlack);
    }
  };

  thinFilms.shader(quadThin);
  normal.shader(quadNormal);
  blur.shader(quadBlur);
  pass.shader(quadPass);
  heightMap.shader(quadHeight);
  gradient.shader(quadGradient);
  spray.shader(quadSpray);
  dewet.shader(quadDewet);
  refract.shader(quadRefract);
  caustics.shader(quadCaustics);
  black.shader(quadBlack);
}


public void draw() {
  //background(0);

  if (frameCount == 1) {
    currentProgram = pass;
    quadPass.set("u", u0);
    drawQuad(currentProgram);
    work1 = currentProgram.get();
    save("test.png");
  }

  currentProgram = thinFilms;
  quadThin.set("u", u0);
  quadThin.set("u_flip", false);
  quadThin.set("bump", back.bump != null ? back.bump : empty);
  quadThin.set("angle", angle);
  quadThin.set("tilt", steepness);
  quadThin.set("eta", diffusion);
  quadThin.set("tau", tau);
  quadThin.set("epsilon", fluid.viscosity);
  quadThin.set("bumpDepth", back.bumpDepth);
  quadThin.set("mobility", mobility);
  quadThin.set("G", G);
  quadThin.set("periodic", periodic);

  int startTime = millis();
  for (int i=0; i < iterations; i++) {

    quadThin.set("Dij", 1, 0);
    quadThin.set("parity", 0);
    quadThin.set("u", work1);
    drawQuad(currentProgram);
    work2 = currentProgram.get();
    save(i+"thin.png");

    quadThin.set("parity", 1);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = currentProgram.get();

    quadThin.set("parity", 2);
    quadThin.set("u", work1);
    drawQuad(currentProgram);
    work2 = currentProgram.get();

    quadThin.set("parity", 3);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = currentProgram.get();

    quadThin.set("Dij", 0, 1);
    quadThin.set("parity", 0);
    quadThin.set("u", work1);
    drawQuad(currentProgram);
    work2 = currentProgram.get();


    quadThin.set("parity", 1);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = currentProgram.get();

    quadThin.set("parity", 2);
    quadThin.set("u", work1);
    drawQuad(currentProgram);
    work2 = currentProgram.get();

    quadThin.set("parity", 3);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = currentProgram.get();
  }

  if (mousePressed) {
  }

  currentProgram = pass;
  quadPass.set("u", work1);
  drawQuad(currentProgram);
  fluidTex = currentProgram.get();

  currentProgram = blur;
  quadBlur.set("dir", 0., 1.);
  quadBlur.set("u", fluidTex);
  drawQuad(currentProgram);
  work2 = currentProgram.get();
  quadBlur.set("dir", 1., 0.);
  quadBlur.set("u", work2);
  drawQuad(currentProgram);
  fluidTex = currentProgram.get();

  currentProgram = normal;
  quadNormal.set("u", fluidTex);
  drawQuad(currentProgram);
  normals = currentProgram.get();

  switch(mode) {
  case "gradient":
    currentProgram = gradient;
    quadGradient.set("gradient", viridis);
    quadGradient.set("u", fluidTex);
    quadGradient.set("u_flip", true);
    drawQuad();
    break;
  case "normal":
    currentProgram = normal;
    quadNormal.set("u", normals);
    drawQuad();
    break;
  case "heightMap":
    currentProgram = heightMap;
    quadHeight.set("u", fluidTex);
    drawQuad();
    break;
  }
  
  int endTime = millis();
  estimatedFrameTime = (endTime-startTime) / 1000.;
  println(estimatedFrameTime);
}

void drawQuad(PGraphics pg) {
  pg.beginDraw();
  pg.beginShape(TRIANGLES);
  pg.vertex(-s, -s, 0, 0);
  pg.vertex(s, s, s, s);
  pg.vertex(s, -s, s, 0);
  pg.vertex(-s, -s, 0, 0);
  pg.vertex(-s, s, 0, s);
  pg.vertex(s, s, s, s);
  pg.endShape();
  pg.endDraw();
  image(pg, 0, 0);
}

void drawQuad() {
  beginShape(TRIANGLES);
  vertex(-s, -s, 0, 0);
  vertex(s, s, s, s);
  vertex(s, -s, s, 0);
  vertex(-s, -s, 0, 0);
  vertex(-s, s, 0, s);
  vertex(s, s, s, s);
  endShape();
}
