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

int w = 512;
int h = 512;
int simRes = 256;
int simWidth;
int simHeight;

PImage empty;

float angle = 0;
float steepness = 1;
float G = 10.;
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
  mode = "refraction";
  dewetMode = false;
  frameRate(144);
  back = new Background("brick", "bricks.diffuse.jpg", "bricks.bump.jpg", 4); //Chargement du fond
  fluid = new Fluid("wine", 1.33, color(.2, 0., .1), 0., 1., 5);

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
  
  work1.loadPixels();
  work2.loadPixels();
  fluidTex.loadPixels();
  normals.loadPixels();
  canvas.loadPixels();

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
}


void draw() {
  background(0);
  if (frameCount == 1) {
    currentProgram = pass;
    
    quadPass.set("u", u0);
    quadPass.set("u_flip", false);
    drawQuad(currentProgram, quadPass);
    arrayCopy(currentProgram.pixels, work1.pixels);
    work1.updatePixels();
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
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work2.pixels);
    work2.updatePixels();

    quadThin.set("parity", 1);
    quadThin.set("u", work2);
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work1.pixels);
    work1.updatePixels();

    quadThin.set("parity", 2);
    quadThin.set("u", work1);
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work2.pixels);
    work2.updatePixels();

    quadThin.set("parity", 3);
    quadThin.set("u", work2);
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work1.pixels);
    work1.updatePixels();

    quadThin.set("Dij", 0, 1);
    quadThin.set("parity", 0);
    quadThin.set("u", work1);
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work2.pixels);
    work2.updatePixels();

    quadThin.set("parity", 1);
    quadThin.set("u", work2);
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work1.pixels);
    work1.updatePixels();

    quadThin.set("parity", 2);
    quadThin.set("u", work1);
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work2.pixels);
    work2.updatePixels();

    quadThin.set("parity", 3);
    quadThin.set("u", work2);
    drawQuad(currentProgram, quadThin);
    arrayCopy(currentProgram.pixels, work1.pixels);
    work1.updatePixels();
  }
  
  if (mousePressed) {
    
    float mX = mouseX/ (float) width;
    float mY = mouseY/ (float) height;
    //println("test");
    currentProgram = dewetMode ? dewet : spray;
    for (PShader s : dewetSpray) {
      s.set("v_click", mX, mY);
      s.set("radius", 0.05);
      s.set("heightToWidthRatio", height/ (float) width);
      s.set("u", work1);
    }
    drawQuad(currentProgram, dewetMode ? quadDewet : quadSpray);
    arrayCopy(currentProgram.pixels, work2.pixels);
    work2.updatePixels();

    currentProgram = pass;
    quadPass.set("u", work2);
    drawQuad(currentProgram, quadPass);
    arrayCopy(currentProgram.pixels, work1.pixels);
    work1.updatePixels();
  }

  currentProgram = pass;
  quadPass.set("u", work1);
  drawQuad(currentProgram, quadPass);
  arrayCopy(currentProgram.pixels, fluidTex.pixels);
  fluidTex.updatePixels();

  currentProgram = blur;
  quadBlur.set("dir", 0., 1.);
  quadBlur.set("u", fluidTex);
  drawQuad(currentProgram, quadBlur);
  arrayCopy(currentProgram.pixels, work2.pixels);
  work2.updatePixels();
  quadBlur.set("dir", 1., 0.);
  quadBlur.set("u", work2);
  drawQuad(currentProgram, quadBlur);
  arrayCopy(currentProgram.pixels, fluidTex.pixels);
  fluidTex.updatePixels();

  currentProgram = normal;
  quadNormal.set("u", fluidTex);
  drawQuad(currentProgram, quadNormal);
  arrayCopy(currentProgram.pixels, normals.pixels);
  normals.updatePixels();
  
  switch(mode) {
  case "refraction":
    currentProgram = refract;
    quadRefract.set("fluidRefractiveIndex", fluid.refractiveIndex);
    quadRefract.set("fluidColor", red(fluid.col), green(fluid.col), blue(fluid.col));
    quadRefract.set("fluidClarity", fluid.clearDepth, fluid.opaqueDepth);
    quadRefract.set("u", fluidTex);
    //quadRefract.set("u_flip", true);
    quadRefract.set("normals", normals);
    quadRefract.set("caustics1", caustics1);
    quadRefract.set("caustics2", caustics2);
    quadRefract.set("caustics3", caustics3);
    quadRefract.set("caustics4", caustics4);
    quadRefract.set("groundTexture", back.diffuse);
    drawQuad(currentProgram, quadRefract);
    arrayCopy(currentProgram.pixels, canvas.pixels);
    canvas.updatePixels();
    break;
  case "gradient":
    currentProgram = gradient;
    quadGradient.set("gradient", viridis);
    quadGradient.set("u", fluidTex);
    //quadGradient.set("u_flip", true);
    drawQuad(currentProgram, quadGradient);
    arrayCopy(currentProgram.pixels, canvas.pixels);
    canvas.updatePixels();
    //canvas.save("canvas.png");
    break;
  case "normal":
    currentProgram = normal;
    quadNormal.set("u", normals);
    //quadNormal.set("u_flip", true);
    drawQuad(currentProgram, quadNormal);
    arrayCopy(currentProgram.pixels, canvas.pixels);
    canvas.updatePixels();
    break;
  case "heightMap":
    currentProgram = heightMap;
    quadHeight.set("u", fluidTex);
    quadHeight.set("threshold", 2.);
    //quadHeight.set("u_flip", true);
    drawQuad(currentProgram, quadHeight);
    arrayCopy(currentProgram.pixels, canvas.pixels);
    canvas.updatePixels();
    break;
  }

  int endTime = millis();
  estimatedFrameTime = (endTime-startTime) / 1000.;
  
  if (keyPressed) {
    if (key == 'b' || key == 'B') {
      dewetMode = !dewetMode;
      println(dewetMode);
    }
  }
  
  image(canvas, 0, 0, width, height);
  //noLoop();
  println(frameRate);
}

void drawQuad(PGraphics pg, PShader s) {
  //println(pg);
  pg.beginDraw();
  pg.noStroke();
  pg.shader(s);
  pg.beginShape(TRIANGLES);
  pg.vertex(0, 0, 0, 0);
  pg.vertex(pg.width, pg.width, 1, 1);
  pg.vertex(pg.width, 0, 1, 0);
  pg.vertex(0, 0, 0, 0);
  pg.vertex(0, pg.width, 0, 1);
  pg.vertex(pg.width, pg.width, 1, 1);
  pg.endShape();
  //pg.save(pg+"img.png");
  pg.loadPixels();
  pg.endDraw();
  //image(pg, 0, 0);
}
