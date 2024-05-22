import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(MaterialApp(home: ChatScreen()));
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<MediaFile> recentFiles = [];
  List<ChatMessage> chatMessages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                return message.type == MediaType.image
                    ? Container(height:100,width:100,child: Image.file(File(message.path), fit: BoxFit.cover))
                    : message.type == MediaType.video
                    ? FutureBuilder<String?>(
                  future: generateThumbnail(message.path),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                      return Container(height:100,width:100,child: Image.file(File(snapshot.data!), fit: BoxFit.cover));
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                )
                    : ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(message.path),
                );
              },
            ),
          ),
          // Recent button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _showRecentFiles(context),
              child: Text('Recent'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _pickMedia(MediaType.image),
                child: Text('Add Image'),
              ),
              ElevatedButton(
                onPressed: () => _pickMedia(MediaType.video),
                child: Text('Add Video'),
              ),
              ElevatedButton(
                onPressed: () => _addLocation(),
                child: Text('Add Location'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecentFiles(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return RecentFilesBottomSheet(
          recentFiles: recentFiles,
          onSend: (file) {
            setState(() {
              chatMessages.add(ChatMessage(path: file.path, type: file.type));
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _pickMedia(MediaType type) async {
    final XFile? pickedFile;
    if (type == MediaType.image) {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    } else if (type == MediaType.video) {
      pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      return;
    }

    if (pickedFile != null) {
      MediaFile file = MediaFile(path: pickedFile.path, type: type);
      addRecentFile(file);
    }
  }

  void _addLocation() {
    // Simulate adding a location
    MediaFile file = MediaFile(path: 'Location ${recentFiles.length}', type: MediaType.location);
    addRecentFile(file);
  }

  void addRecentFile(MediaFile file) {
    setState(() {
      recentFiles.add(file);
      if (recentFiles.length > 10) {
        recentFiles.removeAt(0); // Keep the list to a maximum of 10 items
      }
    });
  }
}

class MediaFile {
  final String path;
  final MediaType type;

  MediaFile({required this.path, required this.type});
}

enum MediaType {
  image,
  video,
  location,
}

class ChatMessage {
  final String path;
  final MediaType type;

  ChatMessage({required this.path, required this.type});
}

class RecentFilesBottomSheet extends StatelessWidget {
  final List<MediaFile> recentFiles;
  final Function(MediaFile) onSend;

  RecentFilesBottomSheet({required this.recentFiles, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: recentFiles.length,
              itemBuilder: (context, index) {
                final file = recentFiles[index];
                return GestureDetector(
                  onTap: () => onSend(file),
                  child: file.type == MediaType.image
                      ? Image.file(File(file.path), fit: BoxFit.cover)
                      : file.type == MediaType.video
                      ? FutureBuilder<String?>(
                    future: generateThumbnail(file.path),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return Image.file(File(snapshot.data!), fit: BoxFit.cover);
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  )
                      : Icon(Icons.location_on, size: 50),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> generateThumbnail(String videoPath) async {
  return await VideoThumbnail.thumbnailFile(
    video: videoPath,
    imageFormat: ImageFormat.JPEG,
    maxWidth: 150,
    quality: 75,
  );
}

