import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/payout_service.dart';

enum PaymentMethodType {
  mpesa,
  tigopesa,
  airtelmoney,
  card,
  cash,
}

class PaymentResult {
  final bool isSuccess;
  final bool isPaid;
  final String paymentMethod;
  final String paymentReference;

  const PaymentResult({
    required this.isSuccess,
    required this.isPaid,
    required this.paymentMethod,
    required this.paymentReference,
  });
}

/// Interactive Test Payment Sheet (Sandbox Gateway Simulator).
/// Allows testing real-time Mobile Money and Card payment flows
/// without charging real money. Creates transaction records in Firestore.
class TestPaymentSheet extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;
  final String fishName;
  final VoidCallback onPaymentSuccess;

  const TestPaymentSheet({
    super.key,
    required this.orderId,
    required this.amount,
    required this.fishName,
    required this.onPaymentSuccess,
  });

  static Future<PaymentResult?> show({
    required BuildContext context,
    required String orderId,
    required double amount,
    required String fishName,
    required VoidCallback onPaymentSuccess,
  }) {
    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: TestPaymentSheet(
          orderId: orderId,
          amount: amount,
          fishName: fishName,
          onPaymentSuccess: onPaymentSuccess,
        ),
      ),
    );
  }

  @override
  ConsumerState<TestPaymentSheet> createState() => _TestPaymentSheetState();
}

class _TestPaymentSheetState extends ConsumerState<TestPaymentSheet> {
  PaymentMethodType _selectedMethod = PaymentMethodType.mpesa;
  late TextEditingController _phoneCtrl;
  late TextEditingController _pinCtrl;
  late TextEditingController _cardCtrl;

