import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? _request;
  List<Map<String, dynamic>> _proposals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    try {
      // 1. Fetch request details
      final requestResponse = await SupabaseClientConfig.instance
          .from('requests')
          .select('*, service_categories(name)')
          .eq('id', widget.requestId)
          .single();

      // 2. Fetch proposals (quotes)
      final quotesResponse = await SupabaseClientConfig.instance
          .from('quotes')
          .select(
            '*, profiles(full_name, business_name)',
          ) // Assuming profiles is linked
          .eq('request_id', widget.requestId);

      if (mounted) {
        setState(() {
          _request = requestResponse;
          _proposals = List<Map<String, dynamic>>.from(quotesResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching request details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No se encontró la solicitud.')),
      );
    }

    final categoryName = _request!['service_categories']?['name'] ?? 'Servicio';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detalle de la Solicitud',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoría: $categoryName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _request!['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.brown,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Fecha y Hora',
                            '${_request!['event_date']} - ${_request!['event_time']}',
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            Icons.location_on,
                            'Ubicación',
                            _request!['location'] ?? '',
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            Icons.people,
                            'Invitados',
                            '${_request!['guest_count']} personas',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      'Propuestas Recibidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (_proposals.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Aún no has recibido propuestas.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._proposals.map(
                        (proposal) => _buildProposalCard(proposal),
                      ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Edit logic
                        context.push(
                          '/service-request',
                          extra: {
                            'id': _request!['id'],
                            'categoryId': _request!['category_id'],
                            'categoryName': categoryName,
                            'description': _request!['description'],
                            'eventDate': _request!['event_date'],
                            'eventTime': _request!['event_time'],
                            'location': _request!['location'],
                            'guestCount': _request!['guest_count'].toString(),
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Editar solicitud'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Cancel logic
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.brown,
                        backgroundColor: Colors.grey[100],
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar solicitud'),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.brown, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.brown),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal) {
    final providerName =
        proposal['profiles']?['business_name'] ??
        proposal['profiles']?['full_name'] ??
        'Proveedor';
    final price = proposal['price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            providerName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 5),
              const Text(
                '4.8 (120 reseñas)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ), // Mock rating
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Propuesta: \$$price',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Ver propuesta'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Elegir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
