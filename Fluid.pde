class Fluid{
  String title;
  float refractiveIndex;
  color col;
  float clearDepth;
  float opaqueDepth;
  float viscosity;
  
  Fluid(String t, float ref, color c, float clearD, float opaqueD, float visc){
    title = t;
    refractiveIndex = ref;
    col = c;
    clearDepth = clearD;
    opaqueDepth = opaqueD;
    viscosity = visc;
  }
  
}
