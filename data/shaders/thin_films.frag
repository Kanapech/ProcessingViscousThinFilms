#version 300 es
precision highp float;
uniform sampler2D u;
uniform sampler2D bump;
uniform int parity;
uniform ivec2 Dij; // direction of edge (1, 0) -> vertical, (0, 1) -> horizontal
uniform float angle;
uniform float tilt; // [0, 1] tilt strength
uniform float eta; // diffusion
uniform float tau;
uniform float epsilon; // viscosity/thickness
uniform float bumpDepth;
uniform int mobility;
uniform float G;
uniform bool periodic;
in vec2 p;
out vec4 fragColor;
#define wrk(tex, x) texture(tex, x).r
#define u(ij) wrk(u, ij)
#define M(u1,u2) (mobility == 0 ? (1./(1./abs(u1*u1*u1)+1./abs(u2*u2*u2))) : 2.*u1*u1*u2*u2/(3.*(u1+u2)))
#define W(__x__) ((1. - wrk(bump, __x__)) * bumpDepth + ((__x__.x / h.x) * dirX + (__x__.y / h.y) * dirY))

void main()
{
    ivec2 imsize = textureSize(u, 0);
    vec2 h = vec2(1.,1.) / vec2(imsize);
    ivec2 pij = ivec2(p * vec2(imsize));
    int par = ((Dij.y + 1) * pij.x + (Dij.x + 1) * pij.y + parity) % 4;
    vec2 hq = vec2(h * vec2(Dij) * float(1 - 2 * (par % 2)));
    vec2 q = p + hq;
    int activeFlag = par / 2;
    vec2 hperp = h * vec2(Dij.y, Dij.x); // diff perp. to edge
    float Dp = u(p - hq) + u(p + hperp) + u(p - hperp);
    float Dq = u(q + hq) + u(q + hperp) + u(q - hperp);
    float up = u(p);
    float uq = u(q);
    float Mpq = M(uq, up);
    float theta = 1. + 2. * tau * Mpq * (5. * epsilon + eta);
    float dirX = sin(angle);
    float dirY = cos(angle);
    float f = -(Mpq / theta) * ((W(q) - W(p)) * -G * tilt  - epsilon * (Dq - Dp) + (5. * epsilon + eta) * (uq - up));
    float du = float(activeFlag) * tau * f;
    up -= max(-uq, min(du, up));
    if (!periodic && (pij.x < 2 || pij.x > imsize.x - 2 || pij.y < 2 || pij.y > imsize.y - 2)) {
        // Neumann b.c. - zero out edge pixels, mobility will prevent flow to them.
        up = 0.;
    }
    fragColor = vec4(up, up, up, 1.);
}