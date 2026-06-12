import 'package:flutter/material.dart';
import '../core/models/expense.dart';
import '../core/api/api_client.dart';
import '../core/utils/formatters.dart';

class ExpenseTile extends StatelessWidget {
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

  Future<void> _delete(BuildContext context) async {
    try {
      await ApiClient.delete('/expenses/${expense.id}');
      onDeleted?.call();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not delete')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Card(
        child: ListTile(
          onTap: onTap,
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
                  opacity: highlighted ? 1.0 : 0.0,
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
    );
  }
}
