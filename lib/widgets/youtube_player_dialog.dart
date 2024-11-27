import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerDialog extends StatefulWidget {
  final String youtubeUrl;

  const YoutubePlayerDialog({Key? key, required this.youtubeUrl}) : super(key: key);

  @override
  State<YoutubePlayerDialog> createState() => _YoutubePlayerDialogState();
}

class _YoutubePlayerDialogState extends State<YoutubePlayerDialog> {
  late YoutubePlayerController _controller;
  late bool _isValid;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
    _isValid = videoId != null;
    
    if (_isValid) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_isValid) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValid) {
      return AlertDialog(
        title: const Text('Erro'),
        content: const Text('URL do YouTube inválida'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      );
    }

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 320,
        height: 240,
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          onEnded: (metaData) {
            Navigator.pop(context);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _controller.pause();
            Navigator.pop(context);
          },
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}