import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String channelId;

  const ChatDetailScreen({super.key, required this.channelId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  String? _userId;
  String _otherUserName = 'Chat';
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final user = SupabaseClientConfig.instance.auth.currentUser;
    if (user == null) return;
    _userId = user.id;

    await _fetchChannelDetails();
    await _fetchMessages();
    _subscribeToMessages();
  }

  Future<void> _fetchChannelDetails() async {
    try {
      final data = await SupabaseClientConfig.instance
          .from('chat_channels')
          .select(
            'client_id, provider_id, client_profile:client_id(full_name), provider_profile:provider_id(business_name, full_name)',
          )
          .eq('id', widget.channelId)
          .single();

      if (mounted) {
        setState(() {
          if (_userId == data['client_id']) {
            final provider = data['provider_profile'];
            _otherUserName =
                provider?['business_name'] ??
                provider?['full_name'] ??
                'Proveedor';
          } else {
            final client = data['client_profile'];
            _otherUserName = client?['full_name'] ?? 'Cliente';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching channel details: $e');
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final data = await SupabaseClientConfig.instance
          .from('chat_messages')
          .select()
          .eq('channel_id', widget.channelId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _subscription = SupabaseClientConfig.instance
        .channel('chat:${widget.channelId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: widget.channelId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _messages.insert(0, payload.newRecord);
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _userId == null) return;

    _messageController.clear();

    try {
      await SupabaseClientConfig.instance.from('chat_messages').insert({
        'channel_id': widget.channelId,
        'sender_id': _userId,
        'content': text,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el mensaje')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _otherUserName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(15),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['sender_id'] == _userId;
                        final time = DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(msg['created_at']).toLocal());

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.red : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(15),
                                topRight: const Radius.circular(15),
                                bottomLeft: isMe
                                    ? const Radius.circular(15)
                                    : const Radius.circular(2),
                                bottomRight: isMe
                                    ? const Radius.circular(2)
                                    : const Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  msg['content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.red),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
