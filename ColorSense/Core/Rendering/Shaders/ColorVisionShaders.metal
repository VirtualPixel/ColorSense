/*
 * Color Vision Deficiency Simulation Shader - Metal implementation
 * Copyright (c) 2025 Justin Wells
 * https://github.com/VirtualPixel/ColorSense
 *
 * This implementation is a derivative work based on:
 * 1. The OpenGL implementation by Michel Fortin (Copyright 2005-2017)
 *    https://github.com/michelf/sim-daltonism/
 * 2. The color_blind_sim JavaScript function originally by Matthew Wickline
 *    and the Human-Computer Interaction Resource Network
 *
 * The implementation is based on the physiologically-based model from:
 * Machado et al. (2009) "A Physiologically-based Model for Simulation of Color Vision Deficiency"
 * IEEE Transactions on Visualization and Computer Graphics
 *
 * Licensed under the Apache License, Version 2.0 and
 * Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0)
 * http://www.apache.org/licenses/LICENSE-2.0
 * https://creativecommons.org/licenses/by-sa/4.0/
 *
 * ATTRIBUTION REQUIREMENTS:
 * If you create a derivative work based on this code, you must:
 * 1. Attribute all previous contributors as listed above
 * 2. Indicate that your work is a derivative
 * 3. Provide a link to your source code repository
 * 4. License your derivative under the same licenses (Apache 2.0 and CC BY-SA 4.0)
 * 5. Document significant changes made to this implementation
 *
 * Changes from the OpenGL implementation include:
 * - Adaptation for Metal Shading Language
 * - Additional error checking and guards against division by zero
 * - Implementation as separate kernel functions for each vision type
 * - Updated RGB/XYZ conversion matrices for higher accuracy using ITU-R BT.709 standard
 * - Improved gamma correction handling for sRGB color space
 * - Enhanced robustness with additional null checks and error prevention
 * - Added enhancement kernels for improved color distinction in CVD
 */

#include <metal_stdlib>
using namespace metal;

// MARK: - Constants

// Adjustable simulation intensity (0 = none, 1 = full simulation)
constant float severity = 1.0;

// Matrix constants based on ITU-R BT.709 primaries with D65 white point
constant float3x3 rgb_to_xyz_matrix = float3x3(
    float3(0.4124564, 0.3575761, 0.1804375),
    float3(0.2126729, 0.7151522, 0.0721750),
    float3(0.0193339, 0.1191920, 0.9503041)
);

constant float3x3 xyz_to_rgb_matrix = float3x3(
    float3( 3.2404542, -1.5371385, -0.4985314),
    float3(-0.9692660,  1.8760108,  0.0415560),
    float3( 0.0556434, -0.2040259,  1.0572252)
);

// White point in XYZ
constant float4 white_xyz0 = float4(0.312713, 0.329016, 0.358271, 0.0);

// Confusion point and color axis parameters
// Deuteranopia
constant float2 deutan_confusion_point = float2(1.14, -0.14);
constant float2 deutan_axis_start = float2(0.102776, 0.102864);
constant float2 deutan_axis_end = float2(0.505845, 0.493211);

// Protanopia
constant float2 protan_confusion_point = float2(0.735, 0.265);
constant float2 protan_axis_start = float2(0.115807, 0.073581);
constant float2 protan_axis_end = float2(0.471899, 0.527051);

// Tritanopia
constant float2 tritan_confusion_point = float2(0.171, -0.003);
constant float2 tritan_axis_start = float2(0.045391, 0.294976);
constant float2 tritan_axis_end = float2(0.665764, 0.334011);

// Standard grayscale conversion weights
constant float3 grayscale_weights = float3(0.299, 0.587, 0.114);

// MARK: - Color Space Conversion Functions

/**
 * Convert sRGB to linear RGB color space by removing gamma correction
 * @param srgbColor Color in sRGB space
 * @return Color in linear RGB space
 */
float3 linearizeRGB(float3 srgbColor) {
    float3 mask = step(0.04045, srgbColor);
    float3 linear = srgbColor / 12.92;
    float3 powered = pow((srgbColor + 0.055) / 1.055, 2.4);
    return mix(linear, powered, mask);
}

