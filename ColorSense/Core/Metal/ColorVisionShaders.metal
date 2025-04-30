#include <metal_stdlib>
using namespace metal;

// Adjustable simulation intensity (0 = none, 1 = full simulation)
constant float severity = 0.6;

// Machado et al. 2009 color blindness simulation matrices (100% severity)

constant float3x3 testingRGB = float3x3(
                                        0.605511,     0.528560,     0.134071,
                                        0.155318,     0.812366,     0.032316,
                                        0.009376,     0.023176,     0.986200
                                        );

// Deuteranopia
constant float3x3 deuteranopiaRGB = float3x3(
                                             0.625,   0.7,     0.0,
                                             0.375,   0.3,     0.3,
                                             0.0,     0.0,     0.7
                                             );

// Protanopia
constant float3x3 protanopiaRGB = float3x3(
                                           0.56667, 0.55833, 0.0,
                                           0.43333, 0.44167, 0.24167,
                                           0.0,     0.0,     0.75833
                                           );

// Tritanopia
constant float3x3 tritanopiaRGB = float3x3(
                                           0.95,    0.0,     0.0,
                                           0.05,    0.43333, 0.475,
                                           0.0,     0.56667, 0.525
                                           );

// Remove sRGB gamma (linearize)
float3 removeGamma(float3 color) {
    float3 result;
    for (int i = 0; i < 3; i++) {
        result[i] = (color[i] <= 0.04045) ? color[i] / 12.92 : pow((color[i] + 0.055) / 1.055, 2.4);
    }
    return result;
}

// Re-apply sRGB gamma
float3 addGamma(float3 color) {
    float3 result;
    for (int i = 0; i < 3; i++) {
        result[i] = (color[i] <= 0.0031308) ? 12.92 * color[i] : 1.055 * pow(color[i], 1.0 / 2.4) - 0.055;
    }
    return result;
}

// Apply simulation matrix and blend with original
// Memory-safe version with additional bounds checking and validation
float3 simulateColorBlindness(float3 rgb, float3x3 simMatrix, float severity) {
    // Ensure input values are valid
    float3 validRGB = clamp(rgb, 0.0, 1.0);

    // Apply simulation matrix
    float3 simColor = simMatrix * validRGB;

    // Ensure simulated color is valid
    simColor = clamp(simColor, 0.0, 1.0);

    // Clamp severity to valid range [0,1]
    float validSeverity = clamp(severity, 0.0, 1.0);

    // Mix original and simulated colors
    return mix(validRGB, simColor, validSeverity);
}

// Test Value filter with bounds checking
kernel void applyTestingFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                texture2d<float, access::write> outTexture [[texture(1)]],
                                uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking to prevent out-of-bounds memory access
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel safely
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = removeGamma(color.rgb);
    float3 simulated = simulateColorBlindness(linear, testingRGB, severity);
    float3 corrected = clamp(addGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

// Deuteranopia filter with bounds checking
kernel void applyDeuteranopiaFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking to prevent out-of-bounds memory access
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel safely
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = removeGamma(color.rgb);
    float3 simulated = simulateColorBlindness(linear, deuteranopiaRGB, severity);
    float3 corrected = clamp(addGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

// Protanopia filter with bounds checking
kernel void applyProtanopiaFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking to prevent out-of-bounds memory access
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel safely
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = removeGamma(color.rgb);
    float3 simulated = simulateColorBlindness(linear, protanopiaRGB, severity);
    float3 corrected = clamp(addGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

// Tritanopia filter with bounds checking
kernel void applyTritanopiaFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking to prevent out-of-bounds memory access
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel safely
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = removeGamma(color.rgb);
    float3 simulated = simulateColorBlindness(linear, tritanopiaRGB, severity);
    float3 corrected = clamp(addGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}
