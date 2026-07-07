import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final Function(T) itemLabelBuilder;
  final Function(List<T>) onSelectionChanged;
  final String hintText;
  final bool isfilled;

  const MultiSelectDropdown({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.itemLabelBuilder,
    required this.onSelectionChanged,
    this.hintText = "Select items",
    this.isfilled = false,
  });

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  bool _isExpanded = false;

  void _toggleItem(T item) {
    final List<T> updated = List.from(widget.selectedItems);
    if (updated.contains(item)) {
      updated.remove(item);
    } else {
      updated.add(item);
    }
    widget.onSelectionChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isfilled ? const Color(0xffF9F9F9) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffD9D8DD)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedItems.isEmpty
                        ? widget.hintText
                        : "${widget.selectedItems.length} selected",
                    style: AppTextStyles.size14Medium.copyWith(
                      color: widget.selectedItems.isEmpty
                          ? const Color(0xff707070)
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.mainAppColr,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffD9D8DD)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedItems.contains(item);
                return InkWell(
                  onTap: () => _toggleItem(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.mainAppColr.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xffD9D8DD).withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.mainAppColr
                                  : const Color(0xffD9D8DD),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: isSelected
                                ? AppColors.mainAppColr
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.itemLabelBuilder(item),
                            style: AppTextStyles.size14Medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

