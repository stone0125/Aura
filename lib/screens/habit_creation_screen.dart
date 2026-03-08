import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_form_data.dart';
import '../models/ai_coach_models.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_coach_provider.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/ui_constants.dart';
import '../config/habit_icons.dart';
import '../services/notification_service.dart';

/// Habit Creation Screen for creating or editing habits
/// 用于创建或编辑习惯的习惯创建屏幕
class HabitCreationScreen extends StatefulWidget {
  /// Live AI Coach suggestion from Cloud Functions
  /// 来自Cloud Functions的实时AI教练建议
  final AICoachSuggestion? aiCoachSuggestion;

  /// Existing habit to edit (null = create mode)
  /// 要编辑的现有习惯（null表示创建模式）
  final Habit? habitToEdit;

  /// Creates the habit creation/editing screen
  /// 创建习惯创建/编辑屏幕
  const HabitCreationScreen({super.key, this.aiCoachSuggestion, this.habitToEdit});

  /// Whether the screen is in editing mode
  /// 屏幕是否处于编辑模式
  bool get isEditing => habitToEdit != null;

  /// Creates the mutable state for the habit creation screen
  /// 创建习惯创建屏幕的可变状态
  @override
  State<HabitCreationScreen> createState() => _HabitCreationScreenState();
}

class _HabitCreationScreenState extends State<HabitCreationScreen> {
  late HabitFormData _formData;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  String? _nameError;
  String? _categoryError;
  String? _frequencyError;

  /// Initializes the form and sets up name change listener
  /// 初始化表单并设置名称变更监听器
  @override
  void initState() {
    super.initState();
    _initializeForm();
    _nameController.addListener(_onNameChanged);
  }

  /// Initializes form data from AI suggestion or existing habit
  /// 从AI建议或现有习惯初始化表单数据
  void _initializeForm() {
    _formData = HabitFormData();

    // Pre-fill from existing habit when editing
    if (widget.habitToEdit != null) {
      final habit = widget.habitToEdit!;
      _formData.name = habit.name;
      _formData.category = habit.category;
      _formData.selectedIcon = HabitIcons.getDefaultIconForCategory(
        habit.category.name,
      );
      _formData.reminderEnabled = habit.reminderEnabled;
      if (habit.reminderTime != null) {
        _formData.reminderTime = habit.reminderTime!;
      }

      // Pre-fill goal fields
      switch (habit.goalType) {
        case 'time':
          _formData.goalType = GoalType.time;
        case 'count':
          _formData.goalType = GoalType.count;
        default:
          _formData.goalType = GoalType.none;
      }
      _formData.goalValue = habit.goalValue;
      _formData.goalUnit = habit.goalUnit;

      _nameController.text = habit.name;
    } else if (widget.aiCoachSuggestion != null) {
      // Pre-fill from AI suggestion if provided
      final suggestion = widget.aiCoachSuggestion!;
      _formData.name = suggestion.title;
      _formData.description = suggestion.description;
      _formData.category = suggestion.category;
      _formData.selectedIcon = HabitIcons.getDefaultIconForCategory(
        suggestion.category.name,
      );
      _formData.aiOptimizedTiming = true;
      _formData.isAISuggested = true;

      // Prefill frequency
      if (suggestion.frequencyType == 'weekly') {
        _formData.frequencyType = FrequencyType.weekly;
        if (suggestion.weeklyDays != null && suggestion.weeklyDays!.isNotEmpty) {
          _formData.weeklyDays = List<int>.from(suggestion.weeklyDays!);
        }
      } else {
        _formData.frequencyType = FrequencyType.daily;
      }

      // Prefill goal
      switch (suggestion.goalType) {
        case 'time':
          _formData.goalType = GoalType.time;
        case 'count':
          _formData.goalType = GoalType.count;
        default:
          _formData.goalType = GoalType.none;
      }
      if (suggestion.goalValue != null) {
        _formData.goalValue = suggestion.goalValue;
      }
      if (suggestion.goalUnit != null) {
        _formData.goalUnit = suggestion.goalUnit;
      }

      // Prefill reminder if AI suggested one
      if (suggestion.suggestedReminderHour != null) {
        _formData.reminderEnabled = true;
        _formData.reminderTime = TimeOfDay(
          hour: suggestion.suggestedReminderHour!,
          minute: suggestion.suggestedReminderMinute ?? 0,
        );
      }

      _nameController.text = suggestion.title;
      _descriptionController.text = suggestion.description;
    } else {
      // Default icon
      _formData.selectedIcon = HabitIcons.icons.first.icon;
    }
  }

