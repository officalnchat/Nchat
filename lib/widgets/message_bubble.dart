import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final String imageUrl;
  final String type;
  final String time;
  final String audioUrl;
  final bool isMe;
  final int status;

  final bool isStarred;

  final String forwarded;

  final String reaction;

  final String replyMessage;
  final String replyType;

  final VoidCallback? onSwipeReply;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.imageUrl,
    required this.type,
    required this.time,
    required this.isMe,
    required this.status,
    required this.isStarred,
    required this.forwarded,
    required this.reaction,
    required this.replyMessage,
    required this.replyType,
    required this.audioUrl,
    this.onSwipeReply,
    this.onLongPress,
  });

  @override
State<MessageBubble> createState() =>
    _MessageBubbleState();
}

class _MessageBubbleState
    extends State<MessageBubble> {

      final AudioPlayer _audioPlayer = AudioPlayer();

bool _isPlaying = false;

Duration _duration = Duration.zero;

Duration _position = Duration.zero;

bool _loaded = false;

@override
void initState() {
  super.initState();

  _audioPlayer.durationStream.listen((duration) {
    if (!mounted || duration == null) return;

    setState(() {
      _duration = duration;
    });
  });

  _audioPlayer.positionStream.listen((position) {
    if (!mounted) return;

    setState(() {
      _position = position;
    });
  });

  _audioPlayer.playerStateStream.listen((state) {
    if (!mounted) return;

   if (state.processingState == ProcessingState.completed) {
  _loaded = false;

  _audioPlayer.seek(Duration.zero);

  if (!mounted) return;

  setState(() {
  _position = Duration.zero;
  _isPlaying = false;
});

  return;
}
    setState(() {
      _isPlaying = state.playing;
    });
  });
}

Future<void> _toggleAudio() async {
  try {
    if (_isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    if (!_loaded) {
      await _audioPlayer.setUrl(widget.audioUrl);
      _loaded = true;
    }

    await _audioPlayer.play();
  } catch (e) {
    debugPrint("Audio Error: $e");
  }
}

@override
void dispose() {
  _audioPlayer.stop();
  _audioPlayer.dispose();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,

      confirmDismiss: (direction) async {
        widget.onSwipeReply?.call();
        return false;
      },

      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.transparent,
        child: const Icon(
          Icons.reply,
          color: Colors.green,
          size: 28,
        ),
      ),

      child: GestureDetector(
        onLongPress: widget.onLongPress,
        child: Align(
          alignment: widget.isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,

          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 280,
            ),

            margin: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),

            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.green.shade400
                  : Colors.grey.shade300,

              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(
                  widget.isMe ? 16 : 0,
                ),
                   bottomRight: Radius.circular(
                    widget.isMe ? 0 : 16,
                ),
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
               if (widget.forwarded == "true")
  Padding(
    padding: const EdgeInsets.only(
      bottom: 4,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "↪ Forwarded",
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: widget.isMe
              ? Colors.white70
              : Colors.black54,
        ),
      ),
    ),
  ),
                if (widget.isStarred)
  const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Icon(
        Icons.star,
        color: Colors.amber,
        size: 16,
      ),
    ),
  ),

                if (widget.replyMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius:
                          BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(
                          color: Colors.green,
                          width: 4,
                        ),
                      ),
                    ),
                                        child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.replyType == "image"
                              ? "📷 Photo"
                              : widget.replyMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.isMe
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.type == "image")
  if (widget.imageUrl.isNotEmpty)
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
         widget.imageUrl,
        width: 220,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: 220,
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      ),
    )
  else
    Container(
      width: 220,
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    ),

               if (widget.type == "text")
  Align(
    alignment: Alignment.centerLeft,
    child: Text(
      widget.message,
      style: TextStyle(
        color: widget.isMe
            ? Colors.white
            : Colors.black,
        fontSize: 16,
      ),
    ),
  ),

if (widget.type == "audio")
  SizedBox(
    width: 230,
    child: Row(
      children: [

        IconButton(
          onPressed: _toggleAudio,
          icon: Icon(
            _isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            size: 36,
            color: widget.isMe
                ? Colors.white
                : Colors.green,
          ),
        ),

        Expanded(
          child: Slider(
            value: _position.inMilliseconds
                .toDouble()
                .clamp(
                  0,
                  _duration.inMilliseconds == 0
                      ? 1
                      : _duration.inMilliseconds.toDouble(),
                ),
            max: _duration.inMilliseconds == 0
                ? 1
                : _duration.inMilliseconds.toDouble(),
            onChanged: (value) async {
              await _audioPlayer.seek(
                Duration(
                  milliseconds: value.toInt(),
                ),
              );
            },
          ),
        ),

        Text(
          "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
          style: TextStyle(
            fontSize: 12,
            color: widget.isMe
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    ),
  ),

                  if (widget.reaction.isNotEmpty)
  Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(
        top: 4,
      ),
      child: Text(
        widget.reaction,
        style: const TextStyle(
          fontSize: 20,
        ),
      ),
    ),
  ),

                const SizedBox(height: 5),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                       widget.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isMe
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),

                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.status == 3
                            ? Icons.done_all
                            : widget.status == 2
                                ? Icons.done_all
                                : Icons.done,
                        size: 16,
                        color: widget.status == 3
                            ? Colors.blue
                            : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}