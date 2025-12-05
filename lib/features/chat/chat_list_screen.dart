import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';

class ChatListScreen extends StatefulWidget {
  final String? requestId;

  const ChatListScreen({super.key, this.requestId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _channels = [];
  bool _isLoading = true;
  String? _userId;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;
      if (user == null) return;

      setState(() {
        _userId = user.id;
        _userRole = user.userMetadata?['role'] ?? 'client';
      });

      var query = SupabaseClientConfig.instance
          .from('chat_channels')
          .select(
            '*, requests(title), client_profile:client_id(full_name, avatar_url), provider_profile:provider_id(business_name, full_name, avatar_url)',
          )
          .or('client_id.eq.${user.id},provider_id.eq.${user.id}');

      if (widget.requestId != null) {
        query = query.eq('request_id', widget.requestId!);
      }

      final response = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _channels = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Mis Chats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    )
                  : _channels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.requestId != null
                                ? "No hay chats para esta solicitud."
                                : "No tienes conversaciones activas.",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _channels.length,
                      itemBuilder: (context, index) {
                        final item = _channels[index];
                        final isClient = _userId == item['client_id'];

                        final otherProfile = isClient
                            ? item['provider_profile']
                            : item['client_profile'];
                        final otherName = isClient
                            ? (otherProfile?['business_name'] ??
                                  otherProfile?['full_name'] ??
                                  'Proveedor')
                            : (otherProfile?['full_name'] ?? 'Cliente');

                        final initials = otherName.isNotEmpty
                            ? otherName.substring(0, 2).toUpperCase()
                            : '??';
                        final requestTitle =
                            item['requests']?['title'] ?? 'Sin asunto';

                        return GestureDetector(
                          onTap: () => context.push('/chat/${item['id']}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        otherName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        requestTitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Nav Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _userRole == 'provider'
                    ? [
                        _buildNavItem(
                          Icons.home,
                          'Inicio',
                          false,
                          () => context.push('/provider-home'),
                        ),
                        _buildNavItem(
                          Icons.list,
                          'Solicitudes',
                          false,
                          () => context.push('/provider-requests'),
                        ),
                        _buildNavItem(
                          Icons.chat_bubble_outline,
                          'Chats',
                          true,
                          () {},
                        ),
                        _buildNavItem(
                          Icons.person_outline,
                          'Perfil',
                          false,
                          () => context.push('/provider-profile'),
                        ),
                      ]
                    : [
                        _buildNavItem(
                          Icons.home,
                          'Inicio',
                          false,
                          () => context.push('/home'),
                        ),
                        _buildNavItem(
                          Icons.calendar_today,
                          'Mis Solicitudes',
                          false,
                          () => context.push('/my-requests'),
                        ),
                        _buildNavItem(
                          Icons.chat_bubble_outline,
                          'Chats',
                          true,
                          () {},
                        ),
                        _buildNavItem(
                          Icons.person_outline,
                          'Perfil',
                          false,
                          () => context.push('/client-profile'),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.red : Colors.grey, size: 26),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.red : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
