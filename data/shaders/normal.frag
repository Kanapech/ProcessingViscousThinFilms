#version 300 es
precision highp float;
uniform sampler2D u;
in vec2 p;
out vec4 fragColor;

#define U(di, dj) texture(u, p + vec2(di, dj) * h).r

vec3 getNormal(vec2 p)
{
  vec2 h = vec2(1., 1.) / vec2(textureSize(u, 0));
  return vec3(U(-1, 0) - U(1, 0), U(0, -1) - U(0, 1), 1.);
}

void main()
{
  vec2 h = vec2(1.,1.) / vec2(textureSize(u, 0));
  fragColor = vec4(getNormal(p), 1);
}