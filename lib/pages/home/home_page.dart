import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/reusable_appbar.dart';
import '../../providers/auth_provider.dart';
import 'widgets/home_tab.dart';
import 'widgets/orders_tab.dart';
import 'widgets/faq_tab.dart';
import 'widgets/messages_tab.dart';
import 'widgets/profile_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  final int? initialTabIndex;

  const HomePage({super.key, this.initialTabIndex});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex ?? 0;
  }
  String _convertToEmbedUrl(String url) {
    if (url.contains("youtube.com/watch")) {
      final videoId = Uri.parse(url).queryParameters['v'];
      return "https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1";
    }
    return url;
  }

  Future<String?> _fetchVideoUrl() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.socialLinksUrl),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final platform = data['data']['platform'];

          if (platform == "youtube") {
            return data['data']['youtubeUrl'];
          } else if (platform == "facebook") {
            return data['data']['facebookUrl'];
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }


  Future<void> _showHowToUsePopup() async {
    final videoUrl = await _fetchVideoUrl();

    if (videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video not available")),
      );
      return;
    }

    final finalUrl = videoUrl.contains("youtube")
        ? _convertToEmbedUrl(videoUrl)
        : videoUrl;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: WebViewWidget(
                    controller: WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(finalUrl)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ReusableAppBar(title: _getAppBarTitle(_currentIndex)),

      drawer: AppDrawer(
        userName: user?.name,
        userEmail: user?.email,
      ),
      body: _buildBody(_currentIndex, user),

      floatingActionButton: Container(
        height: 38, // 👈 height control এখানে
        padding: const EdgeInsets.symmetric(horizontal: 18), // 👈 width বাড়াবে
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _showHowToUsePopup,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'How to use',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconSize: 20.sp,
          selectedLabelStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'ORDERS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outline),
              activeIcon: Icon(Icons.help),
              label: 'FAQ\'S',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'PROFILE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline),
              activeIcon: Icon(Icons.mail),
              label: 'CHAT',
            ),
          ],
        ),
      ),
    );


  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Select Package';
      case 1:
        return 'Pricing Details';
      case 2:
        return 'FAQ\'S';
      case 3:
        return 'Profile';
      case 4:
        return 'Messages';
      default:
        return 'Select Package';
    }
  }

  Widget _buildBody(int currentIndex, user) {
    switch (currentIndex) {
      case 0:
        return HomeTab(user: user);
      case 1:
        return const OrdersTab();
      case 2:
        return const FaqTab();
      case 3:
        return const ProfileTab();
      case 4:
        return const MessagesTab();
      default:
        return HomeTab(user: user);
    }
  }
}
