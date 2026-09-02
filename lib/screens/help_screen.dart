import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The in-app help screen: explains the app's features and how to use
/// them. Opened from the ❓ button on the home screen's app bar.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _items = <({String icon, String title, String body})>[
    (
      icon: '🌳',
      title: 'مرور مرحله‌ای شجره‌نامه',
      body:
          'از صفحه اصلی وارد خاندان شوید. هر صفحه یک زوج (یا فرد) و فرزندانش را نشان می‌دهد. روی نام هر فرزند بزنید تا به نسل بعد بروید یا پروفایل او باز شود. بالای صفحه، مسیر پیمایش (Breadcrumb) دیده می‌شود و با لمس هر مرحله می‌توانید به عقب برگردید.',
    ),
    (
      icon: '🔍',
      title: 'جستجوی فرد',
      body:
          'در کادر جستجوی صفحه اصلی، نام یا نام خانوادگی هر عضو را بنویسید. با لمس نتیجه، پروفایل کامل فرد (همسر، والدین، فرزندان و محل دفن در صورت وجود) باز می‌شود.',
    ),
    (
      icon: '📊',
      title: 'آمار خاندان',
      body:
          'روی ردیف‌های «زنده»، «فوت کرده» و «شهید» در صفحه اصلی بزنید تا فهرست کامل افراد آن دسته را ببینید. لمس هر نفر، پروفایل او را باز می‌کند.',
    ),
    (
      icon: '👨‍👩‍👧‍👦',
      title: 'شمارش نسل‌ها',
      body:
          'در هر صفحه خانواده و در پروفایل هر فرد، تعداد فرزند، نوه، نتیجه، نبیره و ندیده نمایش داده می‌شود. با لمس هر عدد، فهرست همان نسل باز می‌شود.',
    ),
    (
      icon: '🗂️',
      title: 'نمای درختی',
      body:
          'از دکمه 🌳 در بالای هر صفحه خانواده، نمای کلی و قابل بزرگ‌نمایی کل شجره باز می‌شود. لمس هر گره، همان خانواده را در نمای مرحله‌ای باز می‌کند.',
    ),
    (
      icon: '👤',
      title: 'پروفایل فرد',
      body:
          'پروفایل هر فرد شامل سال تولد، وضعیت (با نشانگر رنگی)، محل دفن (برای درگذشتگان و شهیدان)، همسر، والدین، فرزندان، شمارش نسل‌ها و دکمه «مشاهده در خانواده اصلی» است. دکمه «سلسله پدری» زنجیره پدر، پدربزرگ و … تا سرسلسله را نشان می‌دهد.',
    ),
    (
      icon: '🟢🟡⚫',
      title: 'نشانگرهای وضعیت',
      body:
          'نقطه رنگی کنار هر نام نشان‌دهنده وضعیت است: سبز = زنده، مشکی = فوت کرده، طلایی = شهید. متن کامل وضعیت فقط در پروفایل فرد دیده می‌شود.',
    ),
    (
      icon: '🌲',
      title: 'خاندان‌های جانبی',
      body:
          'در نسخه‌های بعدی، شجره‌نامه خاندان‌های دیگر (خویشاوندان سببی) به بخش «خاندان‌های جانبی» در صفحه اصلی اضافه می‌شود.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('راهنما')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Center(child: Text('❓', style: TextStyle(fontSize: 40))),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'راهنمای استفاده از شجره‌نامه',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 20),
            for (final item in _items) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.icon,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.body,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