/**
 * Convert linear RGB back to sRGB color space by applying gamma correction
 * @param linearColor Color in linear RGB space
 * @return Color in sRGB space
 */
float3 applyGamma(float3 linearColor) {
    float3 result;
    for (int i = 0; i < 3; i++) {
        result[i] = (linearColor[i] <= 0.0031308) ? 12.92 * linearColor[i] : 1.055 * pow(linearColor[i], 1.0 / 2.4) - 0.055;
    }
    return result;
}

/**
 * Convert RGB to HSV color space
 * @param rgb Color in RGB space
 * @return Color in HSV space (H: 0-1, S: 0-1, V: 0-1)
 */
float3 rgb_to_hsv(float3 rgb) {
    float maxComponent = max(max(rgb.r, rgb.g), rgb.b);
    float minComponent = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxComponent - minComponent;

    float3 hsv;

    // Hue calculation
    if (delta == 0.0) {
        hsv.x = 0.0; // Undefined, set to 0
    } else if (maxComponent == rgb.r) {
        hsv.x = (rgb.g - rgb.b) / delta;
        if (hsv.x < 0.0) hsv.x += 6.0;
    } else if (maxComponent == rgb.g) {
        hsv.x = 2.0 + (rgb.b - rgb.r) / delta;
    } else {
        hsv.x = 4.0 + (rgb.r - rgb.g) / delta;
    }
    hsv.x /= 6.0; // Normalize to [0,1]

    // Saturation
    hsv.y = (maxComponent == 0.0) ? 0.0 : delta / maxComponent;

    // Value
    hsv.z = maxComponent;

    return hsv;
}

/**
 * Convert HSV to RGB color space
 * @param hsv Color in HSV space (H: 0-1, S: 0-1, V: 0-1)
 * @return Color in RGB space
 */
float3 hsv_to_rgb(float3 hsv) {
    float h = hsv.x * 6.0; // Scale hue to [0,6]
    float s = hsv.y;
    float v = hsv.z;

    if (s == 0.0) {
        return float3(v, v, v); // Grayscale
    }

    int sector = int(floor(h));
    float fractional = h - float(sector);

    float p = v * (1.0 - s);
    float q = v * (1.0 - s * fractional);
    float t = v * (1.0 - s * (1.0 - fractional));

    switch (sector) {
        case 0:  return float3(v, t, p);
        case 1:  return float3(q, v, p);
        case 2:  return float3(p, v, t);
        case 3:  return float3(p, q, v);
        case 4:  return float3(t, p, v);
        default: return float3(v, p, q);
    }
}

// MARK: - CVD Simulation Function

/**
 * Simulate color vision deficiency
 * @param rgb Input color in linear RGB space
 * @param confusionPoint Confusion point for the specific CVD type
 * @param axisBegin Start point of the color axis
 * @param axisEnd End point of the color axis
 * @param anomalyFactor Severity of the simulation (0-1)
 * @return Simulated color in linear RGB space
 */
