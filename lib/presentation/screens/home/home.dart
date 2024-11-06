import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<AssetPathEntity> albums = [];
  List<AssetEntity> media = [];
  List<AssetEntity> selectedImages = [];
  AssetPathEntity? selectedAlbums;

  static const maxLength = 10;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      fetchAlbums();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> fetchAlbums() async {
    final List<AssetPathEntity> result =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    setState(() {
      albums = result;
      selectedAlbums = albums.isNotEmpty ? albums.first : null;
    });
    if (selectedAlbums != null) {
      fetchMedia(selectedAlbums!);
    }
  }

  Future<void> fetchMedia(AssetPathEntity album) async {
    final List<AssetEntity> result =
        await album.getAssetListPaged(page: 0, size: 100);
    setState(() {
      media = result;
    });
  }

  void toggleSelection(AssetEntity asset) {
    setState(() {
      if (!selectedImages.contains(asset) && selectedImages.length < maxLength) {
        validateImage ? selectedImages.add(asset) : showMessageError();
      }
    });
  }

  void onAlbumSelected(AssetPathEntity? album) {
    if (album != null) {
      setState(() {
        selectedAlbums = album;
      });
      fetchMedia(album);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: DropdownButton<AssetPathEntity>(
          value: selectedAlbums,
          menuMaxHeight: MediaQuery.of(context).size.height / 2,
          alignment: Alignment.center,
          items: albums.map((album) {
            return DropdownMenuItem(
              value: album,
              child: Text(
                album.name,
                style: const TextStyle(color: Colors.black),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
          onChanged: onAlbumSelected,
          dropdownColor: Colors.white,
          underline: Container(),
          iconEnabledColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: media.length,
              itemBuilder: (context, index) {
                final asset = media[index];
                final isSelected = selectedImages.contains(asset);
                return GestureDetector(
                  onTap: () => toggleSelection(asset),
                  child: Stack(
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                            isSelected
                                ? Colors.black.withOpacity(0.4)
                                : Colors.transparent,
                            BlendMode.srcOver),
                        child: AssetEntityImage(
                          asset,
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chọn $maxLength ảnh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(50)),
                          child: const Text(
                            'Gần đây',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showMessageError();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: selectedImages.length == maxLength
                                    ? Colors.blueGrey
                                    : Colors.blueGrey.withOpacity(0.5),
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(50)),
                            child: Text(
                              'Tiếp theo(${selectedImages.length})',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 75,
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: maxLength,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: index <= selectedImages.length - 1
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.remove(selectedImages[index]);
                                });
                              },
                              child: Stack(
                                children: [
                                  AssetEntityImage(
                                    selectedImages[index],
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(Icons.cancel_sharp,
                                        color: Colors.white60, size: 18),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              height: 60,
                              width: 60,
                              color: Colors.grey[200],
                            ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ],
      ),
    );
  }

  void showMessageError() {
    Fluttertoast.showToast(
      msg: "Bức ảnh này không thể chọn. Vui lòng chọn ảnh khác",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      fontSize: 16.0,
      backgroundColor: Colors.black45,
    );
  }

  bool get validateImage {
    int random = Random().nextInt(10);
    return random % 2 == 0;
  }
}
