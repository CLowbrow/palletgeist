#version 100

precision highp float;

varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform vec2 sourceSize;
uniform vec2 outputSize;

const float SOFT_EDGE_PIXELS = 1.25;

void main()
{
    vec2 sourcePosition = fragTexCoord*sourceSize - 0.5;
    vec2 sourcePixel = floor(sourcePosition);
    vec2 positionWithinPixel = fract(sourcePosition);

    // The fullscreen mapping is linear, so this ratio is the GLSL ES 1.00
    // equivalent of fwidth(sourcePosition) without requiring derivatives.
    vec2 sourcePixelsPerOutputPixel = sourceSize/outputSize;
    vec2 halfTransition = min(
        sourcePixelsPerOutputPixel*(SOFT_EDGE_PIXELS*0.5),
        vec2(0.5)
    );
    vec2 blend = smoothstep(
        vec2(0.5) - halfTransition,
        vec2(0.5) + halfTransition,
        positionWithinPixel
    );

    vec2 sampleCoordinate = (sourcePixel + vec2(0.5) + blend)/sourceSize;
    gl_FragColor = texture2D(texture0, sampleCoordinate)*fragColor*colDiffuse;
}
