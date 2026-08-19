#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

// Width of the softened boundary measured in output (window) pixels. Source
// pixel centers remain flat, so this still reads as deliberate pixel art.
const float SOFT_EDGE_PIXELS = 1.25;

void main()
{
    vec2 textureSizePixels = vec2(textureSize(texture0, 0));
    vec2 sourcePosition = fragTexCoord*textureSizePixels - 0.5;
    vec2 sourcePixel = floor(sourcePosition);
    vec2 positionWithinPixel = fract(sourcePosition);

    // fwidth converts a requested output-pixel transition into source-pixel
    // units, keeping the softness visually stable at different window sizes.
    vec2 sourcePixelsPerOutputPixel = fwidth(sourcePosition);
    vec2 halfTransition = min(
        sourcePixelsPerOutputPixel*(SOFT_EDGE_PIXELS*0.5),
        vec2(0.5)
    );
    vec2 blend = smoothstep(
        vec2(0.5) - halfTransition,
        vec2(0.5) + halfTransition,
        positionWithinPixel
    );

    vec2 sampleCoordinate = (sourcePixel + vec2(0.5) + blend)/textureSizePixels;
    finalColor = texture(texture0, sampleCoordinate)*fragColor*colDiffuse;
}
