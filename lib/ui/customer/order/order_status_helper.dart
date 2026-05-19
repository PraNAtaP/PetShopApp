import 'package:flutter/material.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

/// A single step definition for the StatusStepper widget.
class TrackingStep {
  final IconData icon;
  final String label;
  final String description;

  const TrackingStep({
    required this.icon,
    required this.label,
    required this.description,
  });
}

/// A premium vertical stepper widget that visually tracks order/booking progress.
class StatusStepper extends StatelessWidget {
  final List<TrackingStep> steps;
  final int currentStep;
  final bool isCancelled;

  const StatusStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = !isCancelled && index < currentStep;
        final isActive = !isCancelled && index == currentStep;
        final isPending = !isCancelled && index > currentStep;
        final isLast = index == steps.length - 1;

        Color circleColor;
        Color lineColor;
        Color textColor;

        if (isCancelled) {
          circleColor = Colors.grey.shade300;
          lineColor = Colors.grey.shade200;
          textColor = Colors.grey.shade400;
        } else if (isCompleted) {
          circleColor = const Color(0xFF2E7D32);
          lineColor = const Color(0xFF2E7D32);
          textColor = Colors.black87;
        } else if (isActive) {
          circleColor = AppColors.primary;
          lineColor = Colors.grey.shade200;
          textColor = AppColors.primary;
        } else {
          circleColor = Colors.grey.shade300;
          lineColor = Colors.grey.shade200;
          textColor = Colors.grey.shade400;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle + Line column
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: isActive ? 40 : 32,
                    height: isActive ? 40 : 32,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? circleColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: circleColor,
                        width: isActive ? 3 : 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: circleColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step.icon,
                      color: isCompleted || isActive
                          ? Colors.white
                          : circleColor,
                      size: isActive ? 20 : 16,
                    ),
                  ),
                  // Line
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 3,
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF2E7D32)
                            : lineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Text column
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: isActive ? 4 : 2,
                  bottom: isLast ? 0 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontWeight: isActive || isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: isActive ? 15 : 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPending
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// A banner widget that shows when a cancellation request is pending.
class CancelRequestBanner extends StatelessWidget {
  const CancelRequestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan Pembatalan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pembatalan Anda sedang ditinjau oleh Admin.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A banner widget for cancelled status
class CancelledBanner extends StatelessWidget {
  const CancelledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pesanan ini telah dibatalkan.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