  bool _isProcessing = false;
  bool _showUssdSim = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '+255712345678');
    _pinCtrl = TextEditingController(text: '1234');
    _cardCtrl = TextEditingController(text: '4242 4242 4242 4242');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  String _getMethodName(PaymentMethodType method, AppLocalizations l10n) {
    switch (method) {
      case PaymentMethodType.mpesa:
        return 'Vodacom M-Pesa (Test Sandbox)';
      case PaymentMethodType.tigopesa:
        return 'Tigo Pesa (Test Sandbox)';
      case PaymentMethodType.airtelmoney:
        return 'Airtel Money (Test Sandbox)';
      case PaymentMethodType.card:
        return l10n.bankCardTest;
      case PaymentMethodType.cash:
        return l10n.cashOnDelivery;
    }
  }

  Future<void> _processPayment() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedMethod == PaymentMethodType.cash) {
      await _recordTransaction(
        paymentMethodName: 'Cash on Delivery',
        refNumber: 'CASH-PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      );
      return;
    }

    setState(() {
      _showUssdSim = true;
      _isProcessing = true;
    });

    // Simulate USSD Push Prompt delay (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final txnRef = '${_selectedMethod.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    await _recordTransaction(
      paymentMethodName: _getMethodName(_selectedMethod, l10n),
      refNumber: txnRef,
    );
  }

  Future<void> _recordTransaction({
    required String paymentMethodName,
    required String refNumber,
  }) async {
    try {
      final now = DateTime.now();
      final txnId = 'TXN-${now.millisecondsSinceEpoch}';

      // Create an initial HELD transaction record.
      // Commission amounts are NOT calculated here — they are calculated
      // server-side in PayoutService.confirmReceived() when the buyer
      // confirms receipt. We store zeros as placeholders.
      final txn = TransactionModel(
        transactionId: txnId,
        orderId: widget.orderId,
        finalAmount: widget.amount,
        sellerAmount: 0.0,   // set on buyer confirmation
        platformAmount: 0.0, // set on buyer confirmation
        paymentMethod: paymentMethodName,
        transactionReference: refNumber,
        status: 'held',      // HELD — not yet released to seller
        createdAt: now,
      );

      // Write the initial transaction record to Firestore.
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(txnId)
          .set(txn.toJson());

      final isPaid = _selectedMethod != PaymentMethodType.cash;

      // Update the order: mark as PAID (held state) if this is a real order.
      if (widget.orderId.isNotEmpty &&
          !widget.orderId.startsWith('TEMP-') &&
          !widget.orderId.startsWith('CART-')) {
        // Set the typed status to 'confirmed' (new held status) and payment info
        // via PayoutService if it's an electronic payment.
        if (isPaid) {
          final payoutSvc = PayoutService(FirebaseFirestore.instance);
          await payoutSvc.holdPayment(
            orderId: widget.orderId,
            totalAmount: widget.amount,
            paymentMethod: paymentMethodName,
            paymentReference: refNumber,
          );
        } else {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .set({
            'isPaid': false,
            'status': OrderStatus.confirmed.name,
            'paymentReference': refNumber,
            'paymentMethod': paymentMethodName,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }


      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      setState(() {
        _isProcessing = false;
        _showUssdSim = false;
      });

      // Notify caller.
      widget.onPaymentSuccess();

      final result = PaymentResult(
        isSuccess: true,
        isPaid: isPaid,
        paymentMethod: paymentMethodName,
        paymentReference: refNumber,
      );

      Navigator.pop(context, result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPaid
                      ? l10n.paymentHeldMessage(refNumber)
                      : l10n.orderReceivedCashMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: isPaid ? const Color(0xFF0369A1) : AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isProcessing = false;
        _showUssdSim = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentErrorPrefix(e.toString())),
          backgroundColor: const Color(0xFF075985),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header with Test Sandbox Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.payments_rounded, color: cs.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.testPaymentTitle,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'FREE TEST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.testPaymentSubtitle,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fishName,
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.orderId(widget.orderId.substring(0, widget.orderId.length > 8 ? 8 : widget.orderId.length)),
                            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      Text(
                        'TZS ${widget.amount.toStringAsFixed(0)}',
                        style: tt.titleLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method Selector
                Text(
                  l10n.selectPaymentMethod,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                _PaymentTile(
                  title: 'M-Pesa (Vodacom Test)',
                  subtitle: 'Simulate Mobile Money USSD Push',
                  icon: Icons.phone_android_rounded,
                  iconColor: cs.primary,
                  isSelected: _selectedMethod == PaymentMethodType.mpesa,
                  onTap: () => setState(() => _selectedMethod = PaymentMethodType.mpesa),
                ),
                const SizedBox(height: 8),

                _PaymentTile(
                  title: 'Tigo Pesa (Test)',
                  subtitle: 'Simulate Mobile Money USSD Push',
                  icon: Icons.phone_iphone_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  isSelected: _selectedMethod == PaymentMethodType.tigopesa,
                  onTap: () => setState(() => _selectedMethod = PaymentMethodType.tigopesa),
                ),
                const SizedBox(height: 8),

                _PaymentTile(
                  title: 'Airtel Money (Test)',
                  subtitle: 'Simulate Mobile Money USSD Push',
                  icon: Icons.mobile_friendly_rounded,
                  iconColor: const Color(0xFF0284C7),
                  isSelected: _selectedMethod == PaymentMethodType.airtelmoney,
                  onTap: () => setState(() => _selectedMethod = PaymentMethodType.airtelmoney),
                ),
                const SizedBox(height: 8),

                _PaymentTile(
                  title: l10n.bankCardTest,
                  subtitle: 'Simulate Card Payment Gateway',
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF0369A1),
                  isSelected: _selectedMethod == PaymentMethodType.card,
                  onTap: () => setState(() => _selectedMethod = PaymentMethodType.card),
                ),
                const SizedBox(height: 8),

                _PaymentTile(
                  title: l10n.cashOnDelivery,
                  subtitle: l10n.cashOnDeliverySubtitle,
                  icon: Icons.money_rounded,
                  iconColor: const Color(0xFF0D9488),
                  isSelected: _selectedMethod == PaymentMethodType.cash,
                  onTap: () => setState(() => _selectedMethod = PaymentMethodType.cash),
                ),
                const SizedBox(height: 20),

                // Form Fields according to selection
                if (_selectedMethod != PaymentMethodType.cash && _selectedMethod != PaymentMethodType.card) ...[
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.mobileNumberLabel,
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: l10n.testPinLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_selectedMethod == PaymentMethodType.card) ...[
                  TextField(
                    controller: _cardCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.testCardLabel,
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // USSD Simulation Overlay
                if (_showUssdSim) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '📲 SIM Push Notification (Simulated)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inathibitisha malipo ya TZS ${widget.amount.toStringAsFixed(0)} kwenda SamakiFresh Connect...',
                          style: tt.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pay Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processPayment,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.lock_clock_rounded, color: Colors.white),
                    label: Text(
                      _selectedMethod == PaymentMethodType.cash
                          ? l10n.placeOrderCash
                          : l10n.confirmTestPayment(widget.amount.toStringAsFixed(0)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
