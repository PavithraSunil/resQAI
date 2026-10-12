import 'package:flutter/material.dart';

class SafetyTip {
  final String title;
  final String description;
  final List<String> tips;

  const SafetyTip({
    required this.title,
    required this.description,
    required this.tips,
  });
}

const safetyTips = <SafetyTip>[
  SafetyTip(
    title: 'Emergency Preparedness',
    description: 'Prepare before an emergency happens.',
    tips: [
      'Keep an emergency kit with water, food, medicine, and a flashlight.',
      'Store important phone numbers where everyone can find them.',
      'Know the safest exits and meeting points in your area.',
    ],
  ),
  SafetyTip(
    title: 'During an Emergency',
    description: 'Stay calm and follow official instructions.',
    tips: [
      'Move away from immediate danger and help children or vulnerable people.',
      'Listen to trusted emergency alerts for evacuation instructions.',
      'Call emergency services only when you need urgent assistance.',
    ],
  ),
];

class SafetyTipsPage extends StatelessWidget {
  const SafetyTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Tips'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: safetyTips.length,
        itemBuilder: (context, index) {
          final tip = safetyTips[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            child: ExpansionTile(
              leading: const Icon(Icons.shield, color: Colors.green, size: 32),

              title: Text(
                tip.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              subtitle: Text(tip.description),

              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tip.tips.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),

                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
