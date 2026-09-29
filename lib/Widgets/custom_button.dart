import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isDanger;
  final bool isOutlined;
  final double? width;
  final double height;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isDanger = false,
    this.isOutlined = false,
    this.width,
    this.height = 48,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color getBgColor() {
      if (isOutlined) return Colors.transparent;
      if (isDanger) return AppColors.danger;
      if (isSecondary) return AppColors.primary;
      return AppColors.accentPink; // Primary PennyPal action button color
    }

    Color getTextColor() {
      if (isOutlined) {
        if (isDanger) return AppColors.danger;
        if (isSecondary) return AppColors.primary;
        return AppColors.accentPink;
      }
      return Colors.white;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: getBgColor(),
          foregroundColor: getTextColor(),
          elevation: isOutlined ? 0 : 2,
          shadowColor: isOutlined
              ? Colors.transparent
              : (isSecondary ? AppColors.primary : AppColors.accentPink).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: isOutlined
                ? BorderSide(
                    color: isDanger
                        ? AppColors.danger
                        : (isSecondary ? AppColors.primary : AppColors.accentPink),
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
