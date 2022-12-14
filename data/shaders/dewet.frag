#version 300 es
#define M_PI 3.1415926535897932384626433832795
precision highp float;
uniform sampler2D u;
uniform vec2 v_click;
uniform float radius;
uniform float heightToWidthRatio;
in vec2 p;
out vec4 fragColor;

void main()
{
    float l = length((p - v_click) * vec2(1., heightToWidthRatio));
    fragColor = l < radius ? vec4(0, 0, 0, 1) : texture(u, p);
}