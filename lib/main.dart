import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;
import 'package:flutter/services.dart';

void main() {
  runApp(const HoneyChainApp());
}

class HoneyChainApp extends StatelessWidget {
  const HoneyChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoneyChain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HoneyChainShell(),
    );
  }
}

class AppColors {
  static const canvas = Color(0xFF000000);
  static const surface = Color(0xFF0A0A0A);
  static const card = Color(0xFF121212);
  static const inset = Color(0xFF171717);
  static const border = Color(0xFF262626);
  static const primary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFFFFFFF);
  static const muted = Color(0xFFFFFFFF);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
}

class AppTheme {
  static const border = BorderSide(color: AppColors.border, width: 1);
  static const cardRadius = BorderRadius.all(Radius.circular(6));
  static const smallRadius = BorderRadius.all(Radius.circular(4));

  static const pageTitle = TextStyle(
    color: AppColors.primary,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.5,
  );
  static const sectionHeading = TextStyle(
    color: AppColors.primary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.30,
    letterSpacing: -0.3,
  );
  static const cardHeading = TextStyle(
    color: AppColors.primary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const body = TextStyle(
    color: AppColors.secondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const label = TextStyle(
    color: AppColors.muted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.20,
    letterSpacing: 0.5,
  );
  static const mono = TextStyle(
    color: AppColors.secondary,
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.30,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const stat = TextStyle(
    color: AppColors.primary,
    fontFamily: 'monospace',
    fontSize: 23,
    fontWeight: FontWeight.w600,
    height: 1.15,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    fontFamily: 'Arial',
    dividerColor: AppColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inset,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: const OutlineInputBorder(
        borderRadius: smallRadius,
        borderSide: border,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: smallRadius,
        borderSide: border,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: smallRadius,
        borderSide: BorderSide(color: AppColors.primary),
      ),
      labelStyle: label,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: AppTheme.body,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class BeekeeperProfile {
  const BeekeeperProfile({
    required this.name,
    required this.beneficiaryId,
    required this.cluster,
    required this.activeHives,
  });
  final String name;
  final String beneficiaryId;
  final String cluster;
  final int activeHives;
}

class TelemetryReading {
  const TelemetryReading({
    required this.label,
    required this.value,
    required this.note,
    required this.healthy,
  });
  final String label;
  final String value;
  final String note;
  final bool healthy;
}

class BatchRecord {
  const BatchRecord({
    required this.id,
    required this.hive,
    required this.quantity,
    required this.floralSource,
    required this.coordinates,
    required this.timestamp,
    required this.transactionHash,
  });
  final String id;
  final String hive;
  final String quantity;
  final String floralSource;
  final String coordinates;
  final String timestamp;
  final String transactionHash;
}

class MockHoneyService {
  static const beekeeper = BeekeeperProfile(
    name: 'Ramesh Kumar',
    beneficiaryId: 'KVIC-HM-2024-8841',
    cluster: 'Bharatpur Apiary Cluster',
    activeHives: 8,
  );

  static const telemetry = [
    TelemetryReading(label: 'BROOD TEMP', value: '34.8°C', note: 'Target: 34–35°C', healthy: true),
    TelemetryReading(label: 'HUMIDITY', value: '61.4%', note: 'Normal: 50–70%', healthy: true),
    TelemetryReading(label: 'SCALE WEIGHT', value: '42.6 kg', note: '+8.2 kg · 7-day flow', healthy: true),
    TelemetryReading(label: 'ACOUSTICS', value: '245 Hz', note: 'Colony baseline', healthy: true),
  ];

  static const verifiedBatch = BatchRecord(
    id: 'HC-2026-0847',
    hive: 'Hive #03',
    quantity: '5.0 kg',
    floralSource: 'Multifloral',
    coordinates: '27.1751° N, 78.0421° E',
    timestamp: '2026-09-07 08:14:32 UTC',
    transactionHash: '0x71c8d4f209c3ae812db97a561a0c6ebd77f5a2f488b9e3d12a7c0e58b24f3a9f',
  );
}

class HoneyChainShell extends StatefulWidget {
  const HoneyChainShell({super.key});

  @override
  State<HoneyChainShell> createState() => _HoneyChainShellState();
}

class _HoneyChainShellState extends State<HoneyChainShell> {
  int _selectedIndex = 0;

  final _views = const [BeekeeperView(), BatchCreationView(), ConsumerVerifyView()];
  final _titles = const ['Hive intelligence', 'Batch minting', 'Verification dossier'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const HoneyMark(),
            const SizedBox(width: 12),
            Text('HONEYCHAIN', style: AppTheme.label.copyWith(color: AppColors.primary, fontSize: 14, letterSpacing: 1.25)),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: AppColors.border),
            const SizedBox(width: 12),
            Expanded(child: Text(_titles[_selectedIndex], style: AppTheme.mono.copyWith(color: AppColors.secondary, fontSize: 14))),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _views),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: AppTheme.border)),
        child: NavigationBar(
          height: 64,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.inset,
          selectedIndex: _selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: 'Batch'),
            NavigationDestination(icon: Icon(Icons.verified_outlined), selectedIcon: Icon(Icons.verified), label: 'Verify'),
          ],
        ),
      ),
    );
  }
}

