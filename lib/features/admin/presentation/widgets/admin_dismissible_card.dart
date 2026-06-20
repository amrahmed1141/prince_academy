import 'package:flutter/material.dart';
import 'package:prince_academy/features/admin/presentation/widgets/delete_confirmation_sheet.dart';

class AdminDismissibleCard extends StatelessWidget {
  final Key dismissKey;
  final Widget child;
  final String confirmTitle;
  final String confirmSubtitle;
  final VoidCallback onDismissConfirmed;

  const AdminDismissibleCard({
    super.key,
    required this.dismissKey,
    required this.child,
    required this.confirmTitle,
    required this.confirmSubtitle,
    required this.onDismissConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) {
        return DeleteConfirmationSheet.show(
          context: context,
          title: confirmTitle,
          subtitle: confirmSubtitle,
        );
      },
      onDismissed: (_) => onDismissConfirmed(),
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade300, Colors.red.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}
