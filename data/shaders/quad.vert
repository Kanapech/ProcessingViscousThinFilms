#version 300 es
in vec2 position;
in vec2 texCoord;
uniform bool u_flip;
uniform mat4 transform;
out vec2 p;

void main()
{
    gl_Position = transform * vec4(u_flip ? vec2(position.x, -position.y) : position, 0, 1);
    p = texCoord;
}