#version 100

precision mediump float;

uniform float progress;
uniform float opacity;

void main()
{
    vec3 hotColor = vec3(1.0, 0.957, 0.639);
    vec3 flameColor = vec3(1.0, 0.478, 0.094);
    vec3 emberColor = vec3(0.725, 0.114, 0.035);
    vec3 color = mix(mix(hotColor, flameColor, 0.55), emberColor, progress);

    gl_FragColor = vec4(color, opacity);
}
