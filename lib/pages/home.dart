import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_mp3/models/descargas_model.dart';
import 'package:youtube_mp3/services/notifications_service.dart';
import 'package:youtube_mp3/utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final textController = TextEditingController();

  bool existeVideo = false;

  bool buscando = false;
  Map resultado = {};

  String progress = "";

  Isolate? isolate;

  ReceivePort receivePort = ReceivePort();
  StreamSubscription<dynamic>? subResutl;

  bool esVideo = false;

  bool quieroVideo = false;
  bool quieroMp3 = true;

  int selectTipo = 0;

  String urlInstagram = "https://www.instagram.com";
  String urlFacebook = "https://www.facebook.com";
  String urlFacebook2 = "https://fb.watch";
  String urlTikTok = "https://vm.tiktok.com";
  String urlYoutube = "https://www.youtube.com";
  String urlYoutube2 = "https://youtu.be";

  String foto = "";

  String urlDescarga = "";
  String nombreDescarga = "";

  String error = "";

  List<TiposDescarga> tiposDescarga = [
    TiposDescarga(
      selected: true,
      title: "YouTube",
      url: "https://api.akuari.my.id/downloader/yt1?link=",
    ),
    TiposDescarga(
        title: "TikTok",
        url: "https://api.akuari.my.id/downloader/tiktok?link="),
    TiposDescarga(
        title: "Facebook",
        url: "https://api.akuari.my.id/downloader/fbdl?link="),
    TiposDescarga(
      title: "Instagram",
      url: "https://api.akuari.my.id/downloader/igdl?link=",
    ),
  ];
  bool existMp4 = false;
  bool existMp3 = false;

  Timer? debounce;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await NotificationService.initialize();
    subResutl = receivePort.listen((message) {
      print(message);
      if (message is String) {
        if (message.contains("100")) {
          setState(() {
            progress = "Guardado en la carpeta de descargas";
            buscando = false;
            existeVideo = false;
            resultado.clear();
            textController.clear();
            flutterLocalNotificationsPlugin.cancel(666);
          });
        } else {
          setState(() {
            progress = message;
          });
          showNotification("Descargando", message);
        }
      }
    });
  }

  void search() async {
    if (textController.text.isNotEmpty) {
      resultado.clear();
      setState(() {
        error = "";
        buscando = true;
        existMp3 = false;
        existMp4 = false;
        existeVideo = false;
        progress = "";
      });
      final client = http.Client();
      try {
        String path = "https://api.akuari.my.id/downloader/yt1?link=";
        path = tiposDescarga[selectTipo].url;
        Uri url = Uri.parse("$path${textController.text}");
        final response = await client.get(url);
        resultado = jsonDecode(utf8.decode(response.bodyBytes));
        print(resultado);

        switch (tiposDescarga[selectTipo].title) {
          case "YouTube":
            if (resultado["mp3"] != null) {
              existMp3 = true;
              foto = resultado["mp3"]["thumbb"];
              nombreDescarga = resultado["mp3"]["title"];
            }
            if (resultado["mp4"] != null) {
              existMp4 = true;
              foto = resultado["mp3"]["thumbb"];
              nombreDescarga = resultado["mp3"]["title"];
            }
            urlDescarga = resultado["mp3"]["result"];
            quieroMp3 = true;
            quieroVideo = false;
            existeVideo = true;
            break;
          case "TikTok":
            nombreDescarga = "${Random().nextInt(1100) + 50}Tiktok";
            urlDescarga = resultado["result"]["nowm"] ??
                resultado["result"]["video_original"];
            quieroVideo = true;
            quieroMp3 = false;
            existeVideo = true;

            break;
          case "Facebook":
            foto = resultado["thumbnail"];
            nombreDescarga = resultado["title"];
            quieroVideo = true;
            quieroMp3 = false;
            existeVideo = true;

            await Future.forEach(resultado["medias"], (element) {
              Map d = element as Map;
              if (d["quality"] == "hd") {
                urlDescarga = d["url"];
                return;
              } else {
                urlDescarga = d["url"];
              }
            });
            existeVideo = true;

            break;
          case "Instagram":
            nombreDescarga = "${Random().nextInt(1100) + 50}Instagram";
            urlDescarga = resultado["respon"];
            existeVideo = true;
            quieroVideo = true;
            quieroMp3 = false;
            break;
          default:
        }

        setState(() {
          buscando = false;
        });
      } catch (e) {
        print(e);
        error = e.toString();
        setState(() {
          buscando = false;
          existeVideo = false;
        });
      } finally {
        client.close();
      }
    }
  }

  void descargar() async {
    if (!buscando) {
      setState(() {
        buscando = true;
      });
      try {
        await Permission.storage.request();
        await Permission.ignoreBatteryOptimizations.request();

        var directory = await getExternalStorageDirectory();
        print(directory?.path);
        String? path = await Utils.getDowloadDirectory();
        String name = "";
        String extencion = ".mp3";
        if (quieroMp3) {
          extencion = ".mp3";
        } else if (quieroVideo) {
          extencion = ".mp4";
        }
        if (path != null) {
          name = "$path/$nombreDescarga$extencion";
        } else {
          name = "${directory!.path}/$nombreDescarga$extencion";
        }

        isolate?.kill(priority: Isolate.immediate);
        isolate = await Isolate.spawn(
            descargarMp3,
            Params(
              path: name,
              sendPort: receivePort.sendPort,
              url: urlDescarga,
            ));
      } catch (e) {
        print(e);
        setState(() {
          buscando = false;
          existeVideo = false;
        });
      }
    }
  }

  void onTextChanged(String text) {
    if (text.isNotEmpty) {
      if (debounce?.isActive ?? false) debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 500), () {
        if (text.contains(urlYoutube) || text.contains(urlYoutube2)) {
          for (var element in tiposDescarga) {
            element.selected = false;
          }
          tiposDescarga[0].selected = true;
          selectTipo = 0;
          setState(() {});
        } else if (text.contains(urlFacebook) || text.contains(urlFacebook2)) {
          for (var element in tiposDescarga) {
            element.selected = false;
          }
          tiposDescarga[2].selected = true;
          selectTipo = 2;

          setState(() {});
        } else if (text.contains(urlInstagram)) {
          for (var element in tiposDescarga) {
            element.selected = false;
          }
          tiposDescarga[3].selected = true;
          selectTipo = 3;
          setState(() {});
        } else if (text.contains(urlTikTok)) {
          for (var element in tiposDescarga) {
            element.selected = false;
          }
          tiposDescarga[1].selected = true;
          selectTipo = 1;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    textController.dispose();
    isolate?.kill();
    receivePort.close();
    subResutl?.cancel();
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Descargar"),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: ListView(
          children: [
            const Text("Link aqui"),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: onTextChanged,
                controller: textController,
                decoration: InputDecoration(
                    suffixIcon: IconButton(
                  onPressed: () {
                    textController.clear();
                    setState(() {
                      existeVideo = false;
                      resultado.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                )),
              ),
            ),
            existeVideo
                ? SizedBox(
                    height: 150,
                    child: Image(
                      errorBuilder: (c, e, t) {
                        return const Icon(
                          Icons.image,
                          size: 100,
                        );
                      },
                      image: NetworkImage(
                        foto,
                      ),
                      loadingBuilder: (c, w, t) {
                        if (t == null) {
                          return w;
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                  )
                : const SizedBox(),
            const SizedBox(
              height: 30,
            ),
            ListView.builder(
                shrinkWrap: true,
                itemCount: tiposDescarga.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (c, index) {
                  TiposDescarga tipos = tiposDescarga[index];
                  return CheckboxListTile(
                      title: Text(
                        tipos.title,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      value: tipos.selected,
                      onChanged: (c) {
                        selectTipo = index;
                        for (var element in tiposDescarga) {
                          element.selected = false;
                        }
                        tiposDescarga[index].selected =
                            !tiposDescarga[index].selected;
                        setState(() {});
                      });
                }),
            buscando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      if (existeVideo) {
                        descargar();
                      } else {
                        search();
                      }
                    },
                    child:
                        Text(existeVideo ? "Descargar " : "Buscar resultado"),
                  ),
            Align(
              alignment: Alignment.center,
              child: Text(
                progress,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: "NexaBold",
                ),
              ),
            ),
            existeVideo
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        existMp4
                            ? Row(
                                children: [
                                  Checkbox(
                                      value: quieroVideo,
                                      onChanged: (c) {
                                        setState(() {
                                          quieroVideo = !quieroVideo;
                                          quieroMp3 = false;
                                          urlDescarga =
                                              resultado["mp4"]["result"];
                                        });
                                      }),
                                  const Text(
                                    "MP4",
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        existMp3
                            ? Row(
                                children: [
                                  Checkbox(
                                      value: quieroMp3,
                                      onChanged: (c) {
                                        setState(() {
                                          quieroVideo = false;
                                          quieroMp3 = !quieroMp3;
                                          urlDescarga =
                                              resultado["mp3"]["result"];
                                        });
                                      }),
                                  const Text(
                                    "MP3",
                                  ),
                                ],
                              )
                            : const SizedBox(),
                      ],
                    ),
                  )
                : const SizedBox(),
            Text(
              error,
              style: const TextStyle(
                color: Colors.red,
              ),
            )
          ],
        ),
      ),
    );
  }
}
