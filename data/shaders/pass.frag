#version 300 es
precision highp float;
uniform sampler2D u;
in vec2 p;
out vec4 fragColor;

void main()
{
    fragColor = texture(u, p);
}