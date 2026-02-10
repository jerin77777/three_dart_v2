import 'dart:convert';
import '../animation/animation_clip.dart';
import './file_loader.dart';
import './loader.dart';

class AnimationLoader extends Loader {
  AnimationLoader([manager]) : super(manager);

  @override
  void load(url, onLoad, [onProgress, onError]) {
    var scope = this;

    var loader = FileLoader(manager);
    loader.setPath(path);
    loader.setRequestHeader(requestHeader);
    loader.setWithCredentials(withCredentials);
    loader.load(url, (text) {
      try {
        onLoad(scope.parse(json.decode(text)));
      } catch (e) {
        if (onError != null) {
          onError(e);
        } else {
          print(e);
        }

        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }

  @override
  List<AnimationClip> parse(json, [String? path, Function? onLoad, Function? onError]) {
    List<AnimationClip> animations = [];

    List _json = json;

    for (var i = 0; i < _json.length; i++) {
      var clip = AnimationClip.parse(_json[i]);
      animations.add(clip);
    }

    return animations;
  }
}
