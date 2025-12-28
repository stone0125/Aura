import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_form_data.dart';
import '../models/ai_coach_models.dart';
import '../providers/habit_provider.dart';
import '../config/theme/app_colors.dart';
import '../config/habit_icons.dart';
import '../services/notification_service.dart';

/// Habit Creation Screen
class HabitCreationScreen extends StatefulWidget {
  /// Live AI Coach suggestion from Cloud Functions
  final AICoachSuggestion? aiCoachSuggestion;

  const HabitCreationScreen({super.key, this.aiCoachSuggestion});

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

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _nameController.addListener(_onNameChanged);
  }

  void _initializeForm() {
    _formData = HabitFormData();

    // Pre-fill from AI suggestion if provided
    if (widget.aiCoachSuggestion != null) {
      final suggestion = widget.aiCoachSuggestion!;
      _formData.name = suggestion.title;
      _formData.description = suggestion.description;
      _formData.category = suggestion.category;
      _formData.selectedIcon = HabitIcons.getDefaultIconForCategory(
        suggestion.category.name,
      );
      _formData.aiOptimizedTiming = true;
      _formData.isAISuggested = true;

      _nameController.text = suggestion.title;
      _descriptionController.text = suggestion.description;
    } else {
      // Default icon
      _formData.selectedIcon = HabitIcons.icons.first.icon;
    }
  }

  void _onNameChanged() {
    setState(() {
      _formData.name = _nameController.text;
      if (_nameError != null) {
        _validateName();
      }
    });
  }

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

  bool _validateCategory() {
    if (_formData.category == null) {
      setState(() => _categoryError = 'Please select a category');
      return false;
    }
    setState(() => _categoryError = null);
    return true;
  }

  bool _validateFrequency() {
    if (_formData.frequencyType == FrequencyType.weekly &&
        _formData.weeklyDays.isEmpty) {
      setState(() => _frequencyError = 'Please select at least one day');
      return false;
    }
    setState(() => _frequencyError = null);
    return true;
  }

  bool _validateForm() {
    final nameValid = _validateName();
    final categoryValid = _validateCategory();
    final frequencyValid = _validateFrequency();

    return nameValid && categoryValid && frequencyValid;
  }

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

    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create habit with reminder settings
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _formData.name,
      category: _formData.category!,
      streak: 0,
      isCompleted: false,
      reminderEnabled: _formData.reminderEnabled,
      reminderTime: _formData.reminderEnabled ? _formData.reminderTime : null,
    );

    if (mounted) {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      habitProvider.addHabit(habit);

      // Schedule notification if reminder is enabled
      if (_formData.reminderEnabled) {
        await NotificationService().scheduleHabitReminder(
          habitId: habit.id,
          habitName: habit.name,
          hour: _formData.reminderTime.hour,
          minute: _formData.reminderTime.minute,
        );
      }

      if (!mounted) return;

      // Success feedback
      HapticFeedback.mediumImpact();

      // Close screen
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _formData.reminderEnabled
                ? 'Habit created with reminder!'
                : 'Habit created!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    // Check if form has content
    if (_formData.name.isNotEmpty || _formData.description.isNotEmpty) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard habit?'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
        _formData.isAISuggested ? 'Add AI Suggestion' : 'Create Habit',
        style: TextStyle(
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _nameError != null
                      ? (isDark ? AppColors.darkRed : AppColors.red)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? gradientColors[0]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                  borderRadius: BorderRadius.circular(24),
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
              borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(10),
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
                    width: 44,
                    height: 44,
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
          Text(
            'Set goals for this habit to track progress',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

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
              borderRadius: BorderRadius.circular(16),
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
                  _formData.isAISuggested ? 'Add Habit' : 'Create Habit',
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
