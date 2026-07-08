import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/payment_screenshot_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentScreenshotViewer {
  static Future<void> show(BuildContext context, String storedUrl) {
    if (storedUrl.trim().isEmpty) return Future.value();

    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              AppBar(
                title: const Text('Payment Screenshot'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<String>(
                  future: PaymentScreenshotHelper.resolveViewUrl(
                    sl<SupabaseClient>(),
                    storedUrl,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: EColorConstants.primaryColor,
                        ),
                      );
                    }

                    final url = snapshot.data;
                    if (url == null || url.isEmpty) {
                      return const Center(
                        child: Text('Unable to load screenshot'),
                      );
                    }

                    return InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: EColorConstants.primaryColor,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('Unable to load screenshot'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
