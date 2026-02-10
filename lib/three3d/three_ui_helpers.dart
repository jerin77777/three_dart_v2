import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:three_dart_v2/three3d/renderers/web_gl_renderer.dart';
import 'package:three_dart_v2/three3d/renderers/shaders/shader_chunk.dart' as sc;

class WebGLRendererWidget extends StatelessWidget {
  final WebGLRenderer renderer;

  const WebGLRendererWidget({Key? key, required this.renderer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (renderer.domElement != null) {
      if (kIsWeb && renderer.domElement is String) {
        return HtmlElementView(viewType: renderer.domElement);
      } else if (renderer.domElement is int) {
        return Texture(textureId: renderer.domElement);
      }
    }
    return Container();
  }
}

// Function to handle "THREE.WebGLRendererOptions({...})" calls
// In three_dart v2, WebGLRenderer takes a Map, but user code uses this helper.
Map<String, dynamic> WebGLRendererOptions(Map<String, dynamic> options) {
  return options;
}

// ShaderChunk instance to support [] and []= operators as used in project code.
class _ShaderChunk {
  String? operator [](Object key) {
    return sc.shaderChunk[key.toString()];
  }
  void operator []=(String key, String value) {
    sc.shaderChunk[key] = value;
  }
}

final ShaderChunk = _ShaderChunk();
