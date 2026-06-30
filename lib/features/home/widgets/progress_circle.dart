import 'package:flutter/material.dart';
import 'package:listriq_app/core/prediction/prediction_service.dart';

/// Lingkaran progres untuk sisa kWh dan sisa hari.
class ProgressCircle extends StatelessWidget {
  final double remainingKWh;
  final int remainingDays;
  final UrgencyLevel urgency;

  const ProgressCircle({
    super.key,
    required this.remainingKWh,
    required this.remainingDays,
    required this.urgency,
  });

  Color get _color => switch (urgency) {
        UrgencyLevel.green => Colors.green,
        UrgencyLevel.yellow => Colors.orange,
        UrgencyLevel.red => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: (remainingDays / 30).clamp(0.0, 1.0),
              strokeWidth: 12,
              backgroundColor: _color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remainingKWh.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
              ),
              Text(
                'kWh',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '~$remainingDays hari',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
