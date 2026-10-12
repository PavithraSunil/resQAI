import 'dart:convert';

import 'package:flutter/material.dart';

import 'services/api_services.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, this.userName = 'Admin'});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  bool _notificationsOpen = false;
  bool _refreshing = false;
  bool _emergencyMode = false;
  String _selectedDistrict = 'All Kerala';
  DateTime _lastUpdated = DateTime.now().subtract(const Duration(minutes: 4));
  final _predictionFormKey = GlobalKey<FormState>();
  final _rainfall24hController = TextEditingController();
  final _rainfall3dayController = TextEditingController();
  final _soilMoistureController = TextEditingController();
  final _slopeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _predicting = false;
  String? _predictionError;
  Map<String, dynamic>? _predictionResult;
  static const _districts = [
    'All Kerala',
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];
  static const _navItems = [
    ('Overview', Icons.grid_view_rounded),
    ('Live disaster map', Icons.map_outlined),
    ('Predictions', Icons.insights_outlined),
    ('Environment', Icons.cloud_outlined),
    ('Emergency alerts', Icons.campaign_outlined),
    ('SOS management', Icons.sos_outlined),
    ('Survivor detection', Icons.person_search_outlined),
    ('Shelters', Icons.home_work_outlined),
    ('Users', Icons.people_outline),
    ('Analytics', Icons.bar_chart_rounded),
    ('Model status', Icons.memory_outlined),
  ];

  @override
  void dispose() {
    _rainfall24hController.dispose();
    _rainfall3dayController.dispose();
    _soilMoistureController.dispose();
    _slopeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f8),
      drawer: isWide ? null : Drawer(child: _sidebar()),
      body: Row(
        children: [
          if (isWide) _sidebar(),
          Expanded(child: _content(isWide)),
        ],
      ),
    );
  }

  Widget _sidebar() => Container(
    width: 248,
    color: const Color(0xff14222e),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 20, 30),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffef6c4d),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ResQAI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'COMMAND CENTER',
              style: TextStyle(
                color: Color(0xff91a0ab),
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: selected,
                    selectedTileColor: const Color(0xff263b48),
                    leading: Icon(
                      item.$2,
                      size: 20,
                      color: selected
                          ? const Color(0xffffa482)
                          : const Color(0xff9cacb7),
                    ),
                    title: Text(
                      item.$1,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xffb5c0c8),
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xff30414c), indent: 20, endIndent: 20),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: Color(0xff9cacb7),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(color: Color(0xffb5c0c8), fontSize: 13),
            ),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xffef6c4d),
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.userName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.more_horiz, color: Color(0xff9cacb7)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _content(bool isWide) => SafeArea(
    child: Stack(
      children: [
        Column(
          children: [
            _topBar(isWide),
            Expanded(child: _selectedIndex == 0 ? _overview() : _modulePage()),
          ],
        ),
        if (_notificationsOpen)
          Positioned(top: 68, right: 24, child: _notificationPanel()),
      ],
    ),
  );

  Future<void> _refreshDashboard() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _lastUpdated = DateTime.now();
      _refreshing = false;
    });
  }

  Future<void> _runLandslidePrediction() async {
    if (!_predictionFormKey.currentState!.validate()) return;

    setState(() {
      _predicting = true;
      _predictionError = null;
    });

    try {
      final response = await ApiService.predictLandslide({
        'rainfall_24h_mm': double.parse(_rainfall24hController.text.trim()),
        'rainfall_3day_mm': double.parse(_rainfall3dayController.text.trim()),
        'soil_moisture_pct': double.parse(_soilMoistureController.text.trim()),
        'slope_angle_deg': double.parse(_slopeController.text.trim()),
        'latitude': double.parse(_latitudeController.text.trim()),
        'longitude': double.parse(_longitudeController.text.trim()),
      });
      final decoded = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _predictionResult = Map<String, dynamic>.from(decoded as Map);
          _lastUpdated = DateTime.now();
        });
      } else {
        final errorBody = decoded is Map ? decoded : <String, dynamic>{};
        setState(() {
          _predictionError =
              errorBody['error']?.toString() ??
              'Prediction request failed (${response.statusCode}).';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _predictionError =
            'Could not reach the prediction service. Check that the Node backend and Flask model API are running.';
      });
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  Widget _modulePage() {
    if (_selectedIndex == 2) return _predictionsPage();
    final module = _navItems[_selectedIndex];
    final details = <int, List<String>>{
      1: ['6 active locations', '3 high-risk zones', '18 SOS locations'],
      2: [
        'Flood probability 42%',
        'Landslide probability 87%',
        'Prediction confidence 91%',
      ],
      3: ['Rainfall 84 mm', 'Water level 3.8 m', 'Temperature 24 C'],
      4: ['3 active alerts', '2 alerts sent today', '1 alert expiring soon'],
      5: ['18 active SOS', '5 new requests', 'Average response 12 min'],
      6: ['42 total detections', '8 pending rescue', '34 rescued'],
      7: [
        '12 available shelters',
        '15 total shelters',
        '68% average occupancy',
      ],
      8: [
        '1,284 registered users',
        '96 active today',
        '18 users with SOS history',
      ],
      9: [
        '24 disasters this month',
        '91% model confidence',
        '12 min average response',
      ],
      10: [
        'XGBoost: operational',
        'YOLO: operational',
        'Last model sync 4 min ago',
      ],
    };
    final moduleDetails =
        details[_selectedIndex] ??
        ['Data unavailable', 'Data unavailable', 'Data unavailable'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.$1,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xff1d2d38),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Monitor and manage ${module.$1.toLowerCase()} from the command center.',
            style: const TextStyle(color: Color(0xff71818a), fontSize: 13),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: moduleDetails.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 700 ? 3 : 1,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth > 700 ? 2.5 : 4,
              ),
              itemBuilder: (context, index) =>
                  _moduleMetric(moduleDetails[index], index),
            ),
          ),
          const SizedBox(height: 20),
          _panel(
            'Recent ${module.$1.toLowerCase()} activity',
            module.$2,
            Column(
              children: [
                _activityRow(
                  'Latest update',
                  'Updated 4 minutes ago',
                  Icons.update_outlined,
                ),
                _activityRow(
                  'System status',
                  'All connected sources operational',
                  Icons.check_circle_outline,
                ),
                _activityRow(
                  'Data source',
                  'Demonstration data until API integration',
                  Icons.info_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionsPage() => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Landslide prediction',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xff1d2d38),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Enter the six measurements used by the trained Random Forest model.',
          style: TextStyle(color: Color(0xff71818a), fontSize: 13),
        ),
        const SizedBox(height: 20),
        _panel(
          'Prediction inputs',
          Icons.tune,
          Form(
            key: _predictionFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: constraints.maxWidth > 700 ? 2 : 1,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth > 700 ? 4.8 : 5.2,
                    children: [
                      _predictionField(
                        '24-hour rainfall (mm)',
                        _rainfall24hController,
                      ),
                      _predictionField(
                        '3-day rainfall (mm)',
                        _rainfall3dayController,
                      ),
                      _predictionField(
                        'Soil moisture (%)',
                        _soilMoistureController,
                      ),
                      _predictionField(
                        'Slope angle (degrees)',
                        _slopeController,
                      ),
                      _predictionField('Latitude', _latitudeController),
                      _predictionField('Longitude', _longitudeController),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _predicting ? null : _runLandslidePrediction,
                  icon: _predicting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(
                    _predicting ? 'Running prediction...' : 'Run prediction',
                  ),
                ),
                if (_predictionError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xfffff0ed),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _predictionError!,
                      style: const TextStyle(
                        color: Color(0xffa83d32),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _panel(
          'Latest model result',
          Icons.psychology_outlined,
          _predictionSummaryContent(),
        ),
      ],
    ),
  );

  Widget _predictionField(String label, TextEditingController controller) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        validator: (value) {
          final number = double.tryParse(value?.trim() ?? '');
          if (number == null || !number.isFinite) return 'Enter a valid number';
          return null;
        },
      );

  Widget _predictionSummaryContent() {
    final result = _predictionResult;
    if (result == null) {
      return const Text(
        'No model prediction yet. Enter measurements above and run a prediction.',
        style: TextStyle(color: Color(0xff71818a), fontSize: 12),
      );
    }

    final risk = result['risk']?.toString() ?? 'Unknown';
    final highRisk = risk.toLowerCase() == 'high';
    final probabilityMap = result['class_probabilities'];
    final landslideProbability = probabilityMap is Map
        ? probabilityMap['1']
        : null;
    final probabilityText = landslideProbability is num
        ? '${(landslideProbability * 100).toStringAsFixed(1)}%'
        : 'Not provided';
    final note =
        result['note']?.toString() ??
        'Experimental model output; not an official warning.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              highRisk
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: highRisk
                  ? const Color(0xffd95343)
                  : const Color(0xff3c9a78),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              '$risk risk',
              style: TextStyle(
                color: highRisk
                    ? const Color(0xffd95343)
                    : const Color(0xff3c9a78),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Landslide class probability: $probabilityText',
          style: const TextStyle(
            color: Color(0xff344954),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          note,
          style: const TextStyle(color: Color(0xff71818a), fontSize: 11),
        ),
      ],
    );
  }

  Widget _moduleMetric(String value, int index) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xffe2e7e9)),
    ),
    child: Row(
      children: [
        Icon(
          [
            Icons.insights_outlined,
            Icons.analytics_outlined,
            Icons.timeline_outlined,
          ][index],
          color: const Color(0xffd65c48),
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xff344954),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _activityRow(String title, String detail, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xff3c9a78), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xff344954),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          detail,
          style: const TextStyle(color: Color(0xff71818a), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _topBar(bool isWide) => Container(
    height: 72,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xffe5e9ec))),
    ),
    child: Row(
      children: [
        if (!isWide)
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
        Expanded(
          child: Text(
            _navItems[_selectedIndex].$1,
            style: const TextStyle(
              color: Color(0xff1d2d38),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (isWide)
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users, SOS, shelters...',
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff91a0ab),
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xfff4f6f8),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        IconButton(
          tooltip: 'Refresh data',
          onPressed: _refreshing ? null : _refreshDashboard,
          icon: _refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, color: Color(0xff566771)),
        ),
        IconButton(
          onPressed: () =>
              setState(() => _notificationsOpen = !_notificationsOpen),
          icon: const Badge(
            label: Text('3'),
            child: Icon(
              Icons.notifications_none_rounded,
              color: Color(0xff566771),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const CircleAvatar(
          radius: 17,
          backgroundColor: Color(0xffe8f0f2),
          child: Icon(Icons.person, size: 18, color: Color(0xff46616d)),
        ),
        const SizedBox(width: 10),
        if (isWide)
          const Text(
            'System Administrator',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff566771),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    ),
  );

  Widget _overview() => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, Admin',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff1d2d38),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Here is the situation across Kerala.',
                    style: TextStyle(color: Color(0xff71818a), fontSize: 13),
                  ),
                ],
              ),
            ),
            _districtSelector(),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xfffff4e8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: Color(0xffb8752b)),
                  SizedBox(width: 8),
                  Text(
                    'DEMO DATA',
                    style: TextStyle(
                      color: Color(0xffa26725),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Last updated ${_lastUpdated.hour.toString().padLeft(2, '0')}:${_lastUpdated.minute.toString().padLeft(2, '0')}  •  Refresh for latest available data',
          style: const TextStyle(color: Color(0xff71818a), fontSize: 11),
        ),
        const SizedBox(height: 18),
        _emergencyBanner(),
        const SizedBox(height: 14),
        _modeToggle(),
        const SizedBox(height: 20),
        _systemStatus(),
        const SizedBox(height: 20),
        _kpis(),
        const SizedBox(height: 20),
        _quickActions(),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 850;
            final risk = _riskSummary();
            final map = _mapCard();
            return stacked
                ? Column(children: [risk, const SizedBox(height: 20), map])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: risk),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: map),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        _priorityQueue(),
        const SizedBox(height: 20),
        _lowerPanels(),
        const SizedBox(height: 20),
        _predictionPanel(),
        const SizedBox(height: 20),
        _activityTimeline(),
        const SizedBox(height: 20),
        _responseTimeline(),
      ],
    ),
  );

  Widget _emergencyBanner() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff7d302c),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMERGENCY STATUS  •  CRITICAL EMERGENCY SITUATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '2 critical incidents  •  5 active alerts  •  18 active SOS  •  3 high-risk districts',
                style: TextStyle(color: Color(0xffffddd5), fontSize: 11),
              ),
            ],
          ),
        ),
        const Text(
          'Updated 4 min ago',
          style: TextStyle(color: Color(0xffffddd5), fontSize: 10),
        ),
      ],
    ),
  );

  Widget _modeToggle() => Row(
    children: [
      const Text(
        'Dashboard mode',
        style: TextStyle(
          color: Color(0xff344954),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 12),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Normal mode')),
          ButtonSegment(value: true, label: Text('Emergency mode')),
        ],
        selected: {_emergencyMode},
        onSelectionChanged: (value) =>
            setState(() => _emergencyMode = value.first),
      ),
    ],
  );

  Widget _priorityQueue() => _panel(
    'Priority actions',
    Icons.priority_high_rounded,
    Column(
      children: [
        _priorityRow(
          'CRITICAL',
          'SOS • Wayanad',
          '3 people reported trapped • 2 min ago',
          const Color(0xffd95343),
          5,
        ),
        _priorityRow(
          'CRITICAL',
          'Landslide risk • Idukki',
          'Probability 87% • review prediction',
          const Color(0xffd95343),
          2,
        ),
        _priorityRow(
          'HIGH',
          'Flood risk • Pathanamthitta',
          'Water level increasing',
          const Color(0xffe68a35),
          2,
        ),
        _priorityRow(
          'MODERATE',
          'Shelter capacity • Alappuzha',
          '91% occupied • monitor capacity',
          const Color(0xffb8752b),
          7,
        ),
      ],
    ),
  );

  Widget _priorityRow(
    String severity,
    String title,
    String detail,
    Color color,
    int destination,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            severity,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff344954),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: Color(0xff71818a), fontSize: 10),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _selectedIndex = destination),
          child: const Text('VIEW', style: TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );

  Widget _predictionPanel() => _panel(
    'AI prediction details',
    Icons.psychology_outlined,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _predictionSummaryContent(),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _selectedIndex = 2),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Open Predictions'),
        ),
      ],
    ),
  );

  Widget _responseTimeline() => _panel(
    'Emergency response timeline  •  INC1024',
    Icons.route_outlined,
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _TimelineStep('MONITOR', '08:32', true),
        _TimelineStep('PREDICT', '08:41', true),
        _TimelineStep('ALERT', '08:43', true),
        _TimelineStep('SOS', '08:49', true),
        _TimelineStep('RESCUE', '08:56', false),
        _TimelineStep('RESOLVE', '--', false),
      ],
    ),
  );

  Widget _districtSelector() => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffdce3e6)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedDistrict,
        icon: const Icon(Icons.expand_more, size: 18),
        style: const TextStyle(
          color: Color(0xff344954),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        items: _districts
            .map(
              (district) =>
                  DropdownMenuItem(value: district, child: Text(district)),
            )
            .toList(),
        onChanged: (district) => setState(() => _selectedDistrict = district!),
      ),
    ),
  );

  Widget _systemStatus() => _panel(
    'System status',
    Icons.monitor_heart_outlined,
    Wrap(
      spacing: 20,
      runSpacing: 12,
      children: const [
        _StatusItem('Environmental monitoring', 'Data unavailable', false),
        _StatusItem('Prediction service', 'Data unavailable', false),
        _StatusItem('SOS service', 'Data unavailable', false),
        _StatusItem('Survivor detection', 'Data unavailable', false),
      ],
    ),
  );

  Widget _quickActions() => _panel(
    'Quick actions',
    Icons.bolt_outlined,
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton('Create emergency alert', Icons.campaign_outlined, 4),
        _actionButton('View active SOS', Icons.sos_outlined, 5),
        _actionButton('Open live map', Icons.map_outlined, 1),
        _actionButton('View shelters', Icons.home_work_outlined, 7),
        _actionButton('View survivors', Icons.person_search_outlined, 6),
        _actionButton('Open analytics', Icons.bar_chart_rounded, 9),
      ],
    ),
  );

  Widget _actionButton(String label, IconData icon, int index) =>
      OutlinedButton.icon(
        onPressed: () => setState(() => _selectedIndex = index),
        icon: Icon(icon, size: 17),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff46616d),
          side: const BorderSide(color: Color(0xffdce3e6)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );

  Widget _activityTimeline() => _panel(
    'Recent activity  •  ${_selectedDistrict.toUpperCase()}',
    Icons.history,
    Column(
      children: const [
        _ActivityItem(
          '14:32',
          'High landslide risk predicted',
          'Idukki',
          Icons.insights_outlined,
          Color(0xffd95343),
        ),
        _ActivityItem(
          '14:29',
          'New SOS received',
          'Wayanad',
          Icons.sos_outlined,
          Color(0xffe68a35),
        ),
        _ActivityItem(
          '14:25',
          'Survivor detected',
          'Idukki',
          Icons.person_search_outlined,
          Color(0xff4385a7),
        ),
        _ActivityItem(
          '14:21',
          'Emergency alert issued',
          'Wayanad',
          Icons.campaign_outlined,
          Color(0xff3c9a78),
        ),
      ],
    ),
  );

  Widget _kpis() {
    final cards = [
      ReusableKpiCard(
        title: 'ACTIVE ALERTS',
        value: '05',
        icon: Icons.campaign_outlined,
        severity: 'CRITICAL',
        accent: const Color(0xffd95343),
        trend: 'Up 2 today',
        supportingText: '2 critical',
        lastUpdated: '2 min ago',
        isLive: true,
        progress: .72,
        onTap: () => setState(() => _selectedIndex = 4),
      ),
      ReusableKpiCard(
        title: 'HIGH-RISK DISTRICTS',
        value: '02',
        icon: Icons.location_on_outlined,
        severity: 'HIGH RISK',
        accent: const Color(0xffe68a35),
        trend: 'Up 1 today',
        supportingText: 'Idukki, Wayanad',
        lastUpdated: '4 min ago',
        progress: .58,
        onTap: () => setState(() => _selectedIndex = 1),
      ),
      ReusableKpiCard(
        title: 'ACTIVE SOS REQUESTS',
        value: '12',
        icon: Icons.sos_outlined,
        severity: 'CRITICAL',
        accent: const Color(0xffd94f61),
        trend: 'Up 3 this hour',
        supportingText: '4 critical',
        lastUpdated: '30 sec ago',
        isLive: true,
        progress: .84,
        onTap: () => setState(() => _selectedIndex = 5),
      ),
      ReusableKpiCard(
        title: 'PEOPLE AT RISK',
        value: '1,284',
        icon: Icons.groups_outlined,
        severity: 'MONITOR',
        accent: const Color(0xff4385a7),
        trend: 'Up 14% today',
        supportingText: 'Across Kerala',
        lastUpdated: '4 min ago',
        isLive: true,
        progress: .64,
        onTap: () => setState(() => _selectedIndex = 1),
      ),
      ReusableKpiCard(
        title: 'SHELTER OCCUPANCY',
        value: '78%',
        icon: Icons.home_work_outlined,
        severity: 'MODERATE',
        accent: const Color(0xffb8752b),
        trend: '22% remaining',
        supportingText: 'Capacity monitored',
        lastUpdated: '5 min ago',
        progress: .78,
        onTap: () => setState(() => _selectedIndex = 7),
      ),
      ReusableKpiCard(
        title: 'ACTIVE INCIDENTS',
        value: '08',
        icon: Icons.warning_amber_rounded,
        severity: 'HIGH',
        accent: const Color(0xffe68a35),
        trend: 'Down 3 resolved today',
        supportingText: '2 critical',
        lastUpdated: '3 min ago',
        isLive: true,
        progress: .48,
        onTap: () => setState(() => _selectedIndex = 1),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 3
            : constraints.maxWidth > 650
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 2.35 : 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }

  Widget _riskSummary() => _panel(
    'Current risk summary',
    Icons.insights_outlined,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'HIGH',
              style: TextStyle(
                color: Color(0xffd95343),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Regional risk level',
              style: TextStyle(color: Color(0xff71818a), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _riskRow('Flood', '42%', 'Moderate', const Color(0xffe68a35)),
        const SizedBox(height: 14),
        _riskRow('Landslide', '87%', 'High', const Color(0xffd95343)),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Prediction confidence',
              style: TextStyle(color: Color(0xff71818a), fontSize: 11),
            ),
            Text(
              '91%',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xff1d2d38),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const Text(
          'Western Ghats region  •  Updated 4 min ago',
          style: TextStyle(color: Color(0xff71818a), fontSize: 11),
        ),
      ],
    ),
  );
  Widget _riskRow(String name, String probability, String level, Color color) =>
      Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff344954),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: double.parse(probability.replaceAll('%', '')) / 100,
                minHeight: 7,
                backgroundColor: const Color(0xffedf0f1),
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            probability,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 55,
            child: Text(
              level,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );

  Widget _mapCard() => _panel(
    'Live disaster map',
    Icons.map_outlined,
    Column(
      children: [
        Container(
          height: 255,
          decoration: BoxDecoration(
            color: const Color(0xffdce9e5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(double.infinity, 255),
                painter: _MapPainter(),
              ),
              const Positioned(top: 14, left: 14, child: _MapLegend()),
              const Positioned(
                top: 100,
                left: 150,
                child: _MapPin(color: Color(0xffd95343), label: 'HIGH'),
              ),
              const Positioned(
                top: 168,
                right: 84,
                child: _MapPin(color: Color(0xffe68a35), label: 'SOS'),
              ),
              const Positioned(
                bottom: 18,
                left: 28,
                child: _MapPin(color: Color(0xff318c71), label: 'SHELTER'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '6 active locations',
              style: TextStyle(
                color: Color(0xff344954),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            Text(
              'View full map',
              style: TextStyle(
                color: Color(0xffd65c48),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _lowerPanels() => LayoutBuilder(
    builder: (context, constraints) {
      final left = _panel(
        'Priority SOS requests',
        Icons.sos_outlined,
        Column(
          children: [
            _sosRow(
              'SOS-1048',
              'Kochi, Kerala',
              '2 min ago',
              'CRITICAL',
              const Color(0xffd95343),
            ),
            _sosRow(
              'SOS-1047',
              'Munnar, Kerala',
              '14 min ago',
              'NEW',
              const Color(0xffe68a35),
            ),
            _sosRow(
              'SOS-1042',
              'Idukki, Kerala',
              '28 min ago',
              'ASSIGNED',
              const Color(0xff4385a7),
            ),
          ],
        ),
      );
      final right = _panel(
        'Environmental conditions',
        Icons.cloud_outlined,
        Column(
          children: [
            _environmentRow(
              'Rainfall',
              '84 mm',
              'Heavy',
              Icons.water_drop_outlined,
              const Color(0xff4385a7),
            ),
            _environmentRow(
              'Water level',
              '3.8 m',
              'Rising',
              Icons.waves_outlined,
              const Color(0xffe68a35),
            ),
            _environmentRow(
              'Temperature',
              '24°C',
              'Normal',
              Icons.thermostat_outlined,
              const Color(0xff3c9a78),
            ),
          ],
        ),
      );
      return constraints.maxWidth < 700
          ? Column(children: [left, const SizedBox(height: 20), right])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 20),
                Expanded(child: right),
              ],
            );
    },
  );

  Widget _sosRow(
    String id,
    String location,
    String time,
    String status,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xff344954),
                ),
              ),
              Text(
                '$location  •  $time',
                style: const TextStyle(fontSize: 10, color: Color(0xff7c8b93)),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
  Widget _environmentRow(
    String name,
    String value,
    String status,
    IconData icon,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff344954),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xff1d2d38),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
  Widget _panel(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe2e7e9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xffd65c48), size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff1d2d38),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _notificationPanel() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            SizedBox(height: 14),
            Text(
              'New SOS request in Kochi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            Text(
              '2 minutes ago',
              style: TextStyle(fontSize: 10, color: Color(0xff71818a)),
            ),
            Divider(height: 22),
            Text(
              'Landslide risk increased to HIGH',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            Text(
              '18 minutes ago',
              style: TextStyle(fontSize: 10, color: Color(0xff71818a)),
            ),
          ],
        ),
      ),
    );
  }
}

class ReusableKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final String severity;
  final Color accent;
  final String trend;
  final String supportingText;
  final String lastUpdated;
  final bool isLive;
  final double progress;
  final VoidCallback onTap;

  const ReusableKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.severity,
    required this.accent,
    required this.trend,
    required this.supportingText,
    required this.lastUpdated,
    this.isLive = false,
    this.progress = 0,
    required this.onTap,
  });

  @override
  State<ReusableKpiCard> createState() => _ReusableKpiCardState();
}

class _ReusableKpiCardState extends State<ReusableKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = Color.lerp(Colors.white, widget.accent, .035)!;
    return Tooltip(
      message:
          '${widget.title}\n${widget.supportingText}\nUpdated ${widget.lastUpdated}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: widget.accent, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? .10 : .04),
                blurRadius: _hovered ? 12 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.accent,
                            size: 20,
                          ),
                        ),
                        Row(
                          children: [
                            if (widget.isLive) const _LiveBadge(),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: widget.accent.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.severity,
                                style: TextStyle(
                                  color: widget.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Color(0xff71818a),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        widget.value,
                        key: ValueKey(widget.value),
                        style: const TextStyle(
                          color: Color(0xff1d2d38),
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          widget.trend.startsWith('Down')
                              ? Icons.trending_down
                              : Icons.trending_up,
                          size: 15,
                          color: widget.accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.trend,
                            style: TextStyle(
                              color: widget.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          widget.supportingText,
                          style: const TextStyle(
                            color: Color(0xff71818a),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xffe9edef),
                        color: widget.accent,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Updated ${widget.lastUpdated}',
                      style: const TextStyle(
                        color: Color(0xff91a0ab),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.circle, size: 7, color: Color(0xff2ca66f)),
      SizedBox(width: 3),
      Text(
        'LIVE',
        style: TextStyle(
          color: Color(0xff2ca66f),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _MapPin extends StatelessWidget {
  final Color color;
  final String label;
  const _MapPin({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      Icon(Icons.location_on, color: color, size: 24),
    ],
  );
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final String time;
  final bool complete;

  const _TimelineStep(this.label, this.time, this.complete);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(
          complete ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: complete ? const Color(0xff3c9a78) : const Color(0xffb9c7cc),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: complete ? const Color(0xff344954) : const Color(0xff91a0ab),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: const TextStyle(fontSize: 9, color: Color(0xff71818a)),
        ),
      ],
    ),
  );
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String status;
  final bool online;

  const _StatusItem(this.label, this.status, this.online);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 175,
    child: Row(
      children: [
        Icon(
          online ? Icons.check_circle : Icons.help_outline,
          size: 17,
          color: online ? const Color(0xff2ca66f) : const Color(0xffb8752b),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff344954),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  color: online
                      ? const Color(0xff2ca66f)
                      : const Color(0xffb8752b),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActivityItem extends StatelessWidget {
  final String time;
  final String event;
  final String location;
  final IconData icon;
  final Color color;

  const _ActivityItem(
    this.time,
    this.event,
    this.location,
    this.icon,
    this.color,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff71818a),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            event,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff344954),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          location,
          style: const TextStyle(fontSize: 11, color: Color(0xff71818a)),
        ),
      ],
    ),
  );
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white70,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RISK AREAS',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Color(0xff566771),
            ),
          ),
          SizedBox(height: 5),
          Text(
            '●  High   ●  Moderate',
            style: TextStyle(fontSize: 9, color: Color(0xff566771)),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x223b9b82);
    final path = Path()
      ..moveTo(0, 50)
      ..quadraticBezierTo(size.width * .25, 0, size.width * .48, 65)
      ..quadraticBezierTo(size.width * .72, 125, size.width, 45)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
    final roads = Paint()
      ..color = const Color(0x66ffffff)
      ..strokeWidth = 2;
    for (var i = 1; i < 7; i++) {
      canvas.drawLine(
        Offset(size.width * i / 7, 0),
        Offset(size.width * (i - 1) / 7, size.height),
        roads,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
