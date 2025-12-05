import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _activeFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Pendientes', 'Confirmados', 'Finalizados'];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;
      if (user == null) return;

      final response = await SupabaseClientConfig.instance
          .from('requests')
          .select('*, service_categories(name, icon)')
          .eq('client_id', user.id)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_activeFilter == 'Todos') return _requests;
    if (_activeFilter == 'Pendientes') return _requests.where((r) => r['status'] == 'open' || r['status'] == 'quoted').toList();
    if (_activeFilter == 'Confirmados') return _requests.where((r) => r['status'] == 'hired').toList();
    if (_activeFilter == 'Finalizados') return _requests.where((r) => r['status'] == 'completed').toList();
    return _requests;
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
              const Text(
                'Mis Solicitudes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isActive = _activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isActive,
                        onSelected: (selected) {
                          if (selected) setState(() => _activeFilter = filter);
                        },
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : Colors.black,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : _filteredRequests.isEmpty
                        ? Center(
                            child: Text(
                              'No tienes solicitudes ${_activeFilter != 'Todos' ? 'en esta categoría' : ''}.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredRequests.length,
                            itemBuilder: (context, index) {
                              final item = _filteredRequests[index];
                              final categoryName = item['service_categories']?['name'] ?? '';
                              final displayCategory = categoryName.toLowerCase() == 'floristeria' ? 'Floreria' : categoryName;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Sin título',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(_getCategoryIcon(categoryName), size: 18, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(displayCategory, style: const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    const Divider(),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Estado: ${item['status']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.red),
                                              onPressed: () => context.push('/chats', extra: {'requestId': item['id']}),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => context.push('/request-detail/${item['id']}'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                              ),
                                              child: const Text('Revisar'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
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
                    _buildNavItem(Icons.home, 'Inicio', false, () => context.push('/home')),
                    _buildNavItem(Icons.calendar_today, 'Mis Solicitudes', true, () {}),
                    _buildNavItem(Icons.chat_bubble_outline, 'Chats', false, () => context.push('/chats')),
                    _buildNavItem(Icons.person_outline, 'Perfil', false, () => context.push('/client-profile')),
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
