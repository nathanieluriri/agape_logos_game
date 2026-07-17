#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uIntensity;

out vec4 fragColor;

// Cheap 2D value noise + a few fbm octaves. Kept light (3 octaves) so a
// full-screen pass for the fog window does not jank the wheel drag.
float hash(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 3; i++) {
    v += amp * noise(p);
    p *= 2.0;
    amp *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  // Two drifting noise fields at different speeds/scales give a roiling,
  // volumetric feel rather than a flat tint.
  vec2 q = uv * 3.0;
  float drift = fbm(q + vec2(uTime * 0.06, uTime * 0.03));
  float roil = fbm(q * 1.7 - vec2(uTime * 0.04, uTime * 0.05));
  float density = clamp(drift * 0.7 + roil * 0.5, 0.0, 1.0);

  // Soft, slightly blue-white fog. Alpha rides the noise so it billows, and
  // uIntensity drives the whole fade in/out.
  vec3 fog = vec3(0.91, 0.95, 0.97);
  float alpha = (0.55 + 0.4 * density) * uIntensity;
  fragColor = vec4(fog * alpha, alpha);
}
