#version 300 es
precision highp float;
uniform sampler2D u;
uniform sampler2D normals;
uniform sampler2D groundTexture;
uniform sampler2D caustics1;
uniform sampler2D caustics2;
uniform sampler2D caustics3;
uniform sampler2D caustics4;
in vec2 p;
out vec4 fragColor;

// Light ray direction
const vec3 L = vec3(0.09901475,  0.09901475, -0.99014754);

// Refractive indices
const float nAir = 1.000277;

// Fluid properties
uniform float fluidRefractiveIndex;
uniform vec3 fluidColor;
uniform vec2 fluidClarity;

#define U(di, dj) texture(u, p + vec2(di, dj) * h).r

// Get the point on the ground which the ray hitting the fluid surface at the given pixel would hit after it has
// refracted.
vec2 getGroundIntersection(vec2 fluidIncidentPoint)
{
  vec2 p = fluidIncidentPoint;
  vec2 h = vec2(1.,1.) / vec2(textureSize(u, 0));
  ivec2 ij = ivec2(p * vec2(textureSize(u, 0)));

  // Surface normal
  vec3 N = texture(normals, p).rgb;

  // cos(incident angle)
  float cosTheta1 = dot(N, L);

  // Ratio of refractive indices
  float refRatio = nAir / fluidRefractiveIndex;

  // sin(refracted angle)
  float sinTheta2 = refRatio * sqrt(1. - cosTheta1 * cosTheta1);
  float cosTheta2 = sqrt(1. - sinTheta2 * sinTheta2);

  // Direction of refracted light
  vec3 Ltag = refRatio * L + (cosTheta1 * refRatio - cosTheta2) * N;

  // Multiplier of Ltag direction s.t. it reaches the bottom
  //float alpha = (u(0, 0) + u(0, -1) + u(0, 1) + u(-1, 0) + u(1, 0)) / (Ltag.z * 5.);
  float alpha = U(0, 0) / Ltag.z;

  return p + alpha * Ltag.xy;
}

void main()
{
  vec2 h = vec2(1.,1.) / vec2(textureSize(u, 0));
  vec2 groundPoint = getGroundIntersection(p);
  float illumination = 0.;
  illumination += texture(caustics1, p + vec2(0, -6) * h).r;
  illumination += texture(caustics1, p + vec2(0, -5) * h).g;
  illumination += texture(caustics1, p + vec2(0, -4) * h).b;
  illumination += texture(caustics1, p + vec2(0, -3) * h).a;
  illumination += texture(caustics2, p + vec2(0, -2) * h).r;
  illumination += texture(caustics2, p + vec2(0, -1) * h).g;
  illumination += texture(caustics2, p).b;
  illumination += texture(caustics2, p + vec2(0, 1) * h).a;
  illumination += texture(caustics3, p + vec2(0, 2) * h).r;
  illumination += texture(caustics3, p + vec2(0, 3) * h).g;
  illumination += texture(caustics3, p + vec2(0, 4) * h).b;
  illumination += texture(caustics3, p + vec2(0, 5) * h).a;
  illumination += texture(caustics4, p + vec2(0, 6) * h).r;
  illumination = max(illumination - .8, 0.);
  vec3 groundColor = texture(groundTexture, groundPoint).rgb;
  float height = (U(0, 0));// + u(0, -1) + u(0, 1) + u(-1, 0) + u(1, 0)) / 5.;
  float depth = max(0., min((height - fluidClarity.x) / (fluidClarity.y - fluidClarity.x), 1.));
  fragColor = vec4(((1. - depth) * groundColor + depth * fluidColor) + illumination * fluidColor, 1.);

  if (U(0, 0) == 0.) {
      fragColor = vec4(0., 0., 0., 1.);
  }
}