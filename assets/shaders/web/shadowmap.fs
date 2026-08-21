#version 100

precision highp float;
precision mediump int;

varying vec3 fragPosition;
varying vec2 fragTexCoord;
varying vec3 fragNormal;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform vec3 lightDir;
uniform vec4 lightColor;
uniform vec4 ambient;

uniform mat4 lightVP;
uniform sampler2D shadowMap;
uniform int shadowMapResolution;

float shadow_visibility(vec3 normal, vec3 directionToLight)
{
    vec4 lightSpacePosition = lightVP*vec4(fragPosition, 1.0);
    vec3 projected = lightSpacePosition.xyz/lightSpacePosition.w;
    projected = projected*0.5 + 0.5;

    if (projected.z > 1.0 || projected.z < 0.0 ||
        projected.x < 0.0 || projected.x > 1.0 ||
        projected.y < 0.0 || projected.y > 1.0)
    {
        return 1.0;
    }

    float bias = max(0.0002*(1.0 - dot(normal, directionToLight)), 0.00002) + 0.00001;
    float receiverDepth = projected.z - bias;
    float resolution = float(shadowMapResolution);

    // GLSL ES 1.00 has no texelFetch. Snap to the same texel center and
    // sample neighboring centers with normalized texture coordinates instead.
    vec2 baseTexel = floor(projected.xy*resolution - vec2(0.5));
    vec2 maxTexel = vec2(resolution - 1.0);
    float visibility = 0.0;
    float sampleCount = 0.0;
    const int filterRadius = 2;
    for (int y = -filterRadius; y <= filterRadius; y++)
    {
        for (int x = -filterRadius; x <= filterRadius; x++)
        {
            vec2 texel = clamp(baseTexel + vec2(float(x), float(y)), vec2(0.0), maxTexel);
            float closestDepth = texture2D(shadowMap, (texel + vec2(0.5))/resolution).r;
            visibility += receiverDepth <= closestDepth ? 1.0 : 0.0;
            sampleCount += 1.0;
        }
    }

    return visibility/sampleCount;
}

void main()
{
    vec4 baseColor = texture2D(texture0, fragTexCoord)*fragColor*colDiffuse;
    vec3 normal = normalize(fragNormal);
    vec3 directionToLight = -lightDir;
    float diffuse = max(dot(normal, directionToLight), 0.0);
    float visibility = shadow_visibility(normal, directionToLight);
    visibility = mix(1.0, visibility, 0.4);

    vec3 lighting = ambient.rgb + lightColor.rgb*diffuse*visibility;
    gl_FragColor = vec4(baseColor.rgb*lighting, baseColor.a);
}
