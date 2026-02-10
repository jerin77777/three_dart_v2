import 'package:three_dart_v2/three3d/materials/material.dart';

class GroupMaterial extends Material {
  List<Material>? children;

  GroupMaterial() : super() {
    type = "GroupMaterial";
  }
}
