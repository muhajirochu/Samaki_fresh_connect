import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../models/enums/payment_status.dart';
import '../../models/order_model.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../utils/route_format.dart';
import '../../widgets/timelines/horizontal_order_timeline.dart';

class BuyerTrackOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const BuyerTrackOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<BuyerTrackOrderScreen> createState() => _BuyerTrackOrderScreenState();
}

class _BuyerTrackOrderScreenState extends ConsumerState<BuyerTrackOrderScreen> {
  bool _isSubmitting = false;
  final TextEditingController _commentCtrl = TextEditingController();
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _selectedImage = file;
      _uploadedImageUrl = null;
    });

    setState(() => _isUploadingImage = true);
    try {
      final svc = CloudinaryService();
      final url = await svc.uploadImage(file, folder: 'order_feedback');
      if (mounted) setState(() => _uploadedImageUrl = url);
    } catch (_) {
      if (mounted) setState(() => _uploadedImageUrl = null);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _selectedImage = file;
      _uploadedImageUrl = null;
    });

    setState(() => _isUploadingImage = true);
    try {
      final svc = CloudinaryService();
      final url = await svc.uploadImage(file, folder: 'order_feedback');
      if (mounted) setState(() => _uploadedImageUrl = url);
    } catch (_) {
      if (mounted) setState(() => _uploadedImageUrl = null);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.trackOrder,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001E45))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF001E45)),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return Center(child: Text(l10n.orderNotFound));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatusHeader(order, cs),
                const SizedBox(height: 16),
                _buildPaymentStateBanner(order, cs),
                const SizedBox(height: 16),
                _buildMapCard(order, cs),
                const SizedBox(height: 28),
                HorizontalOrderTimeline(currentStatus: order.status),
                const SizedBox(height: 28),
                _buildETASection(order, cs),
                const SizedBox(height: 20),
                _buildContactButton(cs),
                const SizedBox(height: 20),
                _buildFeedbackSection(order, cs),
                if (order.buyerConfirmed) _buildCompletionSummary(order, cs),
                if (order.isDisputed) _buildDisputedBanner(order, cs),
                if (order.paymentStatus == PaymentStatus.refunded) _buildRefundedCard(order, cs),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text("${AppLocalizations.of(context).errorLoadingOrder}: ${e.toString()}"),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order, ColorScheme cs) {
    String statusText;
    Color iconBg;
    IconData icon;

    if (order.paymentStatus == PaymentStatus.refunded) {
      statusText = 'Order Refunded 💸';
      iconBg = const Color(0xFF0284C7);
      icon = Icons.assignment_return_rounded;
    } else if (order.isDisputed) {
      statusText = '⚠️ Order Disputed — Pending Admin Review';
      iconBg = const Color(0xFFD97706);
      icon = Icons.report_problem_rounded;
    } else if (order.buyerConfirmed) {
      statusText = 'Order Completed ✅';
      iconBg = Colors.green;
      icon = Icons.verified_rounded;
    } else if (order.status == OrderStatus.completed) {
      statusText = 'Delivered — Leave Your Feedback';
      iconBg = const Color(0xFF0369A1);
      icon = Icons.rate_review_rounded;
    } else if (order.status == OrderStatus.outForDelivery) {
      statusText = 'On the Way 🚴';
      iconBg = cs.primary;
      icon = Icons.directions_bike;
    } else if (order.status == OrderStatus.confirmed) {
      statusText = '🔒 Payment Held';
      iconBg = const Color(0xFF0369A1);
      icon = Icons.lock_rounded;
    } else if (order.status == OrderStatus.preparing) {
      statusText = 'Preparing Fish 🐟';
      iconBg = cs.primary;
      icon = Icons.restaurant_menu;
    } else if (order.status == OrderStatus.cancelled) {
      statusText = 'Order Cancelled';
      iconBg = Colors.red;
      icon = Icons.cancel_rounded;
    } else {
      statusText = 'Awaiting Acceptance...';
      iconBg = Colors.grey;
      icon = Icons.hourglass_empty;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: iconBg.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text(statusText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001E45)),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'Order #${order.orderId.substring(0, order.orderId.length > 8 ? 8 : order.orderId.length).toUpperCase()}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPaymentStateBanner(OrderModel order, ColorScheme cs) {
    if (order.isDisputed) return const SizedBox.shrink();

    if (order.paymentStatus == PaymentStatus.refunded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment_return_rounded, color: Color(0xFF0369A1), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).trackPaymentRefunded,
                      style: const TextStyle(color: Color(0xFF075985), fontWeight: FontWeight.w800, fontSize: 13)),
                  SizedBox(height: 4),
                  Text(
                    'Your dispute was approved. Full order amount has been refunded back to your account.',
                    style: TextStyle(color: Color(0xFF075985), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (order.isPaid && order.paymentStatus == PaymentStatus.held) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_clock, color: Color(0xFFD97706), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).trackPaymentHeld,
                      style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w800, fontSize: 13)),
                  SizedBox(height: 4),
                  Text(
                    'Payment will be released to the seller only after you confirm receiving your fish.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (order.paymentStatus == PaymentStatus.released) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_open_rounded, color: Color(0xFF15803D), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(AppLocalizations.of(context).trackPaymentReleased,
                  style: const TextStyle(color: Color(0xFF14532D), fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFeedbackSection(OrderModel order, ColorScheme cs) {
    final canFeedback = !order.buyerConfirmed &&
        !order.isDisputed &&
        order.paymentStatus != PaymentStatus.refunded &&
        order.isPaid &&
        (order.status == OrderStatus.outForDelivery ||
            order.status == OrderStatus.readyForPickup ||
            order.status == OrderStatus.completed);

    if (!canFeedback) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review_rounded, color: Color(0xFF0369A1), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Did You Receive Your Order?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF001E45)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Provide feedback and upload proof photos if you wish, then confirm receipt or report an issue.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),

          Text(AppLocalizations.of(context).trackCommentsOptional,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'e.g. Fresh fish, excellent quality...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          Text(AppLocalizations.of(context).trackProofPhotoOptional,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
          const SizedBox(height: 10),

          if (_selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                if (_isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            const SizedBox(height: 8),
                            Text(AppLocalizations.of(context).trackUploadingPhoto, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_uploadedImageUrl != null && !_isUploadingImage)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Color(0xFF15803D),
                      radius: 14,
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedImage = null;
                      _uploadedImageUrl = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _photoButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    onTap: _takePicture,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _photoButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose Photo',
                    onTap: _pickImage,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          const Text(
            'Confirm your order status:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (_isSubmitting || _isUploadingImage)
                  ? null
                  : () => _submitConfirm(order, cs),
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(AppLocalizations.of(context).trackReceivedFishCorrect,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.green.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: (_isSubmitting || _isUploadingImage)
                  ? null
                  : () => _submitDispute(order, cs),
              icon: const Icon(Icons.report_problem_rounded, color: Color(0xFFD97706)),
              label: Text(AppLocalizations.of(context).trackIncorrectOrderReport,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF92400E))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFDE68A), width: 2),
                backgroundColor: const Color(0xFFFFFBEB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Center(
            child: Text(
              'A proof photo helps resolve issues quickly if you report a problem.',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF0284C7), size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitConfirm(OrderModel order, ColorScheme cs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF15803D)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).trackConfirmReceipt),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).trackConfirmReceiptMsg),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                '⚠️ Once confirmed, payment will be released to the seller and cannot be reversed.',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).trackNoGoBack),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context).trackYesIConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(orderTrackingProvider);
      final success = await notifier.confirmBuyerReceived(
        order,
        buyerComment: _commentCtrl.text.trim(),
        buyerFeedbackImageUrl: _uploadedImageUrl ?? '',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(AppLocalizations.of(context).trackOrderCompletedMsg)),
              ],
            ),
            backgroundColor: Color(0xFF15803D),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).trackErrorOccurred), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitDispute(OrderModel order, ColorScheme cs) async {
    if (_commentCtrl.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).trackProvideCommentOrPhoto),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.report_problem_rounded, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).trackReportIssueTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).trackSureOrderIncorrect),
            SizedBox(height: 8),
            Text(
              'Your report will be sent to the administrator. Payment will remain held until resolved.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).trackNoGoBack),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context).trackYesReportIssue),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(orderTrackingProvider);
      final success = await notifier.flagDispute(
        order,
        buyerComment: _commentCtrl.text.trim(),
        buyerFeedbackImageUrl: _uploadedImageUrl ?? '',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.report_problem_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(AppLocalizations.of(context).trackIssueReportedMsg)),
              ],
            ),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).trackErrorOccurred), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildCompletionSummary(OrderModel order, ColorScheme cs) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).trackOrderCompletedTitle,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _summaryRow('Order Total:', 'TZS ${order.totalPrice.toStringAsFixed(0)}', Colors.white),
                const SizedBox(height: 6),
                _summaryRow('Platform Commission (5%):', 'TZS ${order.commissionAmount.toStringAsFixed(0)}', Colors.white70),
                const Divider(color: Colors.white30, height: 16),
                _summaryRow('Seller Received (95%):', 'TZS ${order.sellerEarnings.toStringAsFixed(0)}', const Color(0xFF86EFAC)),
              ],
            ),
          ),
          if (order.buyerComment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"${order.buyerComment}"',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
          if (order.buyerFeedbackImageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(order.buyerFeedbackImageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).trackThankYouUsing,
              style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDisputedBanner(OrderModel order, ColorScheme cs) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          const Icon(Icons.report_problem_rounded, color: Colors.white, size: 44),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context).trackIssueReportedTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).trackReportReceivedMsg,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
          if (order.buyerComment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"${order.buyerComment}"',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
          if (order.buyerFeedbackImageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(order.buyerFeedbackImageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefundedCard(OrderModel order, ColorScheme cs) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 44),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context).trackFullRefundIssued,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).trackRefundedToAccount(order.totalPrice.toStringAsFixed(0)),
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          if (order.buyerComment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"${order.buyerComment}"',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
          if (order.buyerFeedbackImageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(order.buyerFeedbackImageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildMapCard(OrderModel order, ColorScheme cs) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildMapContent(order, cs),
      ),
    );
  }

  Widget _buildMapContent(OrderModel order, ColorScheme cs) {
    ll.LatLng buyerLatLng;
    if (order.buyerLocation != null) {
      buyerLatLng = ll.LatLng(order.buyerLocation!.latitude, order.buyerLocation!.longitude);
    } else {
      final loc = ref.watch(currentBuyerLocationProvider).valueOrNull;
      buyerLatLng = loc != null ? ll.LatLng(loc.latitude, loc.longitude) : const ll.LatLng(-6.1629, 39.2026);
    }

    ll.LatLng sellerLatLng;
    if (order.streetSellerLocation != null) {
      sellerLatLng = ll.LatLng(order.streetSellerLocation!.latitude, order.streetSellerLocation!.longitude);
    } else {
      final sellers = ref.watch(activeStreetSellersProvider).valueOrNull ?? const [];
      final match = sellers.where((s) => s.sellerId == order.streetSellerId).firstOrNull;
      if (match != null && (match.latitude != 0 || match.longitude != 0)) {
        sellerLatLng = ll.LatLng(match.latitude, match.longitude);
      } else {
        sellerLatLng = const ll.LatLng(-6.1645, 39.2040);
      }
    }

    final routeAsync = ref.watch(trackingRouteProvider(widget.orderId));
    final routeResult = routeAsync.valueOrNull;
    final isOsrm = routeResult != null && routeResult.points.length > 1 && routeResult.source == RouteSource.osrm;
    final polylinePoints = isOsrm ? routeResult.points : <ll.LatLng>[sellerLatLng, buyerLatLng];

    final center = ll.LatLng(
      (buyerLatLng.latitude + sellerLatLng.latitude) / 2,
      (buyerLatLng.longitude + sellerLatLng.longitude) / 2,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.samakifresh.connect', maxZoom: 19),
        PolylineLayer(polylines: [
          Polyline(
            points: polylinePoints,
            strokeWidth: 5,
            color: const Color(0xFF0284C7),
            pattern: isOsrm ? const StrokePattern.solid() : const StrokePattern.dotted(),
            borderColor: Colors.white,
            borderStrokeWidth: 2,
          ),
        ]),
        MarkerLayer(markers: [
          Marker(
            point: buyerLatLng, width: 44, height: 44,
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF075985), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
          Marker(
            point: sellerLatLng, width: 44, height: 44,
            child: Container(
              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
              child: const Icon(Icons.directions_bike, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildETASection(OrderModel order, ColorScheme cs) {
    final routeAsync = ref.watch(trackingRouteProvider(widget.orderId));
    final route = routeAsync.valueOrNull;

    String etaText() {
      if (order.paymentStatus == PaymentStatus.refunded) return 'Refunded 💸';
      if (order.buyerConfirmed) return 'Delivered ✅';
      if (order.isDisputed) return 'Disputed ⚠️';
      if (order.status == OrderStatus.completed) return 'Arrived — Awaiting Feedback';
      if (order.status == OrderStatus.cancelled) return 'Cancelled';
      if (route != null) return formatRouteEta(route.durationMinutes);
      return 'Calculating...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 24),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context).trackETA, style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(etaText(), style: TextStyle(color: cs.primary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContactButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.phone, color: cs.primary),
        label: Text(AppLocalizations.of(context).trackContactSeller, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
