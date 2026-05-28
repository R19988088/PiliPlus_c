/*
 * Copyright 2025 Kyant
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Modified for PiliPlus:
 * - Ported from AndroidLiquidGlass AGSL RuntimeShader to Flutter GLSL.
 * - Adapted uniform layout for dart:ui ImageFilter.shader.
 */

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 u_size;
uniform sampler2D u_texture_input;
uniform vec4 u_corner_radii;
uniform float u_refraction_height;
uniform float u_refraction_amount;
uniform float u_depth_effect;
uniform float u_chromatic_aberration;

out vec4 frag_color;

float radiusAt(vec2 centeredCoord, vec4 radii) {
    if (centeredCoord.x >= 0.0) {
        if (centeredCoord.y <= 0.0) {
            return radii.y;
        }
        return radii.z;
    }
    if (centeredCoord.y <= 0.0) {
        return radii.x;
    }
    return radii.w;
}

float sdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
    vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
    float outside = length(max(cornerCoord, 0.0)) - radius;
    float inside = min(max(cornerCoord.x, cornerCoord.y), 0.0);
    return outside + inside;
}

vec2 safeNormalize(vec2 value) {
    float len = length(value);
    if (len <= 0.0001) {
        return vec2(0.0);
    }
    return value / len;
}

vec2 gradSdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
    vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
    if (cornerCoord.x >= 0.0 || cornerCoord.y >= 0.0) {
        return sign(coord) * safeNormalize(max(cornerCoord, 0.0));
    }

    float gradX = step(cornerCoord.y, cornerCoord.x);
    return sign(coord) * vec2(gradX, 1.0 - gradX);
}

float circleMap(float x) {
    float clamped = clamp(x, 0.0, 1.0);
    return 1.0 - sqrt(1.0 - clamped * clamped);
}

vec4 sampleContent(vec2 coord) {
    vec2 uv = coord / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
    uv.y = 1.0 - uv.y;
#endif
    return texture(u_texture_input, clamp(uv, vec2(0.0), vec2(1.0)));
}

void main() {
    vec2 coord = FlutterFragCoord().xy;
    vec2 halfSize = u_size * 0.5;
    vec2 centeredCoord = coord - halfSize;

    if (u_refraction_height <= 0.0 || u_refraction_amount <= 0.0) {
        frag_color = sampleContent(coord);
        return;
    }

    float radius = radiusAt(centeredCoord, u_corner_radii);
    float sd = sdRoundedRect(centeredCoord, halfSize, radius);
    if (-sd >= u_refraction_height) {
        frag_color = sampleContent(coord);
        return;
    }

    sd = min(sd, 0.0);
    float d = circleMap(1.0 - -sd / u_refraction_height) * -u_refraction_amount;
    float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
    vec2 edgeGrad = gradSdRoundedRect(centeredCoord, halfSize, gradRadius);
    vec2 depthGrad = safeNormalize(centeredCoord);
    vec2 grad = safeNormalize(edgeGrad + u_depth_effect * depthGrad);
    vec2 refractedCoord = coord + d * grad;

    if (u_chromatic_aberration <= 0.0) {
        frag_color = sampleContent(refractedCoord);
        return;
    }

    float denominator = max(halfSize.x * halfSize.y, 1.0);
    float dispersionIntensity =
        u_chromatic_aberration * ((centeredCoord.x * centeredCoord.y) / denominator);
    vec2 dispersedCoord = d * grad * dispersionIntensity;

    vec4 color = vec4(0.0);

    vec4 red = sampleContent(refractedCoord + dispersedCoord);
    color.r += red.r / 3.5;
    color.a += red.a / 7.0;

    vec4 orange = sampleContent(refractedCoord + dispersedCoord * (2.0 / 3.0));
    color.r += orange.r / 3.5;
    color.g += orange.g / 7.0;
    color.a += orange.a / 7.0;

    vec4 yellow = sampleContent(refractedCoord + dispersedCoord * (1.0 / 3.0));
    color.r += yellow.r / 3.5;
    color.g += yellow.g / 3.5;
    color.a += yellow.a / 7.0;

    vec4 green = sampleContent(refractedCoord);
    color.g += green.g / 3.5;
    color.a += green.a / 7.0;

    vec4 cyan = sampleContent(refractedCoord - dispersedCoord * (1.0 / 3.0));
    color.g += cyan.g / 3.5;
    color.b += cyan.b / 3.0;
    color.a += cyan.a / 7.0;

    vec4 blue = sampleContent(refractedCoord - dispersedCoord * (2.0 / 3.0));
    color.b += blue.b / 3.0;
    color.a += blue.a / 7.0;

    vec4 purple = sampleContent(refractedCoord - dispersedCoord);
    color.r += purple.r / 7.0;
    color.b += purple.b / 3.0;
    color.a += purple.a / 7.0;

    frag_color = color;
}
