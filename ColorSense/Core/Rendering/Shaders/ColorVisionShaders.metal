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
 */

#include <metal_stdlib>
using namespace metal;

// MARK: Adjustable simulation intensity (0 = none, 1 = full simulation)
constant float severity = 1.0;

// MARK: Matrix constants based on ITU-R BT.709 primaries with D65 white point
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

// MARK: White point in XYZ
constant float4 white_xyz0 = float4(0.312713, 0.329016, 0.358271, 0.0);

// MARK: Confusion point and color axis parameters
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

// MARK: Convert sRGB to linear RGB color space by removing gamma correction
float3 linearizeRGB(float3 srgbColor) {
    float3 mask = step(0.04045, srgbColor);
    float3 linear = srgbColor / 12.92;
    float3 powered = pow((srgbColor + 0.055) / 1.055, 2.4);
    return mix(linear, powered, mask);
}

// MARK: Convert linear RGB back to sRGB color space by applying gamma correction
float3 applyGamma(float3 linearColor) {
    float3 result;
    for (int i = 0; i < 3; i++) {
        result[i] = (linearColor[i] <= 0.0031308) ? 12.92 * linearColor[i] : 1.055 * pow(linearColor[i], 1.0 / 2.4) - 0.055;
    }
    return result;
}

// Simulate CVD
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

// Pass-through kernel - just copy input to output
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

// Deuteranopia filter with bounds checking
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

// Protanopia filter with bounds checking
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

// Tritanopia filter with bounds checking
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

// Monochromacy filter
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

// Additional filters for -anomaly conditions and partial monochromacy

// Deuteranomaly filter
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

// Protanomaly filter
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

// Tritanomaly filter
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

// Partial monochromacy filter
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

// MARK: Enahncement Kernal Functions

// RGB to LMS conversion matrix
constant float3x3 rgb_to_lms_matrix = float3x3(
                                               float3(17.8824, 43.5161, 4.11935),
                                               float3(3.45565, 27.1554, 3.86714),
                                               float3(0.0299566, 0.184309, 1.46709)
                                               );

// LMS to RGB conversion matrix
constant float3x3 lms_to_rgb_matrix = float3x3(
                                               float3(0.0809, -0.1305, 0.1167),
                                               float3(-0.0102, 0.0540, -0.1136),
                                               float3(-0.0003, -0.0041, 0.6935)
                                               );

// Daltonization Kernel for Deuteranopia
kernel void enhanceDeuteranopia(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel and set up our intensity controls
    float4 color = inTexture.read(gid);
    float3 rgb = color.rgb;
    float3 enhanced = rgb;

    // Customizable strengths
    float greenBoost = 0.6;     // Higher = more blue added to greens
    float redEnhance = 0.15;    // Higher = more red enhancement
    float blueReduce = 0.15;    // Higher = more blue reduction in reds

    // Calculate how "green-heavy" the pixel is - with better formula
    float greenness = rgb.g - ((rgb.r + rgb.b) * 0.5);

    // Green enhancement - now with more sauce!
    if (greenness > 0.05) {
        // For green-dominant pixels, boost blue more aggressively
        enhanced.b = min(1.0, rgb.b + greenness * greenBoost);

        // Also slightly reduce red to create even more contrast
        enhanced.r = max(0.0, rgb.r - greenness * 0.2);
    }
    // Red enhancement
    else if (rgb.r > rgb.g + 0.05) {
        // More aggressive red boost
        enhanced.r = min(1.0, rgb.r * (1.0 + redEnhance));

        // Stronger blue reduction for reds
        enhanced.b = max(0.0, rgb.b - blueReduce);

        // NEW: Also slightly reduce green for even more distinction
        enhanced.g = max(0.0, rgb.g - 0.05);
    }

    // NEW: Handle yellow and orange (tricky colors for deuteranopes)
    else if (rgb.r > 0.4 && rgb.g > 0.4 && rgb.b < 0.3) {
        // This is likely yellow or orange - make it more distinct
        enhanced.r *= 1.1;  // Boost red
        enhanced.b += 0.1;  // Add a touch of blue
    }

    // Write output pixel
    outTexture.write(float4(enhanced, color.a), gid);
}

// Daltonization Kernel for Protanopia
kernel void enhanceProtanopia(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);
    float3 rgb = color.rgb;
    float3 enhanced = rgb;

    // Customizable strengths
    float redBoost = 0.7;     // Higher = more boost for problematic reds
    float contrastDim = 0.15; // Higher = more dimming for contrast

    // Calculate "redness" - essential for protans who struggle with red
    float redness = rgb.r - ((rgb.g + rgb.b) * 0.5);

    // Red deficiency is the key issue for protanopia
    if (redness > 0.05) {
        // For red-dominant pixels, boost blue to create distinction
        enhanced.b = min(1.0, rgb.b + redness * 0.4);

        // Also boost the red slightly to prevent it from appearing too dark
        enhanced.r = min(1.0, rgb.r * 1.1);
    }
    // Green enhancement
    else if (rgb.g > rgb.r + 0.05) {
        // Make greens more distinctive by boosting their intensity
        enhanced.g = min(1.0, rgb.g * 1.15);

        // Reduce red slightly for better contrast
        enhanced.r = max(0.0, rgb.r - contrastDim);
    }

    // Handle problematic brown/yellow colors
    else if (rgb.r > 0.4 && rgb.g > 0.3 && rgb.b < 0.3) {
        // This is likely brown or yellow - difficult for protanopes
        enhanced.b += 0.15;  // Add blue component to make it distinctive
        enhanced.r = min(1.0, rgb.r * (1.0 + redBoost * 0.3));  // Boost red
    }

    // Write output pixel
    outTexture.write(float4(enhanced, color.a), gid);
}

// Daltonization Kernel for Tritanopia
kernel void enhanceTritanopia(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    // Bounds checking
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Read input pixel
    float4 color = inTexture.read(gid);
    float3 rgb = color.rgb;
    float3 enhanced = rgb;

    // Customizable strengths
    float blueBoost = 0.6;    // Higher = more enhancement for blues
    float yellowAdjust = 0.5; // Higher = more enhancement for yellows

    // Calculate "blueness" - critical measure for tritanopes
    float blueness = rgb.b - ((rgb.r + rgb.g) * 0.5);

    // Calculate "yellowness" - another problem area
    float yellowness = (rgb.r + rgb.g) * 0.5 - rgb.b;

    // Blue adjustment - blues can look greenish to tritanopes
    if (blueness > 0.05) {
        // For blue-dominant pixels, boost red to create distinction from greens
        enhanced.r = min(1.0, rgb.r + blueness * blueBoost);

        // Reduce green slightly to further separate from blue
        enhanced.g = max(0.0, rgb.g - blueness * 0.2);
    }
    // Yellow adjustment - yellows can look pink to tritanopes
    else if (yellowness > 0.05) {
        // For yellow colors, boost both red and green but reduce blue
        enhanced.r = min(1.0, rgb.r * 1.1);
        enhanced.g = min(1.0, rgb.g * 1.1);
        enhanced.b = max(0.0, rgb.b - yellowness * yellowAdjust * 0.3);
    }

    // Special handling for purple/violet shades
    else if (rgb.r > 0.2 && rgb.b > 0.2 && rgb.g < 0.2) {
        // Enhance purple colors by boosting both red and blue
        enhanced.r = min(1.0, rgb.r * 1.15);
        enhanced.b = min(1.0, rgb.b * 1.15);
    }

    // Write output pixel
    outTexture.write(float4(enhanced, color.a), gid);
}
