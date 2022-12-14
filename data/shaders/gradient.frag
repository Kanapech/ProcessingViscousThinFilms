#version 300 es
precision highp float;
uniform sampler2D u;
uniform sampler2D gradient;
in vec2 p;
out vec4 fragColor;

void main()
{
    fragColor = texture(gradient, vec2(texture(u, p).r, 0.));
}