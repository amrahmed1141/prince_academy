import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_searchable_dropdown_field.dart';

class SessionDetailsPanel extends StatefulWidget {
  final List<SessionSlot> slots;
  final List<String> weekDays;
  final List<String> classTypes;
  final bool enabled;
  final void Function(int index, SessionSlot slot) onSlotChanged;

  const SessionDetailsPanel({
    super.key,
    required this.slots,
    required this.weekDays,
    required this.classTypes,
    required this.enabled,
    required this.onSlotChanged,
  });

  @override
  State<SessionDetailsPanel> createState() => _SessionDetailsPanelState();
}

class _SessionDetailsPanelState extends State<SessionDetailsPanel> {
  static const _pageSwitchDuration = Duration(milliseconds: 220);
  static const _sessionPageHeight = 132.0;

  int _selectedIndex = 0;
  late final PageController _pageController;
  final _chipScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SessionDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots.isEmpty) return;

    if (_selectedIndex >= widget.slots.length) {
      _selectedIndex = widget.slots.length - 1;
    }

    if (oldWidget.slots.length != widget.slots.length &&
        _pageController.hasClients) {
      final target = _selectedIndex.clamp(0, widget.slots.length - 1);
      _pageController.jumpToPage(target);
    }
  }

  void _selectSession(int index) {
    if (index < 0 || index >= widget.slots.length) return;
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: _pageSwitchDuration,
        curve: Curves.easeOutCubic,
      );
    }
    _scrollChipIntoView(index);
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _scrollChipIntoView(index);
  }

  void _scrollChipIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipScrollController.hasClients) return;
      const chipStride = 104.0;
      final target = (index * chipStride).clamp(
        0.0,
        _chipScrollController.position.maxScrollExtent,
      );
      _chipScrollController.animateTo(
        target,
        duration: _pageSwitchDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.slots.length;
    final multiSession = count > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.sectionTitle('Session Details'),
        const SizedBox(height: 12),
        if (multiSession) ...[
          SingleChildScrollView(
            controller: _chipScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(count, (i) {
                final active = i == _selectedIndex;
                return GestureDetector(
                  onTap: () => _selectSession(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: i < count - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? EColorConstants.primaryColor
                          : AdminFormStyles.sessionPanelFill,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: active
                            ? EColorConstants.primaryColor
                            : const Color(0xFFE8DDD0),
                      ),
                    ),
                    child: Text(
                      'Session ${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white
                            : EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: AdminFormStyles.sessionDetailsPanelDecoration,
          child: multiSession
              ? SizedBox(
                  height: _sessionPageHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: count,
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SessionDraftRow(
                          index: index,
                          slot: widget.slots[index],
                          weekDays: widget.weekDays,
                          classTypes: widget.classTypes,
                          enabled: widget.enabled,
                          showLabel: false,
                          onChanged: (slot) =>
                              widget.onSlotChanged(index, slot),
                        ),
                      );
                    },
                  ),
                )
              : SessionDraftRow(
                  index: 0,
                  slot: widget.slots.first,
                  weekDays: widget.weekDays,
                  classTypes: widget.classTypes,
                  enabled: widget.enabled,
                  showLabel: true,
                  onChanged: (slot) => widget.onSlotChanged(0, slot),
                ),
        ),
      ],
    );
  }
}

class SessionDraftRow extends StatelessWidget {
  final int index;
  final SessionSlot slot;
  final List<String> weekDays;
  final List<String> classTypes;
  final bool enabled;
  final bool showLabel;
  final ValueChanged<SessionSlot> onChanged;

  const SessionDraftRow({
    super.key,
    required this.index,
    required this.slot,
    required this.weekDays,
    required this.classTypes,
    this.enabled = true,
    this.showLabel = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8DDD0)),
            ),
            child: Text(
              'Session ${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Day',
                value: slot.day,
                prefixIcon: Iconsax.calendar_1,
                items: weekDays,
                onChanged: (value) {
                  if (value != null) onChanged(slot.copyWith(day: value));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                label: 'Class Type',
                value: slot.classType,
                prefixIcon: Iconsax.category,
                items: classTypes,
                onChanged: (value) {
                  if (value != null) onChanged(slot.copyWith(classType: value));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required IconData prefixIcon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return AdminSearchableDropdownField<String>(
      label: label,
      value: value.isNotEmpty && items.contains(value) ? value : null,
      items: items,
      itemLabel: (item) => item,
      prefixIcon: prefixIcon,
      enabled: enabled,
      hintText: 'Select $label',
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
