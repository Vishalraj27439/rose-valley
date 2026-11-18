import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReusableOverlayDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final List<Map<String, dynamic>> list;
  final String labelKey;
  final String valueKey;
  final TextEditingController controller;
  final Function(String value, String label) onSelected;

  const ReusableOverlayDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.list,
    required this.labelKey,
    required this.valueKey,
    required this.controller,
    required this.onSelected,
  });

  @override
  State<ReusableOverlayDropdown> createState() =>
      _ReusableOverlayDropdownState();
}

class _ReusableOverlayDropdownState extends State<ReusableOverlayDropdown> {
  final GlobalKey fieldKey = GlobalKey();
  OverlayEntry? overlayEntry;

  void hideOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  void showOverlay() {
    if (widget.list.isEmpty) return;

    hideOverlay();

    final renderBox = fieldKey.currentContext!.findRenderObject() as RenderBox;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    const double itemHeight = 44;
    const int maxVisibleItems = 4;

    final visibleCount = math.min(widget.list.length, maxVisibleItems);

    final maxHeight = visibleCount * itemHeight;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Outside tap to close
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: hideOverlay,
              child: const SizedBox.expand(),
            ),
          ),

          // Dropdown directly below field
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: Material(
              color: Colors.white,
              elevation: 6,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: maxHeight,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.list.length,
                  itemExtent: itemHeight,
                  itemBuilder: (context, index) {
                    final item = widget.list[index];

                    final label = item[widget.labelKey].toString();

                    final value = item[widget.valueKey].toString();

                    return InkWell(
                      onTap: () {
                        widget.controller.text = label;

                        widget.onSelected(value, label);

                        hideOverlay();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(overlayEntry!);
  }

  @override
  void dispose() {
    hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: fieldKey,
      onTap: showOverlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty) ...[
            Text(
              widget.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
          ],
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.controller.text.isEmpty
                        ? widget.hint
                        : widget.controller.text,
                    style: const TextStyle(fontSize: 13),
                    softWrap: false,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnchoredDropdown extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const AnchoredDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<AnchoredDropdown> createState() => _AnchoredDropdownState();
}

class _AnchoredDropdownState extends State<AnchoredDropdown> {
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  double _fieldWidth = 0;

  bool get _isOpen => _overlayEntry != null;

  void _toggleDropdown() {
    if (_isOpen) {
      _hideDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    if (widget.items.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox;
    _fieldWidth = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final visibleCount = widget.items.length > 4 ? 4 : widget.items.length;

        return Stack(
          children: [
            // Outside tap to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideDropdown,
                child: const SizedBox.expand(),
              ),
            ),

            // Dropdown menu directly below field
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: _fieldWidth,
                  height: visibleCount * 44.0,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: widget.items.length,
                    itemExtent: 44,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = item == widget.value;

                      return InkWell(
                        onTap: () {
                          _hideDropdown();
                          widget.onChanged(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: isSelected
                              ? const Color(0xFFEFF4FF)
                              : Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? const Color(0xFF1E3A8A)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Color(0xFF1E3A8A),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void didUpdateWidget(covariant AnchoredDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value || oldWidget.items != widget.items) {
      _hideDropdown();
    }
  }

  @override
  void dispose() {
    _hideDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
