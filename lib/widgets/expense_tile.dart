import 'package:flutter/material.dart';
import '../core/models/expense.dart';
import '../core/api/api_client.dart';
import '../core/utils/formatters.dart';

class ExpenseTile extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final bool highlighted;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onDeleted,
    this.onTap,
    this.highlighted = false,
  });

  @override
  State<ExpenseTile> createState() => _ExpenseTileState();
}

class _ExpenseTileState extends State<ExpenseTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    if (widget.highlighted) _shakeCtrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(ExpenseTile old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !old.highlighted) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete(BuildContext context) async {
    try {
      await ApiClient.delete('/expenses/${widget.expense.id}');
      widget.onDeleted?.call();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not delete')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    return Dismissible(
      key: Key(expense.id.isNotEmpty ? expense.id : expense.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete expense?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete')),
          ],
        ),
      ),
      onDismissed: (_) => _delete(context),
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: Card(
          child: ListTile(
            onTap: widget.onTap,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  child: Text(
                    (expense.category?.isNotEmpty == true
                            ? expense.category!.substring(0, 1).toUpperCase()
                            : null) ??
                        'E',
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: AnimatedOpacity(
                    opacity: widget.highlighted ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(expense.description,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                '${expense.category?.isNotEmpty == true ? expense.category : 'Uncategorized'} • ${formatDate(expense.date)}'),
            trailing: Text(
              formatCurrency(expense.amount, expense.currency),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
