#version 300 es
in vec2 position;
in vec2 texCoord;
uniform bool u_flip;
out vec2 p;

void main()
{
    gl_Position = vec4(u_flip ?  position : vec2(position.x, -position.y), 0, 1);
    p = texCoord;
}