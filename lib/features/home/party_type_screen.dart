import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartyTypeScreen extends StatefulWidget {
  const PartyTypeScreen({super.key});

  @override
  State<PartyTypeScreen> createState() => _PartyTypeScreenState();
}

class _PartyTypeScreenState extends State<PartyTypeScreen> {
  String? _selectedPartyTypeId;

  final List<Map<String, dynamic>> _partyOptions = [
    {
      'id': '1',
      'title': 'Fiesta Infantil',
      'description': 'Celebra a los más pequeños.',
      'icon': Icons.cake,
      'color': Colors.pink,
    },
    {
      'id': '2',
      'title': 'XV Años',
      'description': 'Un momento inolvidable.',
      'icon': Icons.star,
      'color': Colors.purple,
    },
    {
      'id': '3',
      'title': 'Boda',
      'description': 'El día más especial.',
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    {
      'id': '4',
      'title': 'Baby Shower',
      'description': 'Bienvenida al nuevo bebé.',
      'icon': Icons.child_friendly,
      'color': Colors.blue,
    },
    {
      'id': '5',
      'title': 'Evento Corporativo',
      'description': 'Profesional y memorable.',
      'icon': Icons.work,
      'color': Colors.indigo,
    },
    {
      'id': '6',
      'title': 'Reunión Familiar',
      'description': 'Momentos para compartir.',
      'icon': Icons.home,
      'color': Colors.green,
    },
    {
      'id': '7',
      'title': 'Otro',
      'description': 'Personaliza tu evento.',
      'icon': Icons.more_horiz,
      'color': Colors.orange,
    },
  ];

  void _handleContinue() {
    if (_selectedPartyTypeId != null) {
      context.push('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona un tipo de fiesta para continuar.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // If we can't go back (e.g. from login), maybe logout?
            // Or just let it be if it's the start of the flow.
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Qué tipo de fiesta necesitas?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _partyOptions.length,
                  itemBuilder: (context, index) {
                    final item = _partyOptions[index];
                    final isSelected = item['id'] == _selectedPartyTypeId;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPartyTypeId = item['id']),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red[50] : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected
                                ? Colors.red
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'],
                              size: 40,
                              color: isSelected ? Colors.red : item['color'],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                item['description'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