  /// Clears name error when user types in the name field
  /// 当用户在名称字段中输入时清除名称错误
  void _onNameChanged() {
    setState(() {
      _formData.name = _nameController.text;
      if (_nameError != null) {
        _validateName();
      }
    });
  }

  /// Validates the habit name is not empty
  /// 验证习惯名称不为空
  bool _validateName() {
    if (_formData.name.isEmpty) {
      setState(() => _nameError = 'Habit name is required');
      return false;
    }
    if (_formData.name.length > 50) {
      setState(() => _nameError = 'Name is too long (max 50 characters)');
      return false;
    }
    setState(() => _nameError = null);
    return true;
  }

  /// Validates that a category has been selected
  /// 验证是否已选择类别
  bool _validateCategory() {
    if (_formData.category == null) {
      setState(() => _categoryError = 'Please select a category');
      return false;
    }
    setState(() => _categoryError = null);
    return true;
  }

  /// Validates that weekly frequency has at least one day selected
  /// 验证每周频率是否至少选择了一天
  bool _validateFrequency() {
    if (_formData.frequencyType == FrequencyType.weekly &&
        _formData.weeklyDays.isEmpty) {
      setState(() => _frequencyError = 'Please select at least one day');
      return false;
    }
    setState(() => _frequencyError = null);
    return true;
  }

  /// Validates the entire form and scrolls to the first error
  /// 验证整个表单并滚动到第一个错误位置
  bool _validateForm() {
    final nameValid = _validateName();
    final categoryValid = _validateCategory();
    final frequencyValid = _validateFrequency();

    return nameValid && categoryValid && frequencyValid;
  }

