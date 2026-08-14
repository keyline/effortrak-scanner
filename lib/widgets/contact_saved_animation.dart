import 'package:flutter/material.dart';

Future<void> showContactSavedAnimation(BuildContext context) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Contact saved',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      Future<void>.delayed(const Duration(milliseconds: 1350), () {
        if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });
      return const _ContactSavedCelebration();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _ContactSavedCelebration extends StatefulWidget {
  const _ContactSavedCelebration();

  @override
  State<_ContactSavedCelebration> createState() =>
      _ContactSavedCelebrationState();
}

class _ContactSavedCelebrationState extends State<_ContactSavedCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final turn = Curves.easeOutBack.transform(_controller.value);
                  return Transform.rotate(
                    angle: (1 - turn) * -.35,
                    child: Transform.scale(scale: .7 + turn * .3, child: child),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7F9EC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF25B95A),
                      size: 72,
                    ),
                    const Positioned(
                      right: 0,
                      top: 2,
                      child: Text('✨', style: TextStyle(fontSize: 24)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact saved!',
                style: TextStyle(
                  color: Color(0xFF103D35),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Added to your phonebook',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
