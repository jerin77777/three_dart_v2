import '../constants.dart';
import '../textures/index.dart';
import './image_loader.dart';
import './loader.dart';

class CubeTextureLoader extends Loader {
  CubeTextureLoader([manager]) : super(manager);

  @override
  load(urls, Function onLoad, [Function? onProgress, Function? onError]) {
    var texture = CubeTexture(null, null, null, null, null, null, null, null, null, null);
    texture.encoding = sRGBEncoding;

    var loader = ImageLoader(manager);
    loader.setCrossOrigin(crossOrigin);
    loader.setPath(path);

    int loaded = 0;

    loadTexture(i) {
      loader.load(urls[i], (image) {
        texture.images[i] = image;

        loaded++;

        if (loaded == 6) {
          texture.needsUpdate = true;

          onLoad(texture);
        }
      }, null, onError);
    }

    for (int i = 0; i < urls.length; ++i) {
      loadTexture(i);
    }

    return texture;
  }
}
