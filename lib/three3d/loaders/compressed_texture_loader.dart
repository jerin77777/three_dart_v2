import '../constants.dart';
import './file_loader.dart';
import '../textures/compressed_texture.dart';
import './loader.dart';

class CompressedTextureLoader extends Loader {
  CompressedTextureLoader([manager]) : super(manager);

  @override
  load(url, Function onLoad, [Function? onProgress, Function? onError]) {
    var scope = this;

    List images = [];

    var texture = CompressedTexture(null, null, null, null, null, null, null, null, null, null, null, null);

    var loader = FileLoader(manager);
    loader.setPath(path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(requestHeader);
    loader.setWithCredentials(withCredentials);

    int loaded = 0;

    loadTexture(i) {
      loader.load(url[i], (buffer) {
        var texDatas = scope.parse(buffer); // Base parse only takes 1 required arg

        images[i] = {
          "width": texDatas["width"],
          "height": texDatas["height"],
          "format": texDatas["format"],
          "mipmaps": texDatas["mipmaps"]
        };

        loaded += 1;

        if (loaded == 6) {
          if (texDatas["mipmapCount"] == 1) texture.minFilter = LinearFilter;

          texture.image = images;
          texture.format = texDatas["format"];
          texture.needsUpdate = true;

          onLoad(texture);
        }
      }, onProgress, onError);
    }

    if (url is List) {
      for (var i = 0, il = url.length; i < il; ++i) {
        loadTexture(i);
      }
    } else {
      // compressed cubemap texture stored in a single DDS file

      loader.load(url, (buffer) {
        var texDatas = scope.parse(buffer);

        if (texDatas["isCubemap"]) {
          var faces = texDatas["mipmaps"].length / texDatas["mipmapCount"];

          for (var f = 0; f < faces; f++) {
            images.add({"mipmaps": []});

            for (var i = 0; i < texDatas["mipmapCount"]; i++) {
              images[f]["mipmaps"].add(texDatas["mipmaps"][f * texDatas["mipmapCount"] + i]);
              images[f]["format"] = texDatas["format"];
              images[f]["width"] = texDatas["width"];
              images[f]["height"] = texDatas["height"];
            }
          }

          texture.image = images;
        } else {
          texture.image.width = texDatas["width"];
          texture.image.height = texDatas["height"];
          texture.mipmaps = texDatas["mipmaps"];
        }

        if (texDatas["mipmapCount"] == 1) {
          texture.minFilter = LinearFilter;
        }

        texture.format = texDatas["format"];
        texture.needsUpdate = true;

        onLoad(texture);
      }, onProgress, onError);
    }

    return texture;
  }
}