  /// Saves the habit (creates new or updates existing) to the provider
  /// 将习惯保存（创建新的或更新现有的）到提供者
  Future<void> _saveHabit() async {
    if (!_validateForm()) {
      // Shake animation would go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Store provider references BEFORE any async operations
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final aiCoachProvider = Provider.of<AICoachProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isEditing = widget.isEditing;

    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      if (isEditing) {
        // Update existing habit, preserving streak and completion state
        final existingHabit = widget.habitToEdit!;
        final updatedHabit = existingHabit.copyWith(
          name: _formData.name,
          category: _formData.category!,
          goalType: _formData.goalType.name,
          goalValue: _formData.goalType != GoalType.none ? _formData.goalValue : null,
          goalUnit: _formData.goalType != GoalType.none ? _formData.goalUnit : null,
          clearGoal: _formData.goalType == GoalType.none,
          reminderEnabled: _formData.reminderEnabled,
          reminderTime: _formData.reminderEnabled ? _formData.reminderTime : null,
        );

        await habitProvider.updateHabit(updatedHabit);
        if (!mounted) return;

        // Handle notification rescheduling
        if (_formData.reminderEnabled) {
          await NotificationService().scheduleHabitReminder(
            habitId: updatedHabit.id,
            habitName: updatedHabit.name,
            hour: _formData.reminderTime.hour,
            minute: _formData.reminderTime.minute,
          );
        } else {
          await NotificationService().cancelHabitReminder(updatedHabit.id);
        }
        if (!mounted) return;
      } else {
        // Create new habit with reminder settings
        // Use timestamp + random component to avoid ID collision
        final habit = Habit(
          id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}',
          name: _formData.name,
          category: _formData.category!,
          streak: 0,
          isCompleted: false,
          goalType: _formData.goalType.name,
          goalValue: _formData.goalType != GoalType.none ? _formData.goalValue : null,
          goalUnit: _formData.goalType != GoalType.none ? _formData.goalUnit : null,
          reminderEnabled: _formData.reminderEnabled,
          reminderTime: _formData.reminderEnabled ? _formData.reminderTime : null,
        );

        await habitProvider.addHabit(habit);
        if (!mounted) return;

        // Clear AI suggestions cache so new suggestions are personalized
        aiCoachProvider.clearSuggestionsCache();

        // Schedule notification if reminder is enabled
        if (_formData.reminderEnabled) {
          await NotificationService().scheduleHabitReminder(
            habitId: habit.id,
            habitName: habit.name,
            hour: _formData.reminderTime.hour,
            minute: _formData.reminderTime.minute,
          );
          if (!mounted) return;
        }
      }

      // Success feedback
      HapticFeedback.mediumImpact();

      // Close screen
      navigator.pop();

      // Show success message
      final message = isEditing
          ? 'Habit updated!'
          : (_formData.reminderEnabled ? 'Habit created with reminder!' : 'Habit created!');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to ${isEditing ? 'update' : 'create'} habit: $e'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Shows confirmation dialog when user tries to leave with unsaved changes
  /// 当用户尝试带有未保存更改离开时显示确认对话框
  Future<bool> _onWillPop() async {
    // Check if form has content
    if (_formData.name.isNotEmpty || _formData.description.isNotEmpty) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(widget.isEditing ? 'Discard changes?' : 'Discard habit?'),
          content: const Text('Your changes will be lost'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  /// Disposes controllers and scroll controller
  /// 释放控制器和滚动控制器
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  /// Builds the habit creation/editing form UI
  /// 构建习惯创建/编辑表单界面
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: _buildAppBar(isDark),
        body: Stack(
          children: [
            // Scrollable form content
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 104), // Space for button
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AI Pre-fill Banner (if from AI)
                  if (_formData.isAISuggested) _buildAIBanner(isDark),

                  // Basic Information Section
                  _buildBasicInfoSection(isDark),
                  const SizedBox(height: 12),

                  // Category Selection
                  _buildCategorySection(isDark),
                  const SizedBox(height: 12),

                  // Icon Selection
                  _buildIconSection(isDark),
                  const SizedBox(height: 12),

                  // Frequency Section
                  _buildFrequencySection(isDark),
                  const SizedBox(height: 12),

                  // Goal Section (Optional)
                  _buildGoalSection(isDark),
                  const SizedBox(height: 12),

                  // Reminders & AI
                  _buildRemindersSection(isDark),
                ],
              ),
            ),

            // Bottom action button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomActionButton(isDark),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.close_rounded,
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
        ),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        widget.isEditing
            ? 'Edit Habit'
            : (_formData.isAISuggested ? 'Add AI Suggestion' : 'Create Habit'),
        style: TextStyle(
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
          fontSize: UIConstants.appBarTitleSize,
          fontWeight: UIConstants.appBarTitleWeight,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.check_rounded,
            color: _formData.isValid
                ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                : (isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText),
          ),
          onPressed: _formData.isValid ? _saveHabit : null,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }

  /// Builds the AI suggestion banner shown when pre-filling from AI
  /// 构建从AI预填充时显示的AI建议横幅
  Widget _buildAIBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkCoral.withValues(alpha: 0.2),
                  AppColors.darkPink.withValues(alpha: 0.15),
                ]
              : [
                  AppColors.lightCoral.withValues(alpha: 0.1),
                  AppColors.lightPink.withValues(alpha: 0.1),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pre-filled by AI Coach',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Can edit AI suggestions
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Edit',
              style: TextStyle(
                color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the basic info section with name and description fields
  /// 构建带有名称和描述字段的基本信息部分
  Widget _buildBasicInfoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Habit Name
          RichText(
            text: TextSpan(
              text: 'Habit Name',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: 50,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Morning meditation',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurface,
              border: OutlineInputBorder(
                borderRadius: UIConstants.borderRadiusMedium,
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: UIConstants.borderRadiusMedium,
                borderSide: BorderSide(
                  color: _nameError != null
                      ? (isDark ? AppColors.darkRed : AppColors.red)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: UIConstants.borderRadiusMedium,
                borderSide: BorderSide(
                  color: _nameError != null
                      ? (isDark ? AppColors.darkRed : AppColors.red)
                      : (isDark ? AppColors.darkCoral : AppColors.lightCoral),
                  width: 2,
                ),
              ),
              counterText: '',
            ),
          ),
          // Character counter
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_formData.nameCharCount}/50',
                style: TextStyle(
                  color: _formData.nameExceedsLimit
                      ? AppColors.red
                      : _formData.nameNearLimit
                      ? AppColors.orange
                      : (isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          if (_nameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _nameError!,
                style: TextStyle(
                  color: isDark ? AppColors.darkRed : AppColors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Description (Optional)
          Text(
            'Description or Motivation (Optional)',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLength: 200,
            maxLines: 3,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Add notes or motivation to help you stay committed...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurface,
              border: OutlineInputBorder(
                borderRadius: UIConstants.borderRadiusMedium,
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: UIConstants.borderRadiusMedium,
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: UIConstants.borderRadiusMedium,
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkCoral : AppColors.lightCoral,
                  width: 2,
                ),
              ),
              counterText: '',
            ),
            onChanged: (value) {
              setState(() => _formData.description = value);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_formData.description.length}/200',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the category selection grid
  /// 构建类别选择网格
  Widget _buildCategorySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Category',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HabitCategory.values.map((category) {
                final isSelected = _formData.category == category;
                final gradientColors = category.getGradient(
                  isDark ? Brightness.dark : Brightness.light,
                );

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _formData.category = category;
                          _formData.selectedIcon =
                              HabitIcons.getDefaultIconForCategory(
                                category.name,
                              );
                          _categoryError = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? gradientColors[0]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 18,
                              color: isSelected
                                  ? (isDark
                                        ? AppColors.darkBackground
                                        : Colors.white)
                                  : (isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark
                                          ? AppColors.darkBackground
                                          : Colors.white)
                                    : (isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightPrimaryText),
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_categoryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _categoryError!,
                style: TextStyle(
                  color: isDark ? AppColors.darkRed : AppColors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the icon selection section for the habit
  /// 构建习惯的图标选择部分
  Widget _buildIconSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Icon',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: EdgeInsets.zero,
            children: HabitIcons.icons.map((iconData) {
              final isSelected = _formData.selectedIcon == iconData.icon;
              final categoryColor =
                  _formData.category?.getGradient(
                    isDark ? Brightness.dark : Brightness.light,
                  )[0] ??
                  (isDark ? AppColors.darkCoral : AppColors.lightCoral);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _formData.selectedIcon = iconData.icon);
                  },
                  borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? categoryColor
                          : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightBorder.withValues(alpha: 0.3)),
                      border: isSelected
                          ? Border.all(color: categoryColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      iconData.icon,
                      size: 24,
                      color: isSelected
                          ? (isDark ? AppColors.darkBackground : Colors.white)
                          : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds the frequency selection section (daily/weekly)
  /// 构建频率选择部分（每日/每周）
  Widget _buildFrequencySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequency',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Segmented control
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightBorder.withValues(alpha: 0.3),
              borderRadius: UIConstants.borderRadiusMedium,
              border: isDark
                  ? Border.all(color: AppColors.darkBorder, width: 1)
                  : null,
            ),
            child: Row(
              children: FrequencyType.values.map((type) {
                final isSelected = _formData.frequencyType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _formData.frequencyType = type;
                        _frequencyError = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightSurface)
                            : Colors.transparent,
                        borderRadius: UIConstants.borderRadiusMedium,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          type.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? (isDark
                                      ? AppColors.darkCoral
                                      : AppColors.lightCoral)
                                : (isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightPrimaryText),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Frequency details based on type
          if (_formData.frequencyType == FrequencyType.daily)
            Text(
              'Repeat every day',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontSize: 15,
              ),
            ),

          if (_formData.frequencyType == FrequencyType.weekly) ...[
            Text(
              'Select days',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final dayIndex = (index + 1) % 7; // Monday = 1, Sunday = 0
                final isSelected = _formData.weeklyDays.contains(dayIndex);
                final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isSelected) {
                        _formData.weeklyDays.remove(dayIndex);
                      } else {
                        _formData.weeklyDays.add(dayIndex);
                      }
                      _frequencyError = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? (isDark
                                ? AppColors.darkCoral
                                : AppColors.lightCoral)
                          : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightBorder.withValues(alpha: 0.3)),
                      border: !isSelected
                          ? Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 1,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[index],
                        style: TextStyle(
                          color: isSelected
                              ? (isDark
                                    ? AppColors.darkBackground
                                    : Colors.white)
                              : (isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightPrimaryText),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_frequencyError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _frequencyError!,
                  style: TextStyle(
                    color: isDark ? AppColors.darkRed : AppColors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Builds the goal configuration section (duration, count, distance)
  /// 构建目标配置部分（时长、次数、距离）
  Widget _buildGoalSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal (Optional)',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Segmented control: None / Time / Count
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightBorder.withValues(alpha: 0.3),
              borderRadius: UIConstants.borderRadiusMedium,
              border: isDark
                  ? Border.all(color: AppColors.darkBorder, width: 1)
                  : null,
            ),
            child: Row(
              children: GoalType.values.map((type) {
                final isSelected = _formData.goalType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _formData.goalType = type;
                        if (type == GoalType.none) {
                          _formData.goalValue = null;
                          _formData.goalUnit = null;
                        } else if (type == GoalType.time) {
                          _formData.goalUnit ??= 'minutes';
                        } else if (type == GoalType.count) {
                          _formData.goalValue ??= 1;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightSurface)
                            : Colors.transparent,
                        borderRadius: UIConstants.borderRadiusMedium,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          type == GoalType.none
                              ? 'None'
                              : type == GoalType.time
                                  ? 'Time'
                                  : 'Count',
                          style: TextStyle(
                            color: isSelected
                                ? (isDark
                                      ? AppColors.darkCoral
                                      : AppColors.lightCoral)
                                : (isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightPrimaryText),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Time goal inputs
          if (_formData.goalType == GoalType.time) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                // Value field
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: TextEditingController(
                      text: _formData.goalValue?.toString() ?? '',
                    )..selection = TextSelection.collapsed(
                        offset: (_formData.goalValue?.toString() ?? '').length,
                      ),
                    onChanged: (val) {
                      setState(() {
                        _formData.goalValue = int.tryParse(val);
                      });
                    },
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Value',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Unit dropdown
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _formData.goalUnit ?? 'minutes',
                        isExpanded: true,
                        dropdownColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                          fontSize: 16,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'minutes',
                            child: Text('minutes'),
                          ),
                          DropdownMenuItem(
                            value: 'hours',
                            child: Text('hours'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _formData.goalUnit = val;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Count goal inputs
          if (_formData.goalType == GoalType.count) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                // Value stepper
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.remove,
                              color: isDark
                                  ? AppColors.darkCoral
                                  : AppColors.lightCoral,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                final current = _formData.goalValue ?? 1;
                                _formData.goalValue =
                                    current > 1 ? current - 1 : 1;
                              });
                            },
                          ),
                        ),
                        Text(
                          '${_formData.goalValue ?? 1}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.add,
                              color: isDark
                                  ? AppColors.darkCoral
                                  : AppColors.lightCoral,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                final current = _formData.goalValue ?? 1;
                                _formData.goalValue = current + 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Unit text field (freeform: "glasses", "pages", "times", etc.)
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: TextEditingController(
                      text: _formData.goalUnit ?? '',
                    )..selection = TextSelection.collapsed(
                        offset: (_formData.goalUnit ?? '').length,
                      ),
                    onChanged: (val) {
                      setState(() {
                        _formData.goalUnit = val.isEmpty ? null : val;
                      });
                    },
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Unit (e.g. glasses, pages)',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the reminders toggle and time picker section
  /// 构建提醒开关和时间选择部分
  Widget _buildRemindersSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminders & AI',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Enable Reminders Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enable reminders',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                  fontSize: 15,
                ),
              ),
              Switch(
                value: _formData.reminderEnabled,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _formData.reminderEnabled = value);
                },
                activeTrackColor: isDark
                    ? AppColors.darkCoral
                    : AppColors.lightCoral,
                activeThumbColor: isDark
                    ? AppColors.darkBackground
                    : Colors.white,
              ),
            ],
          ),
          // Time picker (shown when enabled)
          if (_formData.reminderEnabled) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showReminderTimePicker(isDark),
              borderRadius: UIConstants.borderRadiusMedium,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: UIConstants.borderRadiusMedium,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: isDark
                              ? AppColors.darkCoral
                              : AppColors.lightCoral,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Reminder Time',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatTimeOfDay(_formData.reminderTime),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkCoral
                            : AppColors.lightCoral,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Formats a TimeOfDay to a readable string (e.g., "9:00 AM")
  /// 将TimeOfDay格式化为可读字符串（如"9:00 AM"）
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Shows the time picker dialog for setting reminder time
  /// 显示设置提醒时间的时间选择器对话框
  Future<void> _showReminderTimePicker(bool isDark) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _formData.reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark ? AppColors.darkCoral : AppColors.lightCoral,
              onPrimary: Colors.white,
              surface: isDark ? AppColors.darkSurface : Colors.white,
              onSurface: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _formData.reminderTime = picked);
    }
  }

  /// Builds the bottom save/create action button
  /// 构建底部保存/创建操作按钮
  Widget _buildBottomActionButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                .withValues(alpha: 0),
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ],
          stops: const [0.0, 0.3],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _formData.isValid && !_isSaving ? _saveHabit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _formData.isValid
                ? (isDark ? AppColors.darkCoral : AppColors.lightCoral)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            foregroundColor: _formData.isValid
                ? (isDark ? AppColors.darkBackground : Colors.white)
                : (isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText),
            shape: RoundedRectangleBorder(
              borderRadius: UIConstants.borderRadiusLarge,
            ),
            elevation: _formData.isValid ? 4 : 0,
            disabledBackgroundColor: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            disabledForegroundColor: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
          child: _isSaving
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.darkBackground : Colors.white,
                    ),
                  ),
                )
              : Text(
                  widget.isEditing
                      ? 'Save Changes'
                      : (_formData.isAISuggested ? 'Add Habit' : 'Create Habit'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
