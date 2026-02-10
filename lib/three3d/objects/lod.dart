import '../core/index.dart';
import '../math/index.dart';
import '../cameras/index.dart';

var _v1 = Vector3.init();
var _v2 = Vector3.init();

class LOD extends Object3D {
  late List<Map<String, dynamic>> levels;
  late bool autoUpdate;
  int _currentLevel = 0;

  LOD() : super() {
    type = 'LOD';
    levels = [];
    autoUpdate = true;
  }

  LOD.fromJSON(Map<String, dynamic> json, Map<String, dynamic> rootJSON) : super.fromJSON(json, rootJSON) {
    type = 'LOD';
    autoUpdate = json['autoUpdate'] ?? true;
    levels = [];

    if (json['levels'] != null) {
      for (var level in json['levels']) {
        addLevel(rootJSON['objects'][level['object']], level['distance']?.toDouble() ?? 0.0,
            level['hysteresis']?.toDouble() ?? 0.0);
      }
    }
  }

  @override
  LOD copy(Object3D source, [bool? recursive]) {
    super.copy(source, false);

    if (source is LOD) {
      var sourceLevels = source.levels;

      for (var i = 0, l = sourceLevels.length; i < l; i++) {
        var level = sourceLevels[i];
        addLevel(level['object'].clone(), level['distance'], level['hysteresis']);
      }

      autoUpdate = source.autoUpdate;
    }

    return this;
  }

  LOD addLevel(Object3D object, [num distance = 0, num hysteresis = 0]) {
    distance = distance.abs();

    int l = 0;

    for (l = 0; l < levels.length; l++) {
      if (distance < levels[l]['distance']) {
        break;
      }
    }

    levels.insert(l, {'distance': distance.toDouble(), 'hysteresis': hysteresis.toDouble(), 'object': object});

    add(object);

    return this;
  }

  bool removeLevel(num distance) {
    for (int i = 0; i < levels.length; i++) {
      if (levels[i]['distance'] == distance) {
        var removedElements = levels.removeAt(i);
        remove(removedElements['object']);

        return true;
      }
    }

    return false;
  }

  int getCurrentLevel() {
    return _currentLevel;
  }

  Object3D? getObjectForDistance(num distance) {
    if (levels.isNotEmpty) {
      int l = levels.length;
      int i = 1;

      for (i = 1; i < l; i++) {
        num levelDistance = levels[i]['distance'];

        if (levels[i]['object'].visible) {
          levelDistance -= levelDistance * levels[i]['hysteresis'];
        }

        if (distance < levelDistance) {
          break;
        }
      }

      return levels[i - 1]['object'];
    }

    return null;
  }

  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    if (levels.isNotEmpty) {
      _v1.setFromMatrixPosition(matrixWorld);

      double distance = raycaster.ray.origin.distanceTo(_v1).toDouble();

      getObjectForDistance(distance)?.raycast(raycaster, intersects);
    }
  }

  void update(Camera camera) {
    if (levels.length > 1) {
      _v1.setFromMatrixPosition(camera.matrixWorld);
      _v2.setFromMatrixPosition(matrixWorld);

      double distance = _v1.distanceTo(_v2) / camera.zoom;

      levels[0]['object'].visible = true;

      int l = levels.length;
      int i = 1;

      for (i = 1; i < l; i++) {
        num levelDistance = levels[i]['distance'];

        if (levels[i]['object'].visible) {
          levelDistance -= levelDistance * levels[i]['hysteresis'];
        }

        if (distance >= levelDistance) {
          levels[i - 1]['object'].visible = false;
          levels[i]['object'].visible = true;
        } else {
          break;
        }
      }

      _currentLevel = i - 1;

      for (; i < l; i++) {
        levels[i]['object'].visible = false;
      }
    }
  }

  @override
  Map<String, dynamic> toJSON({Object3dMeta? meta}) {
    var data = super.toJSON(meta: meta);

    if (autoUpdate == false) data['object']['autoUpdate'] = false;

    data['object']['levels'] = [];

    for (var i = 0, l = levels.length; i < l; i++) {
      var level = levels[i];

      data['object']['levels'].add({
        'object': level['object'].uuid,
        'distance': level['distance'],
        'hysteresis': level['hysteresis']
      });
    }

    return data;
  }
}
