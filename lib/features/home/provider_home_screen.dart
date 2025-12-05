import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  List<Map<String, dynamic>> _newRequests = [];
  bool _isLoading = true;
  bool _hasServices = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  Future<void> _fetchProviderData() async {
    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;
      if (user == null) return;

      // 1. Get provider services
      final servicesResponse = await SupabaseClientConfig.instance
          .from('services')
          .select('category_id')
          .eq('provider_id', user.id);
      
      final myServices = List<Map<String, dynamic>>.from(servicesResponse);

      if (myServices.isEmpty) {
        if (mounted) {
          setState(() {
            _hasServices = false;
            _isLoading = false;
          });
        }
        return;
      }

      final myCategoryIds = myServices.map((s) => s['category_id']).toList();

      // 2. Get quotes made by this provider
      final quotesResponse = await SupabaseClientConfig.instance
          .from('quotes')
          .select('request_id')
          .eq('provider_id', user.id);
      
      final myQuoteRequestIds = List<Map<String, dynamic>>.from(quotesResponse)
          .map((q) => q['request_id'])
          .toList();

      // 3. Get OPEN requests matching categories
      final requestsResponse = await SupabaseClientConfig.instance
          .from('requests')
          .select('*, service_categories(name, icon)')
          .eq('status', 'open')
          .inFilter('category_id', myCategoryIds)
          .order('created_at', ascending: false);
      
      final allRequests = List<Map<String, dynamic>>.from(requestsResponse);
      
      final filteredRequests = allRequests.where((req) {
        return !myQuoteRequestIds.contains(req['id']);
      }).toList();

      if (mounted) {
        setState(() {
          _newRequests = filteredRequests;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('Error fetching provider data: $e');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nuevas Oportunidades',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const Icon(Icons.notifications, size: 24, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Solicitudes Disponibles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const Text(
                'Basado en los servicios que ofreces.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              if (!_hasServices && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.amber),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No has registrado servicios. Configura tu perfil para ver solicitudes.',
                          style: TextStyle(color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : _newRequests.isEmpty
                        ? Center(
                            child: Text(
                              _hasServices 
                                  ? "No hay solicitudes nuevas en tus categorías." 
                                  : "Registra un servicio para empezar.",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _newRequests.length,
                            itemBuilder: (context, index) {
                              final item = _newRequests[index];
                              final categoryName = item['service_categories']?['name'] ?? '';
                              final displayCategory = categoryName.toLowerCase() == 'floristeria' ? 'Floreria' : categoryName;
                              
                              return GestureDetector(
                                onTap: () => context.push('/request-detail/${item['id']}'),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(_getCategoryIcon(categoryName), color: Colors.blue),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['title'] ?? 'Sin título',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  displayCategory,
                                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                              const SizedBox(width: 5),
                                              Text(
                                                item['event_date'] ?? '',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Text(
                                                'Ver detalle',
                                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Icon(Icons.arrow_forward, size: 16, color: Colors.red),
                                            ],
                                          ),
                                        ],
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
                    _buildNavItem(Icons.home, 'Inicio', true, () {}),
                    _buildNavItem(Icons.list, 'Solicitudes', false, () => context.push('/provider-requests')),
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
