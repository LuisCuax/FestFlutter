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
  Map<String, dynamic>? _myQuote;
  bool _isLoading = true;
  String? _userRole;
  bool _showQuoteForm = false;

  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;
      if (user == null) return;

      // 1. Get User Role
      final profileResponse = await SupabaseClientConfig.instance
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      _userRole = profileResponse['role'];

      // 2. Fetch request details
      final requestResponse = await SupabaseClientConfig.instance
          .from('requests')
          .select('*, service_categories(name)')
          .eq('id', widget.requestId)
          .single();

      // 3. Fetch data based on role
      if (_userRole == 'provider') {
        // Check if I have quoted
        final myQuoteResponse = await SupabaseClientConfig.instance
            .from('quotes')
            .select('*')
            .eq('request_id', widget.requestId)
            .eq('provider_id', user.id)
            .maybeSingle();

        _myQuote = myQuoteResponse;
      } else {
        // Client: fetch all proposals
        final quotesResponse = await SupabaseClientConfig.instance
            .from('quotes')
            .select('*, profiles(full_name, business_name)')
            .eq('request_id', widget.requestId);
        _proposals = List<Map<String, dynamic>>.from(quotesResponse);
      }

      if (mounted) {
        setState(() {
          _request = requestResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitQuote() async {
    if (_priceController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;
      final price = double.tryParse(_priceController.text);

      if (price == null) throw Exception("Precio inválido");

      await SupabaseClientConfig.instance.from('quotes').insert({
        'request_id': widget.requestId,
        'provider_id': user!.id,
        'proposed_price': price,
        'status': 'pending',
      });

      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización enviada exitosamente')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting quote: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar cotización: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;

      // Insert a quote with 'declined' status
      await SupabaseClientConfig.instance.from('quotes').insert({
        'request_id': widget.requestId,
        'provider_id': user!.id,
        'proposed_price': 0,
        'status': 'declined',
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud rechazada')));
        context.pop(); // Go back to previous screen
      }
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al rechazar solicitud: $e')),
        );
        setState(() => _isLoading = false);
      }
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

                    if (_userRole == 'client') ...[
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
                    ] else if (_userRole == 'provider') ...[
                      if (_myQuote != null)
                        _buildMyQuoteStatus()
                      else
                        _buildQuoteForm(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions (Only for Client usually, or if Provider can cancel/edit?)
            // If Provider, we might not want these "Edit Request" buttons.
            if (_userRole == 'client')
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
                              'guestCount':
                                  _request!['guest_count']?.toString() ?? '',
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
                          // Cancel logic could go here
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

  Widget _buildMyQuoteStatus() {
    final price = _myQuote!['proposed_price'] ?? 0;
    final status = _myQuote!['status'] ?? 'pending';

    Color statusColor = Colors.orange;
    String statusText = 'Pendiente';
    if (status == 'accepted') {
      statusColor = Colors.green;
      statusText = 'Aceptada';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Rechazada';
    } else if (status == 'declined') {
      statusColor = Colors.grey;
      statusText = 'Descartada';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu Cotización',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Precio Cotizado:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Text(
                '\$$price',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estado:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteForm() {
    if (!_showQuoteForm) {
      return Container(
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
            const Text(
              '¿Te interesa esta solicitud?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _rejectRequest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showQuoteForm = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cotizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enviar Cotización',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _showQuoteForm = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Precio propuesto',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitQuote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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
    // Handle case where price might be null or differently named if we use 'proposed_price'
    final price = proposal['proposed_price'] ?? proposal['price'] ?? 0;

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
              ),
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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(providerName),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precio: \$$price',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Descripción:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                proposal['description'] ?? 'Sin descripción',
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        actions: [
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text('Rechazar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.pop(); // Close dialog
                              // Navigate to payment
                              context.push(
                                '/payment',
                                extra: {
                                  'requestId': _request!['id'],
                                  'quoteId': proposal['id'],
                                  'providerId': proposal['provider_id'],
                                  'proposedPrice': price,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Aceptar'),
                          ),
                        ],
                      ),
                    );
                  },
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
                  onPressed: () {
                    debugPrint(
                      'Navigating to payment with: requestId=${_request!['id']}, quoteId=${proposal['id']}',
                    );
                    context.push(
                      '/payment',
                      extra: {
                        'requestId': _request!['id'],
                        'quoteId': proposal['id'],
                        'providerId': proposal['provider_id'],
                        'proposedPrice': price,
                      },
                    );
                  },
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
