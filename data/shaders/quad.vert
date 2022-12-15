#version 300 es
in vec2 position;
in vec2 texCoord;
uniform bool u_flip;
uniform mat4 transform;
uniform int u_size;
out vec2 p;

void main()
{
    gl_Position = transform * vec4(u_flip ? vec2(position.x, float(u_size)-position.y) : position, 0, 1);
    p = texCoord;
}