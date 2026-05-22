import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/item.dart';
import 'status_badge.dart';
import 'countdown_display.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ItemCard({super.key, required this.item, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (item.specification != null && item.specification!.isNotEmpty)
                      Text(
                        item.specification!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    CountdownDisplay(date: item.expiryDate, status: item.status),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textDisabled),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
