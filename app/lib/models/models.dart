import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class HoneyBatch {
  const HoneyBatch({
    required this.id,
    required this.hiveId,
    required this.quantity,
    required this.floralSource,
    required this.origin,
    required this.coordinates,
    required this.timestamp,
    required this.transactionHash,
    required this.purityIndex,
    required this.status,
  });

  final String id;
  final String hiveId;
  final String quantity;
  final String floralSource;
  final String origin;
  final String coordinates;
  final String timestamp;
  final String transactionHash;
  final double purityIndex;
  final BatchStatus status;
}

enum BatchStatus { registered, harvested, tested, bottled, verified }

class TraceabilityNode {
  const TraceabilityNode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.details,
    required this.isCompleted,
    this.transactionHash,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Map<String, String> details;
  final bool isCompleted;
  final String? transactionHash;
}

class BeekeeperProfile {
  const BeekeeperProfile({
    required this.name,
    required this.beneficiaryId,
    required this.cluster,
    required this.walletAddress,
    required this.activeHives,
    required this.totalBatches,
  });

  final String name;
  final String beneficiaryId;
  final String cluster;
  final String walletAddress;
  final int activeHives;
  final int totalBatches;
}

class TelemetryReading {
  const TelemetryReading({
    required this.label,
    required this.value,
    required this.unit,
    required this.note,
    required this.healthy,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final String note;
  final bool healthy;
  final IconData icon;
}

class LabResult {
  const LabResult({
    required this.metric,
    required this.result,
    required this.detail,
    required this.passed,
  });

  final String metric;
  final String result;
  final String detail;
  final bool passed;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Data Service
// ─────────────────────────────────────────────────────────────────────────────

abstract final class MockData {
  // ─── Dashboard Stats ───
  static const int totalBatchesVerified = 12450;
  static const double avgPurityIndex = 99.8;
  static const int activeBeekeepers = 842;
  static const int blockHeight = 5829104;

  // ─── Beekeeper ───
  static const beekeeper = BeekeeperProfile(
    name: 'Ramesh Kumar',
    beneficiaryId: 'KVIC-HM-2024-8841',
    cluster: 'Bharatpur Apiary Cluster',
    walletAddress: '0x92f1a8B3...d47e8eB3',
    activeHives: 8,
    totalBatches: 37,
  );

  // ─── Telemetry ───
  static const telemetry = [
    TelemetryReading(
      label: 'BROOD TEMP',
      value: '34.8',
      unit: '°C',
      note: 'Target: 34–35 °C',
      healthy: true,
      icon: Icons.thermostat_rounded,
    ),
    TelemetryReading(
      label: 'HUMIDITY',
      value: '61.4',
      unit: '%',
      note: 'Normal: 50–70%',
      healthy: true,
      icon: Icons.water_drop_outlined,
    ),
    TelemetryReading(
      label: 'HIVE WEIGHT',
      value: '42.6',
      unit: 'kg',
      note: '+8.2 kg · 7-day flow',
      healthy: true,
      icon: Icons.scale_outlined,
    ),
    TelemetryReading(
      label: 'ACOUSTICS',
      value: '245',
      unit: 'Hz',
      note: 'Colony baseline',
      healthy: true,
      icon: Icons.graphic_eq_rounded,
    ),
  ];

  // ─── Featured Batches ───
  static const featuredBatches = [
    HoneyBatch(
      id: 'HC-2026-0847',
      hiveId: 'Hive #03',
      quantity: '5.0 kg',
      floralSource: 'Multifloral',
      origin: 'Bharatpur, Rajasthan',
      coordinates: '27.1751° N, 78.0421° E',
      timestamp: '2026-09-07 08:14:32 UTC',
      transactionHash:
          '0x71c8d4f209c3ae812db97a561a0c6ebd77f5a2f488b9e3d12a7c0e58b24f3a9f',
      purityIndex: 99.8,
      status: BatchStatus.verified,
    ),
    HoneyBatch(
      id: 'HC-2026-0846',
      hiveId: 'Hive #07',
      quantity: '3.2 kg',
      floralSource: 'Mustard',
      origin: 'Satara, Maharashtra',
      coordinates: '17.6805° N, 73.9807° E',
      timestamp: '2026-09-06 14:22:11 UTC',
      transactionHash:
          '0xa4e92bf813d5c710ee3a7b4f8219c6d0e5f38b91c724d063e8f0b42a17c95d8e',
      purityIndex: 99.6,
      status: BatchStatus.verified,
    ),
    HoneyBatch(
      id: 'HC-2026-0845',
      hiveId: 'Hive #01',
      quantity: '4.8 kg',
      floralSource: 'Acacia',
      origin: 'Kodaikanal, Tamil Nadu',
      coordinates: '10.2381° N, 77.4892° E',
      timestamp: '2026-09-05 06:42:08 UTC',
      transactionHash:
          '0x3f8b17d2a094c6e51a823b9f04ed7c1502e6df98a4b0c31d27f5e8a9634b10c2',
      purityIndex: 99.9,
      status: BatchStatus.bottled,
    ),
  ];

  // ─── Traceability Nodes ───
  static const traceabilityNodes = [
    TraceabilityNode(
      title: 'Beekeeper Harvest',
      subtitle: 'Bharatpur Apiary Cluster',
      icon: Icons.grass_rounded,
      isCompleted: true,
      details: {
        'BEEKEEPER': 'Ramesh Kumar',
        'HIVE': 'Hive #03',
        'FLORAL SOURCE': 'Multifloral',
        'HARVEST DATE': '2026-09-07',
        'GPS': '27.1751° N, 78.0421° E',
      },
    ),
    TraceabilityNode(
      title: 'KVIC Lab Testing',
      subtitle: 'NABL Accredited Lab #MHL-2901',
      icon: Icons.science_outlined,
      isCompleted: true,
      details: {
        'MOISTURE': '17.1% (limit ≤ 20.0%)',
        'HMF LEVEL': '11.8 mg/kg (limit ≤ 80.0)',
        'POLLEN COUNT': '18,400 grains/g',
        'NMR PURITY': '100% authentic',
        'CERTIFICATE': 'NABL-CERT-9021',
      },
    ),
    TraceabilityNode(
      title: 'Processing & Bottling',
      subtitle: 'KVIC Processing Centre',
      icon: Icons.precision_manufacturing_outlined,
      isCompleted: true,
      details: {
        'THERMAL LOG': '45°C max (cold-extracted)',
        'BOTTLE SERIAL': 'BT-2026-08-00471',
        'BATCH SIZE': '5.0 kg → 10 × 500g jars',
        'PACKED DATE': '2026-09-08',
      },
    ),
    TraceabilityNode(
      title: 'Blockchain Minting',
      subtitle: 'Polygon Mainnet',
      icon: Icons.token_outlined,
      isCompleted: true,
      transactionHash:
          '0x71c8d4f209c3ae812db97a561a0c6ebd77f5a2f488b9e3d12a7c0e58b24f3a9f',
      details: {
        'NETWORK': 'Polygon Mainnet',
        'TOKEN': 'ERC-721 HoneyNFT',
        'TOKEN ID': '#4829',
        'GAS': '0.002 MATIC (₹0.04)',
        'BLOCK': '#5829104',
      },
    ),
    TraceabilityNode(
      title: 'Retail & Consumer',
      subtitle: 'Delivery & Verification',
      icon: Icons.storefront_outlined,
      isCompleted: true,
      details: {
        'STORE': 'KVIC Emporia, New Delhi',
        'SHELF DATE': '2026-09-09',
        'SCANS': '23 consumer verifications',
        'STATUS': 'Authentic & Active',
      },
    ),
  ];

  // ─── Lab Results ───
  static const labResults = [
    LabResult(
      metric: 'NMR PURITY',
      result: 'PASSED',
      detail: '100% authentic · 0% added syrup',
      passed: true,
    ),
    LabResult(
      metric: 'MOISTURE',
      result: '17.1%',
      detail: 'FSSAI limit: ≤ 20.0%',
      passed: true,
    ),
    LabResult(
      metric: 'HMF LEVEL',
      result: '11.8 mg/kg',
      detail: 'FSSAI limit: ≤ 80.0 mg/kg',
      passed: true,
    ),
    LabResult(
      metric: 'ANTIBIOTIC FREE',
      result: 'CLEAR',
      detail: 'Zero residue detected',
      passed: true,
    ),
    LabResult(
      metric: 'LAB CERTIFICATE',
      result: 'NABL-CERT-9021',
      detail: 'National Bee Board Accredited',
      passed: true,
    ),
  ];
}
