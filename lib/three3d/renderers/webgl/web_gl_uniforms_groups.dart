
import 'dart:typed_data';
import 'package:three_dart_v2/three3d/core/index.dart';
import 'package:three_dart_v2/three3d/math/index.dart';
import 'package:three_dart_v2/three3d/textures/index.dart';
import 'package:three_dart_v2/three3d/renderers/webgl/index.dart';

class WebGLUniformsGroups {
  dynamic gl;
  WebGLInfo info;
  WebGLCapabilities capabilities;
  WebGLState state;

  var buffers = {}; // Map<int, dynamic>
  var updateList = {}; // Map<int, num>
  List<int> allocatedBindingPoints = [];
  
  late int maxBindingPoints;

  WebGLUniformsGroups(this.gl, this.info, this.capabilities, this.state) {
    maxBindingPoints = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS);
  }

  void bind(UniformsGroup uniformsGroup, program) {
    var webglProgram = program.program;
    state.uniformBlockBinding(uniformsGroup, webglProgram);
  }

  void update(UniformsGroup uniformsGroup, program) {
    var buffer = buffers[uniformsGroup.id];

    if (buffer == null) {
      prepareUniformsGroup(uniformsGroup);

      buffer = createBuffer(uniformsGroup);
      buffers[uniformsGroup.id] = buffer;

      uniformsGroup.addEventListener('dispose', onUniformsGroupsDispose);
    }

    // ensure to update the binding points/block indices mapping for this program
    var webglProgram = program.program;
    state.updateUBOMapping(uniformsGroup, webglProgram);

    // update UBO once per frame
    var frame = info.render["frame"];

    if (updateList[uniformsGroup.id] != frame) {
      updateBufferData(uniformsGroup);
      updateList[uniformsGroup.id] = frame;
    }
  }

  dynamic createBuffer(UniformsGroup uniformsGroup) {
    // the setup of an UBO is independent of a particular shader program but global

    var bindingPointIndex = allocateBindingPointIndex();
    uniformsGroup.bindingPointIndex = bindingPointIndex;

    var buffer = gl.createBuffer();
    var size = uniformsGroup.size;
    var usage = uniformsGroup.usage;

    gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);
    gl.bufferData(gl.UNIFORM_BUFFER, size, usage);
    gl.bindBuffer(gl.UNIFORM_BUFFER, null);
    gl.bindBufferBase(gl.UNIFORM_BUFFER, bindingPointIndex, buffer);

    return buffer;
  }

  int allocateBindingPointIndex() {
    for (var i = 0; i < maxBindingPoints; i++) {
        if (allocatedBindingPoints.indexOf(i) == -1) {
            allocatedBindingPoints.add(i);
            return i;
        }
    }

    print('WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.');

    return 0;
  }

  void updateBufferData(UniformsGroup uniformsGroup) {
    var buffer = buffers[uniformsGroup.id];
    var uniforms = uniformsGroup.uniforms;
    var cache = uniformsGroup.cache!;

    gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);

    for (var i = 0, il = uniforms.length; i < il; i++) {
        // Uniforms are always objects in Dart list
        var uniform = uniforms[i];

        // Check if value changed
        if (hasUniformChanged(uniform, i, cache) == true) {
            var offset = uniform.offset!;
            
            var values = (uniform.value is List) ? uniform.value : [uniform.value];
            
            var arrayOffset = 0;
            
            for (var k = 0; k < values.length; k++) {
                var value = values[k];
                var info = getUniformSize(value);
                
                if (value is num || value is bool) {
                    uniform.data![0] = (value is bool) ? (value ? 1.0 : 0.0) : value.toDouble();
                    gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.data);
                } else if (value is Matrix3) {
                    // manually converting 3x3 to 3x4
                    var e = value.elements;
                    uniform.data![0] = e[0];
                    uniform.data![1] = e[1];
                    uniform.data![2] = e[2];
                    uniform.data![3] = 0.0;
                    uniform.data![4] = e[3];
                    uniform.data![5] = e[4];
                    uniform.data![6] = e[5];
                    uniform.data![7] = 0.0;
                    uniform.data![8] = e[6];
                    uniform.data![9] = e[7];
                    uniform.data![10] = e[8];
                    uniform.data![11] = 0.0;
                    
                    gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.data);
                } else {
                    // Vector2, Vector3, Vector4, Matrix4, Color
                    if (value.toArray != null) {
                       value.toArray(uniform.data, 0); 
                    } else {
                        // fallback or error
                        // print("Error value has no toArray: $value");
                    }

                    gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.data);
                }
                
                if (value is! num && value is! bool && value is! Matrix3) {
                     arrayOffset += (info["storage"]! ~/ 4); 
                }
            } // k loop
        }
    }
    
    gl.bindBuffer(gl.UNIFORM_BUFFER, null);
  }

  bool hasUniformChanged(Uniform uniform, int index, Map<String, dynamic> cache) {
    var value = uniform.value;
    var indexString = index.toString(); // simplified key

    if (cache[indexString] == null) {
        if (value is num || value is bool) {
            cache[indexString] = value;
        } else {
             // value is object (Vector3, Color etc)
             // need clone.
             cache[indexString] = value.clone();
        }
        return true;
    } else {
        var cachedObject = cache[indexString];
        
        if (value is num || value is bool) {
            if (cachedObject != value) {
                cache[indexString] = value;
                return true;
            }
        } else {
            if (cachedObject.equals(value) == false) {
                cachedObject.copy(value);
                return true;
            }
        }
    }

    return false;
  }

  void prepareUniformsGroup(UniformsGroup uniformsGroup) {
     var uniforms = uniformsGroup.uniforms;
     var offset = 0; // bytes
     var chunkSize = 16;
     
     for (var i = 0, l = uniforms.length; i < l; i++) {
         var uniform = uniforms[i];
         var values = (uniform.value is List) ? uniform.value : [uniform.value];
         
         for (var k = 0; k < values.length; k++) {
             var value = values[k];
             var info = getUniformSize(value);
             
             var chunkOffset = offset % chunkSize;
             var chunkPadding = chunkOffset % info["boundary"]!; // alignment check
             var chunkStart = chunkOffset + chunkPadding;
             
             offset += chunkPadding.toInt();
             
             if (chunkStart != 0 && (chunkSize - chunkStart) < info["storage"]!) {
                 offset += (chunkSize - chunkStart).toInt();
             }
             
             uniform.data = Float32List(info["storage"]! ~/ 4);
             uniform.offset = offset;
             
             offset += info["storage"]!;
         }
     }
     
     // final padding
     var chunkOffset = offset % chunkSize;
     if (chunkOffset > 0) offset += (chunkSize - chunkOffset);
     
     uniformsGroup.size = offset;
     uniformsGroup.cache = {};
  }

  Map<String, int> getUniformSize(dynamic value) {
    var info = {"boundary": 0, "storage": 0};

    if (value is num || value is bool) {
        info["boundary"] = 4;
        info["storage"] = 4;
    } else if (value is Vector2) {
        info["boundary"] = 8;
        info["storage"] = 8;
    } else if (value is Vector3 || value is Color) {
        info["boundary"] = 16;
        info["storage"] = 12; 
    } else if (value is Vector4) {
        info["boundary"] = 16;
        info["storage"] = 16;
    } else if (value is Matrix3) {
        info["boundary"] = 48; 
        info["storage"] = 48;
    } else if (value is Matrix4) {
        info["boundary"] = 64; 
        info["storage"] = 64;
    } else if (value is Texture) {
        print('WebGLRenderer: Texture samplers can not be part of an uniforms group.');
    } else {
        print('WebGLRenderer: Unsupported uniform value type. $value');
    }

    return info;
  }

  void onUniformsGroupsDispose(Event event) {
    var uniformsGroup = event.target;
    uniformsGroup.removeEventListener('dispose', onUniformsGroupsDispose);

    var index = allocatedBindingPoints.indexOf(uniformsGroup.bindingPointIndex!);
    allocatedBindingPoints.removeAt(index);

    gl.deleteBuffer(buffers[uniformsGroup.id]);

    buffers.remove(uniformsGroup.id);
    updateList.remove(uniformsGroup.id);
  }

  void dispose() {
    for (var id in buffers.keys) {
        gl.deleteBuffer(buffers[id]);
    }
    
    allocatedBindingPoints.clear();
    buffers.clear();
    updateList.clear();
  }
}