class BeekeeperView extends StatelessWidget {
  const BeekeeperView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = MockHoneyService.beekeeper;
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Beekeeper IoT & AI', style: AppTheme.pageTitle),
          const SizedBox(height: 6),
          Text('Live apiary operational view · Hive #03', style: AppTheme.body),
          const SizedBox(height: 20),
          EditorialCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const StatusDot(color: AppColors.green),
                const SizedBox(width: 7),
                Text('IDENTITY VERIFIED', style: AppTheme.label.copyWith(color: AppColors.green)),
              ]),
              const SizedBox(height: 14),
              Text(profile.name, style: AppTheme.sectionHeading),
              const SizedBox(height: 4),
              Text(profile.beneficiaryId, style: AppTheme.mono),
              const Divider(height: 25, thickness: 1),
              InfoRow(label: 'CLUSTER', value: profile.cluster),
              const SizedBox(height: 9),
              InfoRow(label: 'STATUS', value: '${profile.activeHives} Active Hives', valueColor: AppColors.green),
            ]),
          ),
          const SectionLabel('Hive #03 telemetry'),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: MockHoneyService.telemetry.map((reading) => SizedBox(width: width, child: TelemetryCard(reading: reading))).toList(),
            );
          }),
          const SectionLabel('Server-side diagnostics'),
          EditorialCard(
            child: Column(children: const [
              DiagnosisRow(label: 'HEALTH INDEX', value: '94/100', caption: 'Brood stability verified', color: AppColors.green),
              Divider(height: 25, thickness: 1),
              DiagnosisRow(label: 'SWARM PROBABILITY', value: '4%', caption: 'Low risk', color: AppColors.green),
              Divider(height: 25, thickness: 1),
              DiagnosisRow(label: 'HARVEST FORECAST', value: '4 DAYS', caption: 'Optimal harvest window', color: AppColors.amber),
            ]),
          ),
          const SectionLabel('System connectivity'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(color: AppColors.inset, border: Border.fromBorderSide(AppTheme.border), borderRadius: AppTheme.smallRadius),
            child: Row(children: [
              const StatusDot(color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(child: Text('GSM Gateway Online • 0 offline events', style: AppTheme.mono)),
            ]),
          ),
          const SizedBox(height: 12),
          OutlinedAction(
            label: 'WhatsApp Bridge · quick commands',
            icon: Icons.forum_outlined,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.card,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(6)), side: AppTheme.border),
              builder: (_) => const CommandSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class BatchCreationView extends StatefulWidget {
  const BatchCreationView({super.key});

  @override
  State<BatchCreationView> createState() => _BatchCreationViewState();
}

class _BatchCreationViewState extends State<BatchCreationView> {
  final TextEditingController _quantity = TextEditingController(text: '5.0');
  String _hive = 'Hive #03';
  String _floralSource = 'Multifloral';
  bool _committed = false;
  int _progress = 0;
  static const _sources = ['Mustard', 'Acacia', 'Multifloral', 'Eucalyptus'];
  static const _steps = ['Registered', 'Harvested', 'Tested', 'Bottled', 'Verified'];

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _commit() {
    FocusScope.of(context).unfocus();
    setState(() {
      _committed = true;
      _progress = 5;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch signed and committed to Polygon simulation.')));
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Harvest & batch minting', style: AppTheme.pageTitle),
        const SizedBox(height: 6),
        Text('Create an immutable provenance record.', style: AppTheme.body),
        const SizedBox(height: 20),
        EditorialCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CREATE BATCH', style: AppTheme.cardHeading),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _hive,
              dropdownColor: AppColors.card,
              decoration: const InputDecoration(labelText: 'HIVE SELECTOR'),
              items: List.generate(8, (index) => DropdownMenuItem(value: 'Hive #${(index + 1).toString().padLeft(2, '0')}', child: Text('Hive #${(index + 1).toString().padLeft(2, '0')}', style: AppTheme.mono))).toList(),
              onChanged: (value) => setState(() => _hive = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTheme.mono.copyWith(color: AppColors.primary),
              decoration: const InputDecoration(labelText: 'HARVEST QUANTITY', suffixText: 'kg', suffixStyle: AppTheme.mono),
            ),
            const SizedBox(height: 16),
            Text('FLORAL SOURCE', style: AppTheme.label),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sources.map((source) => SourceToggle(label: source, selected: _floralSource == source, onPressed: () => setState(() => _floralSource = source))).toList(),
            ),
            const Divider(height: 28, thickness: 1),
            const InfoRow(label: 'LOCKED GPS', value: '27.1751° N, 78.0421° E', monospace: true),
            const SizedBox(height: 9),
            const InfoRow(label: 'UTC TIMESTAMP', value: '2026-09-07 08:14:32 UTC', monospace: true),
          ]),
        ),
        const SizedBox(height: 12),
        PrimaryAction(label: 'Sign & Commit to Polygon', icon: Icons.lock_outline, onPressed: _commit),
        if (_committed) ...[
          const SizedBox(height: 12),
          CommitReceipt(hive: _hive, quantity: _quantity.text, source: _floralSource),
        ],
        const SectionLabel('Batch state'),
        EditorialCard(child: StepLine(steps: _steps, completed: _progress)),
        const SectionLabel('QR code preview'),
        const QrPreview(),
      ]),
    );
  }
}

