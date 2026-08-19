#version 330

in vec3 fragPosition;
in vec2 fragTexCoord;
in vec3 fragNormal;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform vec3 lightDir;
uniform vec4 lightColor;
uniform vec4 ambient;

uniform mat4 lightVP;
uniform sampler2D shadowMap;
uniform int shadowMapResolution;

out vec4 finalColor;

float compare_shadow_depth(ivec2 texel, float receiverDepth)
{
    float closestDepth = texelFetch(shadowMap, texel, 0).r;
    return receiverDepth <= closestDepth ? 1.0 : 0.0;
}

float shadow_visibility(vec3 normal, vec3 directionToLight)
{
    vec4 lightSpacePosition = lightVP*vec4(fragPosition, 1.0);
    vec3 projected = lightSpacePosition.xyz/lightSpacePosition.w;
    projected = projected*0.5 + 0.5;

    // Geometry outside the light camera does not have useful shadow-map data.
    if (projected.z > 1.0 || projected.z < 0.0 ||
        projected.x < 0.0 || projected.x > 1.0 ||
        projected.y < 0.0 || projected.y > 1.0)
    {
        return 1.0;
    }

    float bias = max(0.0002*(1.0 - dot(normal, directionToLight)), 0.00002) + 0.00001;
    float receiverDepth = projected.z - bias;

    // Compare a deliberately broad box around the receiver. Unlike bilinear
    // interpolation or a center-weighted tent, this increases the actual
    // penumbra width instead of only smoothing transitions between texels.
    vec2 texelPosition = projected.xy*float(shadowMapResolution) - vec2(0.5);
    ivec2 baseTexel = ivec2(floor(texelPosition));
    ivec2 maxTexel = ivec2(shadowMapResolution - 1);

    const int filterRadius = 2;
    float visibility = 0.0;
    float sampleCount = 0.0;
    for (int y = -filterRadius; y <= filterRadius; y++)
    {
        for (int x = -filterRadius; x <= filterRadius; x++)
        {
            ivec2 texel = clamp(baseTexel + ivec2(x, y), ivec2(0), maxTexel);
            visibility += compare_shadow_depth(texel, receiverDepth);
            sampleCount += 1.0;
        }
    }

    return visibility/sampleCount;
}

void main()
{
    vec4 baseColor = texture(texture0, fragTexCoord)*fragColor*colDiffuse;
    vec3 normal = normalize(fragNormal);
    vec3 directionToLight = -lightDir;
    float diffuse = max(dot(normal, directionToLight), 0.0);
    float visibility = shadow_visibility(normal, directionToLight);
    visibility = mix(1.0, visibility, 0.4);

    vec3 lighting = ambient.rgb + lightColor.rgb*diffuse*visibility;
    finalColor = vec4(baseColor.rgb*lighting, baseColor.a);
}