float3 simulateCVD(float3 rgb, float2 confusionPoint, float2 axisBegin, float2 axisEnd, float anomalyFactor) {
    // Handle monochromacy using a direct approach
    if (anomalyFactor <= 0.0) {
        float m = dot(rgb, grayscale_weights);
        return mix(rgb, float3(m, m, m), -anomalyFactor);
    }

    // Convert from RGB to XYZ
    float3 colorXYZ = rgb * rgb_to_xyz_matrix;
    float sum_xyz = colorXYZ.x + colorXYZ.y + colorXYZ.z;

    // Guard against division by zero
    if (sum_xyz < 1e-6) {
        return rgb;
    }

    // Map into uvY space
    float2 colorUV = float2(colorXYZ.x / sum_xyz, colorXYZ.y / sum_xyz);

    // Find neutral grey at this luminosity
    float4 n_xyz0 = white_xyz0 * colorXYZ.y / white_xyz0.y;

    // Calculate confusion line slope and intercept
    float2 cp_uv_minus_c_uv = confusionPoint - colorUV;

    // Guard against division by zero
    if (abs(cp_uv_minus_c_uv.x) < 1e-6) {
        return rgb;
    }

    float confusionLineSlope = cp_uv_minus_c_uv.y / cp_uv_minus_c_uv.x;
    float clyi = colorUV.y - confusionLineSlope * colorUV.x;

    // Calculate color axis slope and intercept
    float2 ae_minus_ab = axisEnd - axisBegin;

    // Guard against division by zero
    if (abs(ae_minus_ab.x) < 1e-6) {
        return rgb;
    }

    float blindness_am = ae_minus_ab.y / ae_minus_ab.x;
    float blindness_ayi = axisBegin.y - axisBegin.x * blindness_am;

    // Guard against division by zero or very close slopes
    if (abs(confusionLineSlope - blindness_am) < 1e-6) {
        return rgb;
    }

    // Find change in u and v dimensions
    float2 d_uv;
    d_uv.x = (blindness_ayi - clyi) / (confusionLineSlope - blindness_am);
    d_uv.y = (confusionLineSlope * d_uv.x) + clyi;

    // Guard against invalid values
    if (d_uv.y < 1e-6) {
        return rgb;
    }

    // Find simulated color's XYZ coords
    float d_u_div_d_v = d_uv.x / d_uv.y;
    float4 s_xyz0 = colorXYZ.y * float4(
        d_u_div_d_v,
        1.0,
        (1.0 / d_uv.y - (d_u_div_d_v + 1.0)),
        0.0
    );

    // Calculate RGB coords
    float3 s_rgb = s_xyz0.xyz * xyz_to_rgb_matrix;

    // Calculate differences between sim color and neutral color
    float3 d_xyz = n_xyz0.xyz - s_xyz0.xyz;
    float3 d_rgb = d_xyz * xyz_to_rgb_matrix;

    // Shift sim color toward neutral to fit in RGB space
    float4 adj = float4(0.0);

    // Guard against division by zero
    for (int i = 0; i < 3; i++) {
        if (abs(d_rgb[i]) >= 1e-6) {
            adj[i] = (1.0 - s_rgb[i]) / d_rgb[i];
        }
    }

    // Apply adjustment
    adj = sign(1.0 - adj) * adj;
    float adjust = max(max(0.0, adj.r), max(adj.g, adj.b));

    // Shift proportionally to the greatest shift
    s_rgb = s_rgb + (adjust * d_rgb);

    // Clamp to valid RGB range
    s_rgb = clamp(s_rgb, 0.0, 1.0);

    // Apply anomalize factor (blend between original and simulated color)
    return mix(rgb, s_rgb, anomalyFactor);
}

// MARK: - Pass-through Kernel

/**
 * Pass-through kernel - just copy input to output
 * Used when CVD simulation is disabled
 */
kernel void passThroughFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Simply copy the input to the output
    float4 color = inTexture.read(gid);
    outTexture.write(color, gid);
}

// MARK: - CVD Simulation Kernels

/**
 * Deuteranopia simulation filter
 * Simulates red-green color blindness (absence of green cones)
 */
kernel void applyDeuteranopiaFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = linearizeRGB(color.rgb);

    // Apply simulation with severity
    float3 simulated = simulateCVD(
        linear, deutan_confusion_point, deutan_axis_start, deutan_axis_end, severity
    );

    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

/**
 * Protanopia simulation filter
 * Simulates red-green color blindness (absence of red cones)
 */
kernel void applyProtanopiaFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = linearizeRGB(color.rgb);

    // Apply simulation with full severity (1.0)
    float3 simulated = simulateCVD(
        linear, protan_confusion_point, protan_axis_start, protan_axis_end, severity
    );

    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

/**
 * Tritanopia simulation filter
 * Simulates blue-yellow color blindness (absence of blue cones)
 */
kernel void applyTritanopiaFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = linearizeRGB(color.rgb);

    // Apply simulation with full severity (1.0)
    float3 simulated = simulateCVD(
        linear, tritan_confusion_point, tritan_axis_start, tritan_axis_end, severity
    );

    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

/**
 * Monochromacy simulation filter
 * Simulates complete color blindness
 */
kernel void applyMonochromacyFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color for full grayscale
    float3 linear = linearizeRGB(color.rgb);
    float gray = dot(linear, grayscale_weights);
    float3 simulated = mix(linear, float3(gray, gray, gray), severity);
    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

// MARK: - Anomaly Simulation Kernels

/**
 * Deuteranomaly simulation filter
 * Simulates partial red-green color blindness (weakened green cones)
 */