class ConsumerVerifyView extends StatefulWidget {
  const ConsumerVerifyView({super.key});

  @override
  State<ConsumerVerifyView> createState() => _ConsumerVerifyViewState();
}

class _ConsumerVerifyViewState extends State<ConsumerVerifyView> {
  final TextEditingController _search = TextEditingController(text: 'HC-2026-0847');
  bool _searched = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _verify() {
    setState(() => _searched = true);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentic HoneyChain batch record located.')));
  }

  @override
  Widget build(BuildContext context) {
    final batch = MockHoneyService.verifiedBatch;
    return PageFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Consumer verification', style: AppTheme.pageTitle),
        const SizedBox(height: 6),
        Text('Trace honey from hive to bottle.', style: AppTheme.body),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: TextField(
            controller: _search,
            style: AppTheme.mono.copyWith(color: AppColors.primary),
            decoration: const InputDecoration(labelText: 'BATCH ID / SCAN RESULT', prefixIcon: Icon(Icons.search, size: 19)),
            onSubmitted: (_) => _verify(),
          )),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _verify,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.canvas, shape: const RoundedRectangleBorder(borderRadius: AppTheme.smallRadius)),
            icon: const Icon(Icons.arrow_forward),
          ),
        ]),
        if (_searched) ...[
          const SectionLabel('Provenance dossier'),
          EditorialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pure Raw Multifloral Honey', style: AppTheme.sectionHeading),
                const SizedBox(height: 5),
                Text('Batch #${batch.id}', style: AppTheme.mono),
              ])),
              const TokenBadge(),
            ]),
            const Divider(height: 25, thickness: 1),
            const InfoRow(label: 'BEEKEEPER', value: 'Ramesh Kumar'),
            const SizedBox(height: 9),
            const InfoRow(label: 'ORIGIN', value: 'Bharatpur, Rajasthan'),
            const SizedBox(height: 9),
            const InfoRow(label: 'ATTESTATION', value: 'KVIC Honey Mission verified'),
          ])),
          const SectionLabel('Lab purity matrix'),
          EditorialCard(child: Column(children: const [
            LabRow(metric: 'NMR PURITY', result: 'PASSED', detail: '100% authentic · 0% added syrup', success: true),
            Divider(height: 25, thickness: 1),
            LabRow(metric: 'MOISTURE', result: '17.1%', detail: 'FSSAI limit: ≤ 20.0%', success: true),
            Divider(height: 25, thickness: 1),
            LabRow(metric: 'HMF LEVEL', result: '11.8 mg/kg', detail: 'FSSAI limit: ≤ 80.0 mg/kg', success: true),
            Divider(height: 25, thickness: 1),
            LabRow(metric: 'LAB CERTIFICATE', result: 'NABL-CERT-9021', detail: 'National Bee Board Accredited', success: true),
          ])),
          const SectionLabel('Polygon verification ledger'),
          EditorialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TRANSACTION HASH', style: AppTheme.label),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: SelectableText(batch.transactionHash, style: AppTheme.mono.copyWith(fontSize: 11))),
              IconButton(
                tooltip: 'Copy transaction hash',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: batch.transactionHash));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction hash copied.')));
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
              ),
            ]),
            const Divider(height: 25, thickness: 1),
            const InfoRow(label: 'NETWORK', value: 'Polygon Mainnet'),
            const SizedBox(height: 9),
            const InfoRow(label: 'TOKEN STANDARD', value: 'ERC-721 HoneyNFT'),
            const SizedBox(height: 14),
            OutlinedAction(label: 'View on Polygonscan', icon: Icons.open_in_new, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Polygonscan explorer link prepared.')))),
          ])),
        ],
      ]),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
        child: child,
      ),
    );
  }
}

