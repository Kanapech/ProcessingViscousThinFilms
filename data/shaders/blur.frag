#version 300 es
precision highp float;

//"in" attributes from our vertex shader
uniform sampler2D u;
in vec2 p;
out vec4 fragColor;

//declare uniforms
uniform vec2 dir;

void main() {
    vec2 imsize = vec2(textureSize(u, 0));
	//this will be our RGBA sum
	vec4 sum = vec4(0.0);

	//the amount to blur, i.e. how far off center to sample from
	//1.0 -> blur by one pixel
	//2.0 -> blur by two pixels, etc.
	float blur = .5;

	//the direction of our blur
	//(1.0, 0.0) -> x-axis blur
	//(0.0, 1.0) -> y-axis blur
	vec2 step = dir / imsize;

	//apply blurring, using a 9-tap filter with predefined gaussian weights

	sum += texture(u, p - 4. * blur * step) * 0.0162162162;
	sum += texture(u, p - 3. * blur * step) * 0.0540540541;
	sum += texture(u, p - 2. * blur * step) * 0.1216216216;
	sum += texture(u, p - 1. * blur * step) * 0.1945945946;

	sum += texture(u, p) * 0.2270270270;

	sum += texture(u, p + 1. * blur * step) * 0.1945945946;
	sum += texture(u, p + 2. * blur * step) * 0.1216216216;
	sum += texture(u, p + 3. * blur * step) * 0.0540540541;
	sum += texture(u, p + 4. * blur * step) * 0.0162162162;

	//discard alpha for our simple demo, multiply by vertex color and return
	fragColor = vec4(sum.rgb, 1.0);
}