import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/providers/funfact_banner_provider.dart';
import 'package:petshopapp/ui/customer/chat/chat_screen.dart';



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
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final item = banners[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    defaultTopic: item.topic,
                  ),
                ),
                );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: item.gradientColors
                      .map((e) => Color(e))
                      .toList(),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                   const SizedBox(width: 20),
                  Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 70),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
                        