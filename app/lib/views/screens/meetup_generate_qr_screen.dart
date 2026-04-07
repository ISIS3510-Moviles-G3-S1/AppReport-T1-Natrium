import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../view_models/generate_qr_view_model.dart';
import '../../view_models/session_view_model.dart';

class MeetupGenerateQrScreen extends StatefulWidget {
  const MeetupGenerateQrScreen({
    super.key,
    required this.listingId,
    required this.sellerId,
  });

  final String listingId;
  final String sellerId;

  @override
  State<MeetupGenerateQrScreen> createState() => _MeetupGenerateQrScreenState();
}

class _MeetupGenerateQrScreenState extends State<MeetupGenerateQrScreen> {
  final TextEditingController _buyerIdController = TextEditingController();

  @override
  void dispose() {
    _buyerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GenerateQrViewModel(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Generate Meetup QR')),
        body: Consumer2<GenerateQrViewModel, SessionViewModel>(
          builder: (context, vm, session, _) {
            final currentUserId = session.currentUser?.uid ?? '';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Create a pending meetup transaction and show this QR to the buyer at pickup.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _buyerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Buyer User ID',
                    helperText:
                        'Use the buyer\'s Firebase uid so only that buyer can confirm.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      vm.isLoading
                          ? null
                          : () {
                            vm.generateQrForListing(
                              listingId: widget.listingId,
                              sellerId: widget.sellerId,
                              buyerId: _buyerIdController.text.trim(),
                              currentUserId: currentUserId,
                            );
                          },
                  icon:
                      vm.isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.qr_code_2),
                  label: const Text('Generate QR Code'),
                ),
                const SizedBox(height: 16),
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
                if (vm.hasQrPayload && vm.qrPayload != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // This widget encodes meetup data in a visual QR image for camera scanning.
                          QrImageView(
                            data: vm.qrPayload!,
                            version: QrVersions.auto,
                            size: 240,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Transaction ID: ${vm.transaction?.transactionId ?? '-'}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