class EditorialCard extends StatelessWidget {
  const EditorialCard({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: const BoxDecoration(color: AppColors.card, border: Border.fromBorderSide(AppTheme.border), borderRadius: AppTheme.cardRadius),
    child: child,
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(text.toUpperCase(), style: AppTheme.label),
  );
}

class StatusDot extends StatelessWidget {
  const StatusDot({required this.color, super.key});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class InfoRow extends StatelessWidget {
  const InfoRow({required this.label, required this.value, this.valueColor = AppColors.secondary, this.monospace = false, super.key});
  final String label;
  final String value;
  final Color valueColor;
  final bool monospace;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 104, child: Text(label, style: AppTheme.label)),
    Expanded(child: Text(value, textAlign: TextAlign.right, style: (monospace ? AppTheme.mono : AppTheme.body).copyWith(color: valueColor))),
  ]);
}

class TelemetryCard extends StatelessWidget {
  const TelemetryCard({required this.reading, super.key});
  final TelemetryReading reading;
  @override
  Widget build(BuildContext context) => EditorialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [StatusDot(color: reading.healthy ? AppColors.green : AppColors.red), const SizedBox(width: 6), Expanded(child: Text(reading.label, style: AppTheme.label, overflow: TextOverflow.ellipsis))]),
    const SizedBox(height: 10),
    Text(reading.value, style: AppTheme.stat.copyWith(fontSize: 20)),
    const SizedBox(height: 5),
    Text(reading.note, style: AppTheme.mono.copyWith(color: AppColors.muted, fontSize: 10)),
  ]));
}

class DiagnosisRow extends StatelessWidget {
  const DiagnosisRow({required this.label, required this.value, required this.caption, required this.color, super.key});
  final String label;
  final String value;
  final String caption;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTheme.label), const SizedBox(height: 5), Text(caption, style: AppTheme.body)])),
    Text(value, style: AppTheme.stat.copyWith(color: color, fontSize: 21)),
  ]);
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({required this.label, required this.icon, required this.onPressed, super.key});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.canvas, shape: const RoundedRectangleBorder(borderRadius: AppTheme.smallRadius)),
      icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}

class OutlinedAction extends StatelessWidget {
  const OutlinedAction({required this.label, required this.icon, required this.onPressed, super.key});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 42,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: AppTheme.border, shape: const RoundedRectangleBorder(borderRadius: AppTheme.smallRadius)),
      icon: Icon(icon, size: 17), label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ),
  );
}

class SourceToggle extends StatelessWidget {
  const SourceToggle({required this.label, required this.selected, required this.onPressed, super.key});
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: AppTheme.smallRadius,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: selected ? AppColors.amber : AppColors.inset, border: const Border.fromBorderSide(AppTheme.border), borderRadius: AppTheme.smallRadius),
      child: Text(label, style: AppTheme.mono.copyWith(fontSize: 11, color: selected ? AppColors.canvas : AppColors.secondary)),
    ),
  );
}

class CommitReceipt extends StatelessWidget {
  const CommitReceipt({required this.hive, required this.quantity, required this.source, super.key});
  final String hive;
  final String quantity;
  final String source;
  @override
  Widget build(BuildContext context) => EditorialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const StatusDot(color: AppColors.green), const SizedBox(width: 7), Text('COMMIT CONFIRMED', style: AppTheme.label.copyWith(color: AppColors.green))]),
    const SizedBox(height: 13),
    Text('HC-2026-0847', style: AppTheme.stat),
    const SizedBox(height: 12),
    InfoRow(label: 'PAYLOAD', value: '$hive · $quantity · $source'),
    const SizedBox(height: 9),
    const InfoRow(label: 'GAS COST', value: '0.002 MATIC / ₹0.04', monospace: true),
    const SizedBox(height: 9),
    const InfoRow(label: 'BLOCK', value: '#5829104', monospace: true),
    const SizedBox(height: 9),
    const InfoRow(label: 'TX HASH', value: '0x71c8...3a9f', monospace: true),
  ]));
}

