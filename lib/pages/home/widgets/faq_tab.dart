import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

class FaqTab extends StatefulWidget {
  const FaqTab({super.key});

  @override
  State<FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<FaqTab> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'Are the photos actually professional-quality?',
      answer:
          'Yes. When you follow our in-app composition tips and use good lighting, REALTOG delivers clean, professional-looking listing photos. Our AI fine-tunes each image by correcting verticals, balancing white levels, adjusting brightness, and enhancing skies when needed. All edits are subtle and photorealistic—never artificial or CGI.',
    ),
    FAQItem(
      question: 'How do I take photos with REALTOG?',
      answer:
          'Start by choosing a Photo Package that fits your listing. Use the in-app shooting guide to capture each space, paying attention to the on-screen vertical and horizontal guides for proper alignment. Make sure rooms are well lit—low light can affect image clarity. Once you’re done, submit your photos and relax while we professionally edit them for you.',
    ),
    FAQItem(
      question: 'How quickly will I get my photos?',
      answer:
          'Speed is at the core of what we do. In most cases, your fully edited photos are delivered in just 20–30 minutes. If you choose our Decluttering add-on, delivery may take a little longer—up to 12 hours—to ensure the highest-quality, photo-realistic results.',
    ),
    FAQItem(
      question: 'How much does REALTOG cost?',
      answer:
          'REALTOG is designed to be flexible and transparent. Simply pay per use and choose the photo package that best fits your listing and budget. There are no subscriptions, no contracts, and no hidden fees. Best of all, REALTOG delivers professional-grade results at a fraction of the cost of traditional real estate photography.',
    ),
    FAQItem(
      question:
          'When should I use REALTOG vs traditional real estate photography?',
      answer:
          'REALTOG is designed for moments when speed, flexibility, and value matter most. Because the results are truly professional-grade, there’s no limitation on the type of listing you can use it for—from a one-bedroom rental to a luxury, multi-million-dollar home.\nIf you need high-quality images delivered quickly, or are looking to significantly reduce the cost of traditional real estate media, REALTOG is an ideal solution. It empowers you to move faster, spend less, and still present every listing at its absolute best.',
    ),
    FAQItem(
      question: 'Can I get revisions?',
      answer:
          'REALTOG does not offer revisions. Our AI uses a consistent, standardized editing process, applying the same professional metrics to every image for reliable, repeatable results. The final outcome is directly influenced by the quality of the original capture—this is why following our composition guidelines and using proper lighting is essential to achieving truly professional-grade images.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Row(
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // FAQ List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _FAQCard(faq: _faqs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

class _FAQCard extends StatefulWidget {
  final FAQItem faq;

  const _FAQCard({required this.faq});

  @override
  State<_FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<_FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: Divider(color: AppColors.border, height: 1),
            ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.faq.answer,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
