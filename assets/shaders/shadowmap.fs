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
    vec2 texelSize = vec2(1.0/float(shadowMapResolution));
    float occludedSamples = 0.0;

    for (int x = -1; x <= 1; x++)
    {
        for (int y = -1; y <= 1; y++)
        {
            float closestDepth = texture(shadowMap, projected.xy + vec2(x, y)*texelSize).r;
            occludedSamples += projected.z - bias > closestDepth ? 1.0 : 0.0;
        }
    }

    return 1.0 - occludedSamples/9.0;
}

void main()
{
    vec4 baseColor = texture(texture0, fragTexCoord)*fragColor*colDiffuse;
    vec3 normal = normalize(fragNormal);
    vec3 directionToLight = -lightDir;
    float diffuse = max(dot(normal, directionToLight), 0.0);
    float visibility = shadow_visibility(normal, directionToLight);

    vec3 lighting = ambient.rgb + lightColor.rgb*diffuse*visibility;
    finalColor = vec4(baseColor.rgb*lighting, baseColor.a);
}
