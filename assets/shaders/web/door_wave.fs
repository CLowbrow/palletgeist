#version 100

precision mediump float;

varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float time;

void main()
{
    vec4 baseColor = texture2D(texture0, fragTexCoord)*fragColor*colDiffuse;
    float height = 1.0 - fragTexCoord.y;
    float wave = sin(height*12.0 - time*0.8)*0.5 + 0.5;
    vec3 animatedColor = baseColor.rgb*(0.78 + wave*0.22) + vec3(wave*0.10);

    gl_FragColor = vec4(animatedColor, baseColor.a);
}
