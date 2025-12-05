import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_client.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String? id;
  final String? categoryId;
  final String? categoryName;
  final String? description;
  final String? eventDate;
  final String? eventTime;
  final String? location;
  final String? guestCount;

  const ServiceRequestScreen({
    super.key,
    this.id,
    this.categoryId,
    this.categoryName,
    this.description,
    this.eventDate,
    this.eventTime,
    this.location,
    this.guestCount,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _guestCountController;

  String? _eventDate;
  String? _eventTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.description);
    _locationController = TextEditingController(text: widget.location);
    _guestCountController = TextEditingController(text: widget.guestCount);
    _eventDate = widget.eventDate;
    _eventTime = widget.eventTime;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _guestCountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate != null
          ? DateTime.parse(_eventDate!)
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _eventDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _eventTime != null
          ? TimeOfDay(
              hour: int.parse(_eventTime!.split(':')[0]),
              minute: int.parse(_eventTime!.split(':')[1]),
            )
          : TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _eventTime = DateFormat('HH:mm').format(dt);
      });
    }
  }

  Future<void> _handleSubmit() async {
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final guestCount = _guestCountController.text.trim();

    if (description.isEmpty ||
        _eventDate == null ||
        _eventTime == null ||
        location.isEmpty ||
        guestCount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseClientConfig.instance.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado.')),
        );
        return;
      }

      final requestData = {
        'description': description,
        'event_date': _eventDate,
        'event_time': _eventTime,
        'location': location,
        'address': location,
        'guest_count': int.tryParse(guestCount) ?? 0,
      };

      if (widget.id != null) {
        // Update
        await SupabaseClientConfig.instance
            .from('requests')
            .update(requestData)
            .eq('id', widget.id!);
      } else {
        // Insert
        await SupabaseClientConfig.instance.from('requests').insert({
          ...requestData,
          'client_id': user.id,
          'category_id': widget.categoryId,
          'title': 'Solicitud de ${widget.categoryName ?? 'Servicio'}',
          'status': 'open',
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Éxito'),
            content: Text(
              'Solicitud ${widget.id != null ? 'actualizada' : 'enviada'} correctamente',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  if (widget.id != null) {
                    context.pushReplacement('/my-requests');
                  } else {
                    context.pushReplacement('/home');
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un problema al enviar la solicitud.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.id != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Editar Solicitud' : 'Nueva Solicitud',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? 'Editar Solicitud'
                    : 'Describe lo que necesitas para ${widget.categoryName ?? 'tu evento'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Descripción del evento',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Ej: Necesito decoración con globos y temática de superhéroes...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _eventDate ?? 'Selecciona',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hora',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _eventTime ?? 'Selecciona',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location
              const Text(
                'Ubicación o dirección',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Calle Falsa 123, Ciudad',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Guests
              const Text(
                'Número de invitados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _guestCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 50',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Guardar Cambios' : 'Enviar solicitud',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
