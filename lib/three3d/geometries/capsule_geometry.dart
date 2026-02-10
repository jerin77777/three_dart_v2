import '../core/index.dart';
import '../math/index.dart';

class CapsuleGeometry extends BufferGeometry {
  CapsuleGeometry([
    double radius = 1,
    double height = 1,
    int capSegments = 4,
    int radialSegments = 8,
    int heightSegments = 1
  ]) : super() {
    type = 'CapsuleGeometry';

    parameters = {
      "radius": radius,
      "height": height,
      "capSegments": capSegments,
      "radialSegments": radialSegments,
      "heightSegments": heightSegments,
    };

    height = Math.max(0, height);
    capSegments = Math.max(1, Math.floor(capSegments.toDouble())).toInt();
    radialSegments = Math.max(3, Math.floor(radialSegments.toDouble())).toInt();
    heightSegments = Math.max(1, Math.floor(heightSegments.toDouble())).toInt();

    // buffers

    List<int> indices = [];
    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    // helper variables

    double halfHeight = height / 2;
    double capArcLength = (Math.pi / 2) * radius;
    double cylinderPartLength = height;
    double totalArcLength = 2 * capArcLength + cylinderPartLength;

    int numVerticalSegments = capSegments * 2 + heightSegments;
    int verticesPerRow = radialSegments + 1;

    Vector3 normal = Vector3();
    Vector3 vertex = Vector3();

    // generate vertices, normals, and uvs

    for (int iy = 0; iy <= numVerticalSegments; iy++) {
      double currentArcLength = 0;
      double profileY = 0;
      double profileRadius = 0;
      double normalYComponent = 0;

      if (iy <= capSegments) {
        // bottom cap
        double segmentProgress = iy / capSegments;
        double angle = (segmentProgress * Math.pi) / 2;
        profileY = -halfHeight - radius * Math.cos(angle);
        profileRadius = radius * Math.sin(angle);
        normalYComponent = -radius * Math.cos(angle);
        currentArcLength = segmentProgress * capArcLength;
      } else if (iy <= capSegments + heightSegments) {
        // middle section
        double segmentProgress = (iy - capSegments) / heightSegments;
        profileY = -halfHeight + segmentProgress * height;
        profileRadius = radius;
        normalYComponent = 0;
        currentArcLength = capArcLength + segmentProgress * cylinderPartLength;
      } else {
        // top cap
        double segmentProgress = (iy - capSegments - heightSegments) / capSegments;
        double angle = (segmentProgress * Math.pi) / 2;
        profileY = halfHeight + radius * Math.sin(angle);
        profileRadius = radius * Math.cos(angle);
        normalYComponent = radius * Math.sin(angle);
        currentArcLength = capArcLength + cylinderPartLength + segmentProgress * capArcLength;
      }

      double v = Math.max(0, Math.min(1, currentArcLength / totalArcLength));

      // special case for the poles

      double uOffset = 0;

      if (iy == 0) {
        uOffset = 0.5 / radialSegments;
      } else if (iy == numVerticalSegments) {
        uOffset = -0.5 / radialSegments;
      }

      for (int ix = 0; ix <= radialSegments; ix++) {
        double u = ix / radialSegments;
        double theta = u * Math.pi * 2;

        double sinTheta = Math.sin(theta);
        double cosTheta = Math.cos(theta);

        // vertex

        vertex.x = -profileRadius * cosTheta;
        vertex.y = profileY;
        vertex.z = profileRadius * sinTheta;
        vertices.addAll([vertex.x.toDouble(), vertex.y.toDouble(), vertex.z.toDouble()]);

        // normal

        normal.set(-profileRadius * cosTheta, normalYComponent, profileRadius * sinTheta);
        normal.normalize();
        normals.addAll([normal.x.toDouble(), normal.y.toDouble(), normal.z.toDouble()]);

        // uv

        uvs.addAll([(u + uOffset).toDouble(), v.toDouble()]);
      }

      if (iy > 0) {
        int prevIndexRow = (iy - 1) * verticesPerRow;
        for (int ix = 0; ix < radialSegments; ix++) {
          int i1 = prevIndexRow + ix;
          int i2 = prevIndexRow + ix + 1;
          int i3 = iy * verticesPerRow + ix;
          int i4 = iy * verticesPerRow + ix + 1;

          indices.addAll([i1, i2, i3]);
          indices.addAll([i2, i4, i3]);
        }
      }
    }

    // build geometry

    setIndex(indices);
    setAttribute('position', Float32BufferAttribute(Float32Array.from(vertices), 3));
    setAttribute('normal', Float32BufferAttribute(Float32Array.from(normals), 3));
    setAttribute('uv', Float32BufferAttribute(Float32Array.from(uvs), 2));
  }

  @override
  CapsuleGeometry copy(BufferGeometry source) {
    super.copy(source);
    parameters = Map.from(source.parameters ?? {});
    return this;
  }

  static CapsuleGeometry fromJSON(Map<String, dynamic> data) {
    return CapsuleGeometry(
      data["radius"]?.toDouble() ?? 1.0,
      data["height"]?.toDouble() ?? 1.0,
      data["capSegments"]?.toInt() ?? 4,
      data["radialSegments"]?.toInt() ?? 8,
      data["heightSegments"]?.toInt() ?? 1,
    );
  }
}
