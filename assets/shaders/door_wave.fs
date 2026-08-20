#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float time;

out vec4 finalColor;

void main()
{
    vec4 baseColor = texture(texture0, fragTexCoord)*fragColor*colDiffuse;

    // The panel UV runs from 0 at the top to 1 at the bottom. Subtracting time
    // from the phase makes the wave travel upward at a deliberately slow pace.
    float height = 1.0 - fragTexCoord.y;
    float wave = sin(height*12.0 - time*0.8)*0.5 + 0.5;
    vec3 animatedColor = baseColor.rgb*(0.78 + wave*0.22) + vec3(wave*0.10);

    finalColor = vec4(animatedColor, baseColor.a);
}
