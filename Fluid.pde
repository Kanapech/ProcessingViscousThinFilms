class Fluid{
  String title;
  float refractiveIndex;
  float red;
  float blue;
  float green;
  float clearDepth;
  float opaqueDepth;
  float viscosity;
  
  Fluid(String t, float ref, float r, float g, float b, float clearD, float opaqueD, float visc){
    title = t;
    refractiveIndex = ref;
    red = r;
    green = g;
    blue = b;
    clearDepth = clearD;
    opaqueDepth = opaqueD;
    viscosity = visc;
  }
  
}
