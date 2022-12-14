class Background{
  String title;
  PImage diffuse;
  PImage bump;
  float bumpDepth;
  
  Background(String t, String diff, String b, float bDepth){
    title = t;
    diffuse = diff != null ? loadImage(diff) : null;
    bump = b != null ? loadImage(b) : null;
    bumpDepth = bDepth;
  }
}
