#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

const int PALETTE_SIZE = 102;
const vec3 PALETTE[PALETTE_SIZE] = vec3[PALETTE_SIZE](
    vec3( 46.0,  34.0,  47.0)/255.0,
    vec3( 62.0,  53.0,  70.0)/255.0,
    vec3( 98.0,  85.0, 101.0)/255.0,
    vec3(150.0, 108.0, 108.0)/255.0,
    vec3(171.0, 148.0, 122.0)/255.0,
    vec3(105.0,  79.0,  98.0)/255.0,
    vec3(127.0, 112.0, 138.0)/255.0,
    vec3(155.0, 171.0, 178.0)/255.0,
    vec3(199.0, 220.0, 208.0)/255.0,
    vec3(255.0, 255.0, 255.0)/255.0,
    vec3(110.0,  39.0,  39.0)/255.0,
    vec3(179.0,  56.0,  49.0)/255.0,
    vec3(234.0,  79.0,  54.0)/255.0,
    vec3(245.0, 125.0,  74.0)/255.0,
    vec3(174.0,  35.0,  52.0)/255.0,
    vec3(232.0,  59.0,  59.0)/255.0,
    vec3(251.0, 107.0,  29.0)/255.0,
    vec3(247.0, 150.0,  23.0)/255.0,
    vec3(249.0, 194.0,  43.0)/255.0,
    vec3(122.0,  48.0,  69.0)/255.0,
    vec3(158.0,  69.0,  57.0)/255.0,
    vec3(205.0, 104.0,  61.0)/255.0,
    vec3(230.0, 144.0,  78.0)/255.0,
    vec3(251.0, 185.0,  84.0)/255.0,
    vec3( 76.0,  62.0,  36.0)/255.0,
    vec3(103.0, 102.0,  51.0)/255.0,
    vec3(162.0, 169.0,  71.0)/255.0,
    vec3(213.0, 224.0,  75.0)/255.0,
    vec3(251.0, 255.0, 134.0)/255.0,
    vec3( 22.0,  90.0,  76.0)/255.0,
    vec3( 35.0, 144.0,  99.0)/255.0,
    vec3( 30.0, 188.0, 115.0)/255.0,
    vec3(145.0, 219.0, 105.0)/255.0,
    vec3(205.0, 223.0, 108.0)/255.0,
    vec3( 49.0,  54.0,  56.0)/255.0,
    vec3( 55.0,  78.0,  74.0)/255.0,
    vec3( 84.0, 126.0, 100.0)/255.0,
    vec3(146.0, 169.0, 132.0)/255.0,
    vec3(178.0, 186.0, 144.0)/255.0,
    vec3( 11.0,  94.0, 101.0)/255.0,
    vec3( 11.0, 138.0, 143.0)/255.0,
    vec3( 14.0, 175.0, 155.0)/255.0,
    vec3( 48.0, 225.0, 185.0)/255.0,
    vec3(143.0, 248.0, 226.0)/255.0,
    vec3( 50.0,  51.0,  83.0)/255.0,
    vec3( 72.0,  74.0, 119.0)/255.0,
    vec3( 77.0, 101.0, 180.0)/255.0,
    vec3( 77.0, 155.0, 230.0)/255.0,
    vec3(143.0, 211.0, 255.0)/255.0,
    vec3( 69.0,  41.0,  63.0)/255.0,
    vec3(107.0,  62.0, 117.0)/255.0,
    vec3(144.0,  94.0, 169.0)/255.0,
    vec3(168.0, 132.0, 243.0)/255.0,
    vec3(234.0, 173.0, 237.0)/255.0,
    vec3(117.0,  60.0,  84.0)/255.0,
    vec3(162.0,  75.0, 111.0)/255.0,
    vec3(207.0, 101.0, 127.0)/255.0,
    vec3(237.0, 128.0, 153.0)/255.0,
    vec3(131.0,  28.0,  93.0)/255.0,
    vec3(195.0,  36.0,  84.0)/255.0,
    vec3(240.0,  79.0, 120.0)/255.0,
    vec3(246.0, 129.0, 129.0)/255.0,
    vec3(252.0, 167.0, 144.0)/255.0,
    vec3(253.0, 203.0, 176.0)/255.0,

    // A denser, less teal green ramp for the ghost's lit and shadowed folds.
    vec3( 18.0,  53.0,  31.0)/255.0,
    vec3( 24.0,  75.0,  39.0)/255.0,
    vec3( 32.0,  99.0,  49.0)/255.0,
    vec3( 41.0, 125.0,  59.0)/255.0,
    vec3( 53.0, 152.0,  70.0)/255.0,
    vec3( 71.0, 182.0,  83.0)/255.0,
    vec3(100.0, 212.0,  91.0)/255.0,
    vec3(130.0, 233.0, 106.0)/255.0,
    vec3(176.0, 245.0, 138.0)/255.0,

    // Level greys follow static_level_renderer exactly: its top color is
    // 200 - 10*elevation. Continuing the same spacing in both directions
    // gives the lighting pass nearby shadow and highlight choices as well.
    vec3( 40.0,  40.0,  40.0)/255.0,
    vec3( 50.0,  50.0,  50.0)/255.0,
    vec3( 60.0,  60.0,  60.0)/255.0,
    vec3( 70.0,  70.0,  70.0)/255.0,
    vec3( 80.0,  80.0,  80.0)/255.0,
    vec3( 90.0,  90.0,  90.0)/255.0,
    vec3(100.0, 100.0, 100.0)/255.0,
    vec3(110.0, 110.0, 110.0)/255.0,
    vec3(120.0, 120.0, 120.0)/255.0,
    vec3(130.0, 130.0, 130.0)/255.0,
    vec3(140.0, 140.0, 140.0)/255.0,
    vec3(150.0, 150.0, 150.0)/255.0,
    vec3(160.0, 160.0, 160.0)/255.0,
    vec3(170.0, 170.0, 170.0)/255.0,
    vec3(180.0, 180.0, 180.0)/255.0,
    vec3(190.0, 190.0, 190.0)/255.0,
    vec3(200.0, 200.0, 200.0)/255.0,
    vec3(210.0, 210.0, 210.0)/255.0,
    vec3(220.0, 220.0, 220.0)/255.0,
    vec3(230.0, 230.0, 230.0)/255.0,
    vec3(240.0, 240.0, 240.0)/255.0,

    // Extra crate reds bridge its deep sides, midtones, and hot top faces.
    vec3( 85.0,  36.0,  42.0)/255.0,
    vec3(127.0,  43.0,  42.0)/255.0,
    vec3(144.0,  48.0,  44.0)/255.0,
    vec3(161.0,  52.0,  47.0)/255.0,
    vec3(193.0,  62.0,  50.0)/255.0,
    vec3(207.0,  68.0,  52.0)/255.0,
    vec3(220.0,  73.0,  53.0)/255.0,
    vec3(242.0,  98.0,  61.0)/255.0
);

// Redmean is a compact perceptual distance approximation that behaves better
// than plain RGB distance while keeping this palette lookup inexpensive.
float colorDistance(vec3 source, vec3 candidate)
{
    vec3 difference = source - candidate;
    float redMean = (source.r + candidate.r)*0.5;
    return (2.0 + redMean)*difference.r*difference.r
         + 4.0*difference.g*difference.g
         + (3.0 - redMean)*difference.b*difference.b;
}

void main()
{
    vec4 sampled = texture(texture0, fragTexCoord)*fragColor*colDiffuse;
    vec3 nearest = PALETTE[0];
    float nearestDistance = colorDistance(sampled.rgb, nearest);

    for (int i = 1; i < PALETTE_SIZE; i++)
    {
        float candidateDistance = colorDistance(sampled.rgb, PALETTE[i]);
        if (candidateDistance < nearestDistance)
        {
            nearest = PALETTE[i];
            nearestDistance = candidateDistance;
        }
    }

    finalColor = vec4(nearest, sampled.a);
}