kernel void applyDeuteranomalyFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                     texture2d<float, access::write> outTexture [[texture(1)]],
                                     uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color using
    float3 linear = linearizeRGB(color.rgb);

    // Apply simulation with severity based on Machado's model: α = (20 - Δλ)/20
    // For deuteranomaly: equivalent to ~13nm shift
    float3 simulated = simulateCVD(
        linear, deutan_confusion_point, deutan_axis_start, deutan_axis_end, severity * 0.35
    );

    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

/**
 * Protanomaly simulation filter
 * Simulates partial red-green color blindness (weakened red cones)
 */
kernel void applyProtanomalyFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                   texture2d<float, access::write> outTexture [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color
    float3 linear = linearizeRGB(color.rgb);

    // Apply simulation with severity based on Machado's model: α = (20 - Δλ)/20
    // For protanomaly: equivalent to ~13nm shift
    float3 simulated = simulateCVD(
        linear, protan_confusion_point, protan_axis_start, protan_axis_end, severity * 0.35
    );

    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

/**
 * Tritanomaly simulation filter
 * Simulates partial blue-yellow color blindness (weakened blue cones)
 */
kernel void applyTritanomalyFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                   texture2d<float, access::write> outTexture [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color using
    float3 linear = linearizeRGB(color.rgb);

    // Apply simulation with partial severity (0.35) for anomaly
    float3 simulated = simulateCVD(
        linear, tritan_confusion_point, tritan_axis_start, tritan_axis_end, severity * 0.35
    );

    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

/**
 * Partial monochromacy simulation filter
 * Simulates partial loss of color vision
 */
kernel void applyPartialMonochromacyFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);

    // Process color for partial grayscale (35% severity)
    float3 linear = linearizeRGB(color.rgb);
    float gray = dot(linear, grayscale_weights);
    float3 simulated = mix(linear, float3(gray, gray, gray), severity * 0.35);
    float3 corrected = clamp(applyGamma(simulated), 0.0, 1.0);

    // Write output pixel
    outTexture.write(float4(corrected, color.a), gid);
}

// MARK: - Enhancement Kernel Functions

/**
 * Quantize colors to basic distinct colors for maximum clarity
 * @param hsv Color in HSV space
 * @param cvdType Type of color vision deficiency (0=Deuteranopia, 1=Protanopia, 2=Tritanopia)
 * @return Quantized color in HSV space
 */
float3 quantizeToBasicColors(float3 hsv, float cvdType) {
    float hue = hsv.x * 360.0f;
    float sat = hsv.y;
    float val = hsv.z;

    // Skip near-grays to avoid artifacts
    if (sat < 0.1f) {
        return hsv;
    }

    float targetHue = hue;

    // Define clear color bands for each CVD type
    if (cvdType == 0.0f) { // Deuteranopia
        // Create distinct bands that avoid red-green confusion
        if (hue >= 0.0f && hue < 15.0f) {
            targetHue = 0.0f; // Pure red
        }
        else if (hue >= 15.0f && hue < 45.0f) {
            targetHue = 30.0f; // Pure orange (keep as distinct orange)
        }
        else if (hue >= 45.0f && hue < 90.0f) {
            targetHue = 60.0f; // Pure yellow (very distinct from green)
        }
        else if (hue >= 90.0f && hue < 150.0f) {
            targetHue = 120.0f; // Pure green
        }
        else if (hue >= 150.0f && hue < 210.0f) {
            targetHue = 180.0f; // Cyan (distinct from green)
        }
        else if (hue >= 210.0f && hue < 270.0f) {
            targetHue = 240.0f; // Blue
        }
        else if (hue >= 270.0f && hue < 315.0f) {
            targetHue = 285.0f; // Purple
        }
        else {
            targetHue = 330.0f; // Magenta
        }

        // Boost saturation for all colors
        sat = min(1.0f, sat * 1.5f);
    }
    else if (cvdType == 1.0f) { // Protanopia
        // Special handling for reds (appear dark) and greens
        if (hue >= 0.0f && hue < 20.0f || hue >= 340.0f) {
            targetHue = 0.0f; // Pure red
            val = min(1.0f, val * 1.4f); // Brighten reds significantly
        }
        else if (hue >= 20.0f && hue < 50.0f) {
            targetHue = 35.0f; // Keep orange distinct from yellow
        }
        else if (hue >= 50.0f && hue < 90.0f) {
            targetHue = 60.0f; // Yellow
        }
        else if (hue >= 90.0f && hue < 150.0f) {
            targetHue = 140.0f; // Blue-green (avoid pure green)
        }
        else if (hue >= 150.0f && hue < 210.0f) {
            targetHue = 180.0f; // Cyan
        }
        else if (hue >= 210.0f && hue < 270.0f) {
            targetHue = 240.0f; // Blue
        }
        else {
            targetHue = 300.0f; // Magenta
        }

        sat = min(1.0f, sat * 1.5f);
    }
    else if (cvdType == 2.0f) { // Tritanopia
        // Handle blue-yellow confusion
        if (hue >= 0.0f && hue < 30.0f) {
            targetHue = 0.0f; // Red
        }
        else if (hue >= 30.0f && hue < 90.0f) {
            targetHue = 45.0f; // Orange (instead of yellow which can appear pink)
        }
        else if (hue >= 90.0f && hue < 150.0f) {
            targetHue = 120.0f; // Green
        }
        else if (hue >= 150.0f && hue < 240.0f) {
            targetHue = 270.0f; // Purple (instead of blue which can appear green)
        }
        else if (hue >= 240.0f && hue < 300.0f) {
            targetHue = 285.0f; // Violet
        }
        else {
            targetHue = 330.0f; // Magenta
        }

        sat = min(1.0f, sat * 1.4f);
    }

    float3 result;
    result.x = targetHue / 360.0f;
    result.y = sat;
    result.z = val;

    return result;
}

