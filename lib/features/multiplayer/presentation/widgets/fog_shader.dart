import 'dart:ui' as ui;

/// Loads and caches the fog `FragmentProgram` once, so the first fog cast in a
/// match does not pay the shader-compile cost mid-frame. Warmed at bootstrap.
ui.FragmentProgram? _program;

ui.FragmentProgram? get fogProgram => _program;

Future<void> warmUpFogShader() async {
  if (_program != null) return;
  try {
    _program = await ui.FragmentProgram.fromAsset('assets/shaders/fog.frag');
  } catch (_) {
    // A shader-compile failure must never break bootstrap: the overlay falls
    // back to the flat scrim when the program is null.
    _program = null;
  }
}
