//Definition des shaders //<>//
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
ArrayList<PShader> dewetSpray;

//Definition des programmes (equivalent OpenGL)
PGraphics currentProgram;
PGraphics canvas;
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
boolean dewetMode; //Appliquer du liquide/faire des trous
float s = 1;

int w = 256;
int h = 256;
int simRes = 256;
int simWidth;
int simHeight;

PImage empty;

float angle = 0;
float steepness = 1;
float G = 30;
float diffusion = 2;
int mobility = 0;

int iterations = 1;
boolean dynamicTimeStep = false;
float estimatedFrameTime = 0.02;
float[] logTimeStep = {-5, -1};
float tau = dynamicTimeStep ? min(10 * (estimatedFrameTime / iterations), pow(10, logTimeStep[1])) : pow(10, logTimeStep[1]);
boolean periodic = false;

void settings() {
  size(w, h, P2D);
}

void setup() {
  mode = "gradient";
  dewetMode = false;

  back = new Background("brick", "bricks.diffuse.jpg", "bricks.bump.jpg", 2); //Chargement du fond
  fluid = new Fluid("wine", 1.33, color(.4, 0., .05), 0., 1., 5);

  simWidth = simRes;
  simHeight = simRes * (height/width);

  //u0 = loadImage("emptiest.png");
  u0 = loadImage("siggraph.png");
  //u0 = loadImage("doodle520.png");
  viridis = loadImage("viridis.png");
  empty = loadImage("empty.png"); //Image en cas de composante diffuse ou bump nulle


  //Differents programmes
  canvas = createGraphics(simWidth, simHeight, P2D);
  thinFilms = createGraphics(simWidth, simHeight, P2D);
  normal = createGraphics(simWidth, simHeight, P2D);
  blur = createGraphics(simWidth, simHeight, P2D);
  pass = createGraphics(simWidth, simHeight, P2D);
  heightMap = createGraphics(simWidth, simHeight, P2D);
  gradient = createGraphics(simWidth, simHeight, P2D);
  spray = createGraphics(simWidth, simHeight, P2D);
  dewet = createGraphics(simWidth, simHeight, P2D);
  refract = createGraphics(simWidth, simHeight, P2D);
  caustics = createGraphics(simWidth, simHeight, P2D);
  black = createGraphics(simWidth, simHeight, P2D);

  work1 = createImage(simWidth, simHeight, RGB);
  work2 = createImage(simWidth, simHeight, RGB);
  fluidTex = createImage(simWidth, simHeight, RGB);
  caustics1 = createImage(simWidth, simHeight, RGB);
  caustics2 = createImage(simWidth, simHeight, RGB);
  caustics3 = createImage(simWidth, simHeight, RGB);
  caustics4 = createImage(simWidth, simHeight, RGB);
  normals = createImage(simWidth, simHeight, RGB);
  normalsWork = createImage(simWidth, simHeight, RGB);

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

  dewetSpray = new ArrayList<PShader>() {
    {
      add(quadDewet);
      add(quadSpray);
    }
  };

  //On lie chaque shader à son programme
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


void draw() {
  clear();
  if (frameCount == 1) {
    currentProgram = pass;
    quadPass.set("u", u0);
    quadPass.set("u_flip", false);
    drawQuad(currentProgram);
    work1 = get();
    work1.resize(width, height);
    //work1.save("work1.png");
  }

  currentProgram = thinFilms;
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
    work2 = get();
    work2.resize(width, height);

    quadThin.set("parity", 1);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = get();
    work1.resize(width, height);

    quadThin.set("parity", 2);
    quadThin.set("u", work1);
    drawQuad(currentProgram);
    work2 = get();
    work2.resize(width, height);

    quadThin.set("parity", 3);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = get();
    work1.resize(width, height);

    quadThin.set("Dij", 0, 1);
    quadThin.set("parity", 0);
    quadThin.set("u", work1);
    drawQuad(currentProgram);
    work2 = get();
    work2.resize(width, height);

    quadThin.set("parity", 1);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = get();
    work1.resize(width, height);

    quadThin.set("parity", 2);
    quadThin.set("u", work1);
    drawQuad(currentProgram);
    work2 = get();
    work2.resize(width, height);

    quadThin.set("parity", 3);
    quadThin.set("u", work2);
    drawQuad(currentProgram);
    work1 = get();
    work1.resize(width, height);
  }
  println(frameRate);
  if (mousePressed) {
    //println("test");
    currentProgram = dewetMode ? dewet : spray;
    for (PShader s : dewetSpray) {
      s.set("v_click", (float) mouseX, (float) mouseY);
      s.set("radius", 0.5);
      s.set("heightToWidthRatio", height/ (float) width);
      s.set("u", work1);
    }
    drawQuad(currentProgram);
    work2 = get();
    work2.resize(width, height);

    currentProgram = pass;
    quadPass.set("u", work2);
    drawQuad(currentProgram);
    work1 = get();
    work1.resize(width, height);
  }

  currentProgram = pass;
  quadPass.set("u", work1);
  drawQuad(currentProgram);
  fluidTex = get();
  fluidTex.resize(width, height);

  currentProgram = blur;
  quadBlur.set("dir", 0., 1.);
  quadBlur.set("u", fluidTex);
  drawQuad(currentProgram);
  work2 = get();
  work2.resize(width, height);
  quadBlur.set("dir", 1., 0.);
  quadBlur.set("u", work2);
  drawQuad(currentProgram);
  fluidTex = get();
  fluidTex.resize(width, height);

  currentProgram = normal;
  quadNormal.set("u", fluidTex);
  drawQuad(currentProgram);
  normals = get();

  switch(mode) {
  case "refraction":
    currentProgram = refract;
    quadRefract.set("fluidRefractiveIndex", fluid.refractiveIndex);
    quadRefract.set("fluidColor", red(fluid.col), green(fluid.col), blue(fluid.col));
    quadRefract.set("fluidClarity", fluid.clearDepth, fluid.opaqueDepth);
    quadRefract.set("u", fluidTex);
    quadRefract.set("normals", normals);
    quadRefract.set("caustics1", caustics1);
    quadRefract.set("caustics2", caustics2);
    quadRefract.set("caustics3", caustics3);
    quadRefract.set("caustics4", caustics4);
    quadRefract.set("groundTexture", back.diffuse);
    drawQuad(currentProgram);
    break;
  case "gradient":
    currentProgram = gradient;
    quadGradient.set("gradient", viridis);
    quadGradient.set("u", fluidTex);
    //quadGradient.set("u_flip", true);
    drawQuad(currentProgram);
    break;
  case "normal":
    currentProgram = normal;
    quadNormal.set("u", normals);
    //quadNormal.set("u_flip", true);
    drawQuad(currentProgram);
    break;
  case "heightMap":
    currentProgram = heightMap;
    quadHeight.set("u", fluidTex);
    quadHeight.set("threshold", 2.);
    //quadHeight.set("u_flip", true);
    drawQuad(currentProgram);
    break;
  }

  int endTime = millis();
  estimatedFrameTime = (endTime-startTime) / 1000.;
  //println(estimatedFrameTime);
  //noLoop();
  image(currentProgram, 0, 0);
  if (keyPressed) {
    if (key == 'b' || key == 'B') {
      dewetMode = !dewetMode;
      println(dewetMode);
    }
  }
}

void drawQuad(PGraphics pg) {
  //println(pg);
  pg.beginDraw();
  pg.noStroke();
  pg.beginShape(TRIANGLES);
  pg.vertex(-s, -s, 0, 0);
  pg.vertex(s, s, 1, 1);
  pg.vertex(s, -s, 1, 0);
  pg.vertex(-s, -s, 0, 0);
  pg.vertex(-s, s, 0, 1);
  pg.vertex(s, s, 1, 1);
  pg.endShape();
  //pg.save(pg+"img.png");
  pg.endDraw();
  image(pg, 0, 0);
}
