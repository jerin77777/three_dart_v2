import './file_loader.dart';
import './loader.dart';

class AudioLoader extends Loader {
  AudioLoader([manager]) : super(manager);

  @override
  load(url, Function onLoad, [Function? onProgress, Function? onError]) {
    var loader = FileLoader(manager);
    loader.setPath(path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(requestHeader);
    loader.setWithCredentials(withCredentials);
    loader.load(url, (buffer) {
      // In JS, this would use AudioContext.decodeAudioData
      // Since AudioContext is not yet ported to Dart in three_dart_v2,
      // we return the raw buffer.
      onLoad(buffer);
    }, onProgress, onError);
  }
}
