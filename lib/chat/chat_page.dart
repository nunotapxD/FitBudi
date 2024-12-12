import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatPage({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Stream<QuerySnapshot> _getMessages() {
    final currentUserId = _auth.currentUser?.uid;
    
    return _firestore
        .collection('messages')
        .where(Filter.or(
          Filter.and(
            Filter('senderId', isEqualTo: currentUserId),
            Filter('receiverId', isEqualTo: widget.otherUserId),
          ),
          Filter.and(
            Filter('senderId', isEqualTo: widget.otherUserId),
            Filter('receiverId', isEqualTo: currentUserId),
          ),
        ))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _sendMessage(messageText: _messageController.text.trim());
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage({
    String? messageText,
    String? fileName,
    String? fileType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final message = {
        'senderId': user.uid,
        'receiverId': widget.otherUserId,
        'timestamp': FieldValue.serverTimestamp(),
        if (messageText != null) 'text': messageText,
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
      };

      await _firestore.collection('messages').add(message);
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  Future<void> _handleFilePick() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final fileExt = fileName.split('.').last.toLowerCase();

        // Aqui você pode implementar a lógica de upload do arquivo
        // Por enquanto, vamos apenas simular enviando o nome do arquivo
        await _sendMessage(
          fileName: fileName,
          fileType: fileExt,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

Widget _buildMessage(Map<String, dynamic> message, bool isMe) {
  final timestamp = message['timestamp'] as Timestamp?;
  final time = timestamp != null 
      ? DateFormat('HH:mm').format(timestamp.toDate())
      : '';

  if (message['fileName'] != null) {
    return FileMessageBubble(
      fileName: message['fileName'],
      fileType: message['fileType'] ?? '',
      fileUrl: message['fileUrl'], // Adicionado
      isSent: isMe,
      time: time,
    );
  }

  return MessageBubble(
    message: message['text'] ?? '',
    isSent: isMe,
    time: time,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFF1E1E1E),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getMessages(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index].data() as Map<String, dynamic>;
                      final isMe = message['senderId'] == _auth.currentUser?.uid;
                      return _buildMessage(message, isMe);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: Colors.grey,
                    ),
                    onPressed: _handleFilePick,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Digite sua mensagem',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _sendTextMessage,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.green,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSent;
  final String time;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSent,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSent ? Colors.white : const Color(0xFF2C6BED),
          borderRadius: BorderRadius.only(
            topLeft: isSent ? const Radius.circular(16) : const Radius.circular(0),
            topRight: isSent ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isSent ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isSent ? Colors.black54 : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileMessageBubble extends StatelessWidget {
  final String fileName;
  final String fileType;
  final bool isSent;
  final String time;
  final String? fileUrl; // Adicionado para armazenar a URL do arquivo

  const FileMessageBubble({
    Key? key,
    required this.fileName,
    required this.fileType,
    required this.isSent,
    required this.time,
    this.fileUrl,
  }) : super(key: key);

  IconData _getFileIcon() {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool get _isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    return imageExtensions.contains(fileType.toLowerCase());
  }

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(fileName),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                fileUrl ?? '',
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Erro ao carregar imagem'),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSent ? Colors.white : const Color(0xFF2C6BED),
          borderRadius: BorderRadius.only(
            topLeft: isSent ? const Radius.circular(16) : const Radius.circular(0),
            topRight: isSent ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (_isImage && fileUrl != null) ...[
              GestureDetector(
                onTap: () => _showImagePreview(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fileUrl!,
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFileIcon(),
                  color: isSent ? Colors.black : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      color: isSent ? Colors.black : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isSent ? Colors.black54 : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}