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
    l /= radius;
    vec4 u_x = texture(u, p);
    fragColor = u_x.r == 0. ? u_x : (u_x + ((l > 2.) ? 0. : exp(- (l * l) / 2.) / 10.) * 2.);
}