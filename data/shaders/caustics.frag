#version 300 es
#define N 13
#define N_HALF 6

precision highp float;
uniform sampler2D u;
uniform sampler2D normals;
in vec2 p;
layout(location=0) out vec4 out1;
layout(location=1) out vec4 out2;
layout(location=2) out vec4 out3;
layout(location=3) out vec4 out4;

// Light ray direction
uniform vec3 L;
//const vec3 L = normalize(vec3(.03, 0.1, -1));

const float hRest = .1;

// Refractive indices
const float nAir = 1.000277;
const float nWater = 1.330;

#define u(di,dj) texture(u,p+vec2(di,dj)*h).r

vec3 getRefractedLightDirection(vec3 n, vec3 L)
{
  // cos(incident angle)
  float cosTheta1 = dot(n, normalize(L));

  // Ratio of refractive indices
  float refRatio = nAir / nWater;

  // sin(refracted angle)
  float sinTheta2 = refRatio * sqrt(1. - cosTheta1 * cosTheta1);
  float cosTheta2 = sqrt(1. - sinTheta2 * sinTheta2);

  // Direction of refracted light
  return refRatio * L + (cosTheta1 * refRatio - cosTheta2) * n;
}

// Get the point on the ground which the ray hitting the water surface at the given pixel would hit after it has
// refracted.
vec2 getGroundIntersection(vec2 waterIncidentPoint)
{
  vec2 h = vec2(1.,1.) / vec2(textureSize(u, 0));

  // Surface normal
  vec3 n = texture(normals, waterIncidentPoint).rgb;

  vec3 Ltag = getRefractedLightDirection(vec3(0., 0., 1.), L);

  // Multiplier of Ltag direction s.t. it reaches the bottom
  float alpha = u(0, 0) / Ltag.z;

  return waterIncidentPoint + alpha * Ltag.xy;
}

void main()
{
    vec2 h = vec2(1.,1.) / vec2(textureSize(u, 0));
    ivec2 ij = ivec2(p * vec2(textureSize(u, 0)));
    // initialize output intensities
    float intensity[N];
    for ( int i=0; i<N; i++ ) intensity[i] = 0.;

    vec2 P_G = p;
    vec3 Ltag = getRefractedLightDirection(vec3(0., 0., 1.), L);
    float alpha = hRest / Ltag.z;
    vec2 P_C = P_G - alpha * Ltag.xy;

    // initialize caustic-receiving pixel positions
    float P_Gy[N];
    for ( int i=-N_HALF; i<=N_HALF; i++ ) P_Gy[i + N_HALF] = P_G.y + float(i) * h.y;
    // for each sample on the height field
    for ( int i=0; i<N; i++ ) {
        // find the intersection with the ground plane
        vec2 pN = P_C + float(i - N_HALF) * vec2(h.x, 0);
        vec2 intersection = getGroundIntersection(pN);
        // ax is the overlapping distance along x-direction
        float ax = max(0., h.x - abs(P_G.x - intersection.x)) / h.x;
        // for each caustic-receiving pixel position
        for ( int j=0; j<N; j++ ) {
            // ay is the overlapping distance along y-direction
            float ay = max(0., h.y - abs(P_Gy[j] - intersection.y)) / h.y;
            // increase the intensity by the overlapping area
            intensity[j] += ax*ay;
        }
    }
    // copy the output intensities to the color channels
    out1 = vec4( intensity[0], intensity[1], intensity[2], intensity[3] );
    out2 = vec4( intensity[4], intensity[5], intensity[6], intensity[7] );
    out3 = vec4( intensity[8], intensity[9], intensity[10], intensity[11] );
    out4 = vec4( intensity[12], 0., 0., 0. );
}