// MARK: - Enhancement Kernels

/**
 * Deuteranopia enhancement kernel
 * Enhances color distinction for red-green color blindness (missing green cones)
 * Quantizes colors to distinct bands to avoid confusion
 */
kernel void enhanceDeuteranopia(texture2d<float, access::read> inTexture [[texture(0)]],
                                texture2d<float, access::write> outTexture [[texture(1)]],
                                uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);
    float3 rgb = color.rgb;

    // Convert to HSV for better color manipulation
    float3 hsv = rgb_to_hsv(rgb);

    // Apply aggressive quantization to create distinct color bands
    float3 quantizedHSV = quantizeToBasicColors(hsv, 0.0f);

    // Convert back to RGB
    float3 enhanced = hsv_to_rgb(quantizedHSV);

    // Apply enhancement based on saturation to avoid artifacts
    // Full strength above 20% saturation, smooth transition below
    float enhanceStrength = smoothstep(0.0f, 0.2f, hsv.y);
    enhanced = mix(rgb, enhanced, enhanceStrength);

    outTexture.write(float4(enhanced, color.a), gid);
}

/**
 * Protanopia enhancement kernel
 * Enhances color distinction for red-green color blindness (missing red cones)
 * Brightens reds and separates them from greens
 */
kernel void enhanceProtanopia(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);
    float3 rgb = color.rgb;

    // Convert to HSV
    float3 hsv = rgb_to_hsv(rgb);

    // Apply aggressive quantization with special handling for reds
    float3 quantizedHSV = quantizeToBasicColors(hsv, 1.0f);

    // Convert back to RGB
    float3 enhanced = hsv_to_rgb(quantizedHSV);

    // Very strong enhancement
    float enhanceStrength = smoothstep(0.0f, 0.2f, hsv.y);
    enhanced = mix(rgb, enhanced, enhanceStrength);

    outTexture.write(float4(enhanced, color.a), gid);
}

// Daltonization Kernel for Tritanopia
kernel void enhanceTritanopia(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);
    float3 rgb = color.rgb;

    // Convert to HSV
    float3 hsv = rgb_to_hsv(rgb);

    // Apply aggressive quantization
    float3 quantizedHSV = quantizeToBasicColors(hsv, 2.0f);

    // Convert back to RGB
    float3 enhanced = hsv_to_rgb(quantizedHSV);

    // Very strong enhancement
    float enhanceStrength = smoothstep(0.0f, 0.2f, hsv.y);
    enhanced = mix(rgb, enhanced, enhanceStrength);

    outTexture.write(float4(enhanced, color.a), gid);
}
