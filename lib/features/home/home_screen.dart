import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await SupabaseClientConfig.instance
          .from('service_categories')
          .select('id, name, icon')
          .eq('active', true);

      if (mounted) {
        setState(() {
          _services = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final normalized = categoryName.toLowerCase();
    if (normalized.contains('floreria') || normalized.contains('floristeria')) {
      return Icons.local_florist;
    }
    if (normalized.contains('pasteleria') || normalized.contains('pastel')) {
      return Icons.cake;
    }
    if (normalized.contains('iluminacion') || normalized.contains('luces')) {
      return Icons.lightbulb;
    }
    if (normalized.contains('decoracion') || normalized.contains('globos')) {
      return Icons.celebration; // Balloon equivalent
    }
    if (normalized.contains('catering') || normalized.contains('comida')) {
      return Icons.restaurant;
    }
    if (normalized.contains('musica') || normalized.contains('dj')) {
      return Icons.music_note;
    }
    if (normalized.contains('foto') || normalized.contains('video')) {
      return Icons.camera_alt;
    }
    if (normalized.contains('mobiliario') || normalized.contains('sillas')) {
      return Icons.chair;
    }
    if (normalized.contains('montaje') || normalized.contains('carpas')) {
      return Icons.build;
    }
    if (normalized.contains('animacion') ||
        normalized.contains('entretenimiento')) {
      return Icons.auto_awesome; // Magic equivalent
    }
    if (normalized.contains('bebidas') || normalized.contains('barra')) {
      return Icons.local_bar;
    }
    return Icons.apps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  const Icon(Icons.celebration, size: 28, color: Colors.black),
                  IconButton(
                    icon: const Icon(
                      Icons.account_circle,
                      size: 28,
                      color: Colors.black,
                    ),
                    onPressed: () => context.push('/client-profile'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Qué servicio necesitas hoy?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final item = _services[index];
                          final displayName =
                              item['name'].toLowerCase() == 'floristeria'
                              ? 'Floreria'
                              : item['name'];

                          return GestureDetector(
                            onTap: () {
                              context.push(
                                '/service-request',
                                extra: {
                                  'categoryId': item['id'],
                                  'categoryName': displayName,
                                },
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getCategoryIcon(item['name']),
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Nav Bar Placeholder (or implemented as a ShellRoute in GoRouter)
              // For now, just a static row to match the visual
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, 'Inicio', true, () {}),
                    _buildNavItem(
                      Icons.calendar_today,
                      'Mis Solicitudes',
                      false,
                      () => context.push('/my-requests'),
                    ),
                    _buildNavItem(
                      Icons.chat_bubble_outline,
                      'Chats',
                      false,
                      () => context.push('/chats'),
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
