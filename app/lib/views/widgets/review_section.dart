import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/review_view_model.dart';

class ReviewSection extends StatefulWidget {
  final String productId;
  const ReviewSection({super.key, required this.productId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewViewModel(),
      child: Consumer<ReviewViewModel>(
        builder: (context, vm, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Leave a review', style: Theme.of(context).textTheme.titleMedium),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(labelText: 'Comment'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter a comment' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Rating:'),
                        Slider(
                          value: _rating.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _rating.toString(),
                          onChanged: (v) => setState(() => _rating = v.toInt()),
                        ),
                        Text('$_rating'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: vm.isSubmitting
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await vm.submitReview(
                                  productId: widget.productId,
                                  comment: _commentController.text,
                                  rating: _rating,
                                );
                                if (vm.error == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Review saved locally and will sync when online.')),
                                  );
                                  _commentController.clear();
                                  setState(() => _rating = 5);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${vm.error}')),
                                  );
                                }
                              }
                            },
                      child: vm.isSubmitting ? const CircularProgressIndicator() : const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
