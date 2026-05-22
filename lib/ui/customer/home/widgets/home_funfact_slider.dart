import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/providers/funfact_banner_provider.dart';
import 'package:petshopapp/ui/customer/chat/chat_screen.dart';
import 'package:go_router/go_router.dart';


class HomeFunFactSlider extends StatefulWidget {
  const HomeFunFactSlider({super.key});

  @override
  State<HomeFunFactSlider> createState() => _HomeFunFactSliderState();
}
class _HomeFunFactSliderState extends State<HomeFunFactSlider> {
  final PageController _pageController = PageController();

  int currentIndex = 0;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        final provider = context.read<FunFactBannerProvider>();
        if (provider.banners.isEmpty) return;

        currentIndex++;

        if (currentIndex >= provider.banners.length) {
          currentIndex = 0;
        }

        _pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }
   @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = context
        .watch<FunFactBannerProvider>()
        .banners
        .where((e) => e.isActive)
        .toList();
    if (banners.isEmpty) {
      return const Center(
         child: Text(
           'Belum ada banner funfact',
        ),
      );
    }
     return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final item = banners[index];

          return GestureDetector(
            onTap: () {
              context.push('/funfact-detail', extra: item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(item.imageUrl.isNotEmpty 
                      ? item.imageUrl 
                      : 'https://via.placeholder.com/400x200?text=Fun+Fact'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha(120),
                    BlendMode.darken,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Colors.black12,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Tap to see detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
                        