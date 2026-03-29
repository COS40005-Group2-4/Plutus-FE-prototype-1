part of dashboard;

/// Slot background builder.
abstract class SlotBackgroundBuilder<T extends DashboardItem> {
  SlotBackgroundBuilder();

  /// Create a builder with a function.
  static SlotBackgroundBuilder<T> withFunction<T extends DashboardItem>(
      Widget? Function(
              BuildContext context, T? item, int x, int y, bool editing)
          builder) {
    return _WithFunctionSlotBackgroundBuilder<T>(builder);
  }

  DashboardItemController<T>? _itemController;

  Widget _build(BuildContext context, int x, int y) {
    final layoutController = _itemController!._layoutController!;
    final i = layoutController._indexesTree[layoutController.getIndex([x, y])];

    T? item;
    bool isSwapTarget = false;

    if (i != null) {
      item = layoutController.itemController._items[i] as T;
      isSwapTarget =
          layoutController._layouts![i]?._isSwapTarget.value ?? false;
    }

    return buildBackground(
            context, item, x, y, layoutController._isEditing, isSwapTarget) ??
        Container();
  }

  /// Build background widget.
  /// [isSwapTarget] is true when the item at this slot is the target of
  /// a pending swap operation during drag.
  Widget? buildBackground(BuildContext context, T? item, int x, int y,
      bool editing, bool isSwapTarget);
}

class _WithFunctionSlotBackgroundBuilder<T extends DashboardItem>
    extends SlotBackgroundBuilder<T> {
  final Widget? Function(
      BuildContext context, T? item, int x, int y, bool editing) builder;

  _WithFunctionSlotBackgroundBuilder(this.builder);

  @override
  Widget? buildBackground(BuildContext context, T? item, int x, int y,
      bool editing, bool isSwapTarget) {
    return builder(context, item, x, y, editing);
  }
}