class StepLine extends StatelessWidget {
  const StepLine({required this.steps, required this.completed, super.key});
  final List<String> steps;
  final int completed;
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(steps.length, (index) {
      final done = index < completed;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: done ? AppColors.green : AppColors.inset, border: const Border.fromBorderSide(AppTheme.border), shape: BoxShape.circle), child: done ? const Icon(Icons.check, color: AppColors.canvas, size: 12) : Text('${index + 1}', style: AppTheme.mono.copyWith(fontSize: 9))),
          if (index != steps.length - 1) Container(width: 1, height: 18, color: done ? AppColors.green : AppColors.border),
        ]),
        const SizedBox(width: 10),
        Padding(padding: const EdgeInsets.only(top: 1), child: Text(steps[index].toUpperCase(), style: AppTheme.mono.copyWith(color: done ? AppColors.primary : AppColors.muted))),
      ]);
    }),
  );
}

class QrPreview extends StatelessWidget {
  const QrPreview({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(color: AppColors.card, border: Border.fromBorderSide(AppTheme.border), borderRadius: AppTheme.cardRadius),
    child: Column(children: [
      Container(width: 156, height: 156, color: AppColors.primary, padding: const EdgeInsets.all(10), child: const CustomPaint(painter: QrPainter())),
      const SizedBox(height: 13),
      Text('honeychain.gov.in/verify/HC-2026-0847', textAlign: TextAlign.center, style: AppTheme.mono.copyWith(fontSize: 11)),
    ]),
  );
}

class QrPainter extends CustomPainter {
  const QrPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.canvas;
    const cells = 21;
    final cell = size.width / cells;
    bool inFinder(int x, int y, int ox, int oy) => x >= ox && x < ox + 7 && y >= oy && y < oy + 7;
    bool finderValue(int x, int y, int ox, int oy) {
      final dx = x - ox, dy = y - oy;
      return dx == 0 || dx == 6 || dy == 0 || dy == 6 || (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4);
    }
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        bool on;
        if (inFinder(x, y, 0, 0)) on = finderValue(x, y, 0, 0);
        else if (inFinder(x, y, 14, 0)) on = finderValue(x, y, 14, 0);
        else if (inFinder(x, y, 0, 14)) on = finderValue(x, y, 0, 14);
        else on = ((x * 13 + y * 7 + x * y * 3 + 5) % 11) < 5;
        if (on) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + .2, cell + .2), paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TokenBadge extends StatelessWidget {
  const TokenBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: const BoxDecoration(color: AppColors.inset, border: Border.fromBorderSide(AppTheme.border), borderRadius: AppTheme.smallRadius),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('ERC-721', style: AppTheme.label.copyWith(color: AppColors.amber, fontSize: 9)), Text('Token #4829', style: AppTheme.mono.copyWith(fontSize: 10))]),
  );
}

class LabRow extends StatelessWidget {
  const LabRow({required this.metric, required this.result, required this.detail, required this.success, super.key});
  final String metric;
  final String result;
  final String detail;
  final bool success;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(metric, style: AppTheme.label), const SizedBox(height: 5), Text(detail, style: AppTheme.body)])),
    const SizedBox(width: 8),
    Text(result, textAlign: TextAlign.right, style: AppTheme.mono.copyWith(color: success ? AppColors.green : AppColors.red, fontWeight: FontWeight.w600)),
  ]);
}

class HoneyMark extends StatelessWidget {
  const HoneyMark({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(color: AppColors.amber, borderRadius: AppTheme.smallRadius),
    alignment: Alignment.center,
    child: const Icon(Icons.hexagon_outlined, size: 20, color: AppColors.canvas),
  );
}

class CommandSheet extends StatelessWidget {
  const CommandSheet({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WhatsApp Bridge', style: AppTheme.sectionHeading),
        const SizedBox(height: 5),
        Text('Pre-filled SMS commands for the field gateway.', style: AppTheme.body),
        const SizedBox(height: 16),
        const CommandRow(command: 'STATUS HIVE 3', description: 'Request live telemetry'),
        const SizedBox(height: 8),
        const CommandRow(command: 'HARVEST 5KG', description: 'Register harvest intent'),
      ]),
    ),
  );
}

class CommandRow extends StatelessWidget {
  const CommandRow({required this.command, required this.description, super.key});
  final String command;
  final String description;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(color: AppColors.inset, border: Border.fromBorderSide(AppTheme.border), borderRadius: AppTheme.smallRadius),
    child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(command, style: AppTheme.mono.copyWith(color: AppColors.primary)), const SizedBox(height: 3), Text(description, style: AppTheme.body)])), IconButton(onPressed: () async { await Clipboard.setData(ClipboardData(text: command)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Command copied to clipboard.'))); }, icon: const Icon(Icons.copy_outlined, size: 18))]),
  );
}
