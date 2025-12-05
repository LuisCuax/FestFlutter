import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  List<Map<String, dynamic>> _quotedRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuotedRequests();
  }

  Future<void> _fetchQuotedRequests() async {
    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;
      if (user == null) return;

      // 1. Get quotes
      final quotesResponse = await SupabaseClientConfig.instance
          .from('quotes')
          .select('request_id, id, status, proposed_price')
          .eq('provider_id', user.id);
      
      final myQuotes = List<Map<String, dynamic>>.from(quotesResponse);

      if (myQuotes.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final myQuoteRequestIds = myQuotes.map((q) => q['request_id']).toList();
      final myQuotesMap = {for (var q in myQuotes) q['request_id']: q};

      // 2. Get requests
      final requestsResponse = await SupabaseClientConfig.instance
          .from('requests')
          .select('*, service_categories(name, icon)')
          .inFilter('id', myQuoteRequestIds)
          .order('created_at', ascending: false);
      
      final requests = List<Map<String, dynamic>>.from(requestsResponse);

      final quotedReqs = requests.map((req) {
        final quote = myQuotesMap[req['id']];
        return {
          ...req,
          'quote_status': quote?['status'],
          'quote_price': quote?['proposed_price'],
          'quote_id': quote?['id'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _quotedRequests = quotedReqs;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('Error fetching quoted requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.apps;
    final normalized = categoryName.toLowerCase();
    if (normalized.contains('floreria') || normalized.contains('floristeria')) return Icons.local_florist;
    if (normalized.contains('pasteleria') || normalized.contains('pastel')) return Icons.cake;
    if (normalized.contains('iluminacion') || normalized.contains('luces')) return Icons.lightbulb;
    if (normalized.contains('decoracion') || normalized.contains('globos')) return Icons.celebration;
    if (normalized.contains('catering') || normalized.contains('comida')) return Icons.restaurant;
    if (normalized.contains('musica') || normalized.contains('dj')) return Icons.music_note;
    if (normalized.contains('foto') || normalized.contains('video')) return Icons.camera_alt;
    if (normalized.contains('mobiliario') || normalized.contains('sillas')) return Icons.chair;
    if (normalized.contains('montaje') || normalized.contains('carpas')) return Icons.build;
    if (normalized.contains('animacion') || normalized.contains('entretenimiento')) return Icons.auto_awesome;
    if (normalized.contains('bebidas') || normalized.contains('barra')) return Icons.local_bar;
    return Icons.apps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Cotizaciones',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Icon(Icons.list_alt, size: 24, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : _quotedRequests.isEmpty
                        ? const Center(
                            child: Text(
                              'Aún no has enviado cotizaciones.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _quotedRequests.length,
                            itemBuilder: (context, index) {
                              final item = _quotedRequests[index];
                              final categoryName = item['service_categories']?['name'] ?? '';
                              final displayCategory = categoryName.toLowerCase() == 'floristeria' ? 'Floreria' : categoryName;
                              final isAccepted = item['quote_status'] == 'accepted';

                              return GestureDetector(
                                onTap: () => context.push('/proposal-detail/${item['quote_id']}'),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'] ?? 'Sin título',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(_getCategoryIcon(categoryName), size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(displayCategory, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Cotizado: \$${item['quote_price']}',
                                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isAccepted ? Colors.green[50] : Colors.orange[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isAccepted ? 'Aceptada' : 'Pendiente',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isAccepted ? Colors.green[800] : Colors.orange[800],
                                          ),
                                        ),
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
                  children: [
                    _buildNavItem(Icons.home, 'Inicio', false, () => context.push('/provider-home')),
                    _buildNavItem(Icons.list, 'Solicitudes', true, () {}),
                    _buildNavItem(Icons.chat_bubble_outline, 'Chats', false, () => context.push('/chats')),
                    _buildNavItem(Icons.person_outline, 'Perfil', false, () => context.push('/provider-profile')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
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
