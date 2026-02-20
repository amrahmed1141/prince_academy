// view/mma_booking/mma_booking_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/model/booking_model.dart';
import 'package:prince_academy/utils/constants/colors.dart';
import 'package:prince_academy/utils/helpers/helper_function.dart';
import 'package:prince_academy/view/booking_details/widgets/booking_summary.dart';
import 'package:prince_academy/view/booking_details/widgets/paymnet.dart';
import 'package:url_launcher/url_launcher.dart';

class MMABookingPage extends StatefulWidget {
  final MMABookingModel bookingInfo;

  const MMABookingPage({super.key, required this.bookingInfo});

  @override
  State<MMABookingPage> createState() => _MMABookingPageState();
}

class _MMABookingPageState extends State<MMABookingPage> {
  int _selectedSessions = 6;
  String _selectedDay = 'Monday';
  String _selectedTime = '7:00 AM';
  int _selectedPaymentMethod = 0;

  final List<String> _days = ['Monday', 'Wednesday', 'Friday', 'Saturday'];
  final List<String> _times = ['7:00 AM', '8:00 AM', '9:00 AM', '5:00 PM', '6:00 PM', '7:00 PM'];
  final List<int> _sessionOptions = [6, 8, 12];
  final List<String> _paymentMethods = ['Credit Card', 'PayPal', 'Google Pay'];

  double get totalPrice {
    return _selectedSessions * widget.bookingInfo.pricePerSession;
  }

  void _launchWhatsApp() async {
    final message = 'Hello, I would like to know more about your MMA classes';
    final url = 'https://wa.me/${widget.bookingInfo.coachWhatsapp}?text=${Uri.encodeFull(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  void _processPayment() {
    // Simulate payment processing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed'),
        content: Text('Your MMA class booking with ${widget.bookingInfo.coachName} has been confirmed!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MMA Class Booking'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.message),
            onPressed: _launchWhatsApp,
            tooltip: 'Chat with Coach',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        widget.bookingInfo.coachImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bookingInfo.coachName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MMA Coach',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Iconsax.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '4.9 (120 reviews)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Session Package Selection
            Text(
              'Training Package',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _sessionOptions.map((sessions) {
                final isSelected = _selectedSessions == sessions;
                return ChoiceChip(
                  label: Text('$sessions Sessions'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSessions = sessions;
                    });
                  },
                  selectedColor: EColorConstants.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Day Selection
            Text(
              'Training Days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final isSelected = _selectedDay == day;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? EColorConstants.primaryColor
                            : (dark ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Time Selection
            Text(
              'Training Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _times.map((time) {
                final isSelected = _selectedTime == time;
                return FilterChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
                  selectedColor: EColorConstants.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Booking Summary
            BookingSummary(
              sessions: _selectedSessions,
              day: _selectedDay,
              time: _selectedTime,
              pricePerSession: widget.bookingInfo.pricePerSession,
            ),
            const SizedBox(height: 24),

            // Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Column(
              children: _paymentMethods.asMap().entries.map((entry) {
                final index = entry.key;
                final method = entry.value;
                final isSelected = _selectedPaymentMethod == index;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected 
                      ? EColorConstants.primaryColor.withOpacity(0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? EColorConstants.primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      _getPaymentIcon(method),
                      color: isSelected ? EColorConstants.primaryColor : null,
                    ),
                    title: Text(
                      method,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? EColorConstants.primaryColor : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: EColorConstants.primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = index;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Payment Section
            PaymentSection(
              totalPrice: totalPrice,
              onPaymentPressed: _processPayment,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Credit Card':
        return Iconsax.card;
      case 'PayPal':
        return Iconsax.money;
      case 'Google Pay':
        return Iconsax.wallet;
      default:
        return Iconsax.card;
    }
  }
}