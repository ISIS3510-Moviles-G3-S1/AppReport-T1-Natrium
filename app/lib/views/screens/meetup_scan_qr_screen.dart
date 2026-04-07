import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../view_models/scan_qr_view_model.dart';
import '../../view_models/session_view_model.dart';

class MeetupScanQrScreen extends StatefulWidget {
  const MeetupScanQrScreen({super.key});

  @override
  State<MeetupScanQrScreen> createState() => _MeetupScanQrScreenState();
}

class _MeetupScanQrScreenState extends State<MeetupScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanQrViewModel(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Scan QR to Confirm Pickup')),
        body: Consumer2<ScanQrViewModel, SessionViewModel>(
          builder: (context, vm, session, _) {
            final currentUserId = session.currentUser?.uid;

            if (currentUserId == null || currentUserId.isEmpty) {
              return const Center(
                child: Text('You must be signed in to confirm a meetup.'),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Camera sensor is used here to read QR frames in real time.
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) async {
                          final barcode =
                              capture.barcodes.isNotEmpty
                                  ? capture.barcodes.first
                                  : null;
                          await vm.processScannedCode(
                            rawValue: barcode?.rawValue,
                            currentUserId: currentUserId,
                          );

                          if (vm.isConfirmed) {
                            await _scannerController.stop();
                          }
                        },
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            color: Colors.black87,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'Point your camera at the seller\'s meetup QR.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.isProcessing) const LinearProgressIndicator(),
                      if (vm.errorMessage != null)
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              vm.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ),
                      if (vm.successMessage != null)
                        Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              vm.successMessage!,
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          vm.resetForRescan();
                          await _scannerController.start();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
