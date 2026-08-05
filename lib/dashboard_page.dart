import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String userName;

  const DashboardPage({super.key, this.userName = 'User'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ResQAI User',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Personal Details'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("ResQAI Dashboard"),
        backgroundColor: Colors.red,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Welcome User",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Stay Safe. Stay Alert.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,

                crossAxisSpacing: 15,

                mainAxisSpacing: 15,

                children: [
                  dashboardCard(
                    icon: Icons.location_on,
                    title: "My Location",
                    color: Colors.blue,
                  ),

                  dashboardCard(
                    icon: Icons.warning,
                    title: "Alerts",
                    color: Colors.orange,
                  ),

                  dashboardCard(
                    icon: Icons.sos,
                    title: "SOS Emergency",
                    color: Colors.red,
                  ),

                  dashboardCard(
                    icon: Icons.report,
                    title: "Report Incident",
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard({
    required IconData icon,

    required String title,

    required Color color,
  }) {
    return Card(
      elevation: 5,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: InkWell(
        onTap: () {
          // Add page navigation later
        },

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 50, color: color),

            const SizedBox(height: 15),

            Text(
              title,

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
