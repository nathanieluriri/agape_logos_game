#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uIntensity;
uniform float uStacks;

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

  // Domain warp: curl the sampling space so the sheets read as mist
  // tendrils rather than blobby noise.
  vec2 q = uv * 3.0;
  vec2 warp = vec2(
    fbm(q + vec2(uTime * 0.15, 0.0)),
    fbm(q + vec2(0.0, uTime * 0.12)));
  vec2 p = q + 1.4 * warp;

  // Three parallax sheets: different scales, speeds, and directions, so
  // gaps open and close between layers.
  float a = fbm(p + vec2(uTime * 0.20, uTime * 0.09));
  float b = fbm(p * 1.7 - vec2(uTime * 0.14, uTime * 0.17));
  float c = fbm(p * 0.6 + vec2(-uTime * 0.11, uTime * 0.05));
  float density = clamp(a * 0.55 + b * 0.45 + c * 0.35, 0.0, 1.0);

  // Descending front: uIntensity 0..1 sweeps a ragged front line from the
  // top edge past the bottom (1.6 overshoots so full cover holds even where
  // the noisy edge bulges). The same envelope runs in reverse on expiry, so
  // the fog lifts back out the way it came in.
  float front = uIntensity * 1.6;
  float edge = uv.y + 0.25 * (a - 0.5);
  float cover = 1.0 - smoothstep(front - 0.28, front, edge);

  // Steep contrast remap: thin gaps stay hazy-readable, billows go dense.
  float body = smoothstep(0.35, 0.75, density);
  // Stacked casts raise the alpha floor so glimpse gaps get rarer.
  float alphaFloor = clamp(0.15 + 0.10 * (uStacks - 1.0), 0.0, 0.55);
  float alpha = mix(alphaFloor, 0.95, body) * cover;

  // Depth cue: dense mist catches light, thin mist cools toward the pond.
  vec3 thinTint = vec3(0.78, 0.88, 0.90);
  vec3 denseTint = vec3(0.96, 0.98, 1.00);
  vec3 fog = mix(thinTint, denseTint, body);

  fragColor = vec4(fog * alpha, alpha);
}
