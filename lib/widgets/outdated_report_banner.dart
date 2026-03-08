import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/ui_constants.dart';

/// Banner shown when an AI report is outdated due to habit completion changes
/// 当 AI 报告因习惯完成状态变化而过时时显示的横幅
class OutdatedReportBanner extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isRefreshing;

  /// Creates an outdated report banner with refresh callback
  /// 创建带刷新回调的过时报告横幅
  const OutdatedReportBanner({
    super.key,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  /// Builds the warning banner with info icon, message, and refresh button
  /// 构建警告横幅，包含信息图标、消息和刷新按钮
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing12,
        vertical: UIConstants.spacing8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2000)
            : const Color(0xFFFFF8E1),
        borderRadius: UIConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark
              ? const Color(0xFF5C4800)
              : const Color(0xFFFFE082),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: UIConstants.iconMedium,
            color: isDark
                ? AppColors.darkGold
                : AppColors.lightOrange,
          ),
          const SizedBox(width: UIConstants.spacing8),
          Expanded(
            child: Text(
              'Analysis may be outdated',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkGold
                    : const Color(0xFF8D6E00),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: isRefreshing
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark
                          ? AppColors.darkGold
                          : AppColors.lightOrange,
                    ),
                  )
                : IconButton(
                    onPressed: onRefresh,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: UIConstants.iconMedium,
                      color: isDark
                          ? AppColors.darkGold
                          : AppColors.lightOrange,
                    ),
                    tooltip: 'Refresh analysis',
                  ),
          ),
        ],
      ),
    );
  }
}
