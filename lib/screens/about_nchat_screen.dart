import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_colors.dart';

class AboutNChatScreen extends StatelessWidget {
  const AboutNChatScreen({super.key});

  // =========================================================
  // OPEN INSTAGRAM
  // =========================================================

  Future<void> _openInstagram(
    BuildContext context,
    String username,
  ) async {
    final uri = Uri.parse(
      'https://www.instagram.com/$username/',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Instagram.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // INSTAGRAM LOGO
  // =========================================================

  Widget _instagramLogo({
    double size = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFFFC107),
            Color(0xFFFF0069),
            Color(0xFF8A3FFC),
          ],
        ),
        borderRadius: BorderRadius.circular(
          size * 0.27,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: size * 0.09,
            ),
            borderRadius: BorderRadius.circular(
              size * 0.18,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INSTAGRAM HANDLE
  // =========================================================

  Widget _instagramHandle(
    BuildContext context,
    String username,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        _openInstagram(
          context,
          username,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _instagramLogo(
              size: 21,
            ),
            const SizedBox(width: 7),
            Text(
              '@$username',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // INFORMATION CARD
  // =========================================================

  Widget _card(
    BuildContext context,
    Widget child,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(
            alpha: 0.35,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // =========================================================
  // TEAM MEMBER
  // =========================================================

  Widget _teamMember(
    BuildContext context,
    String name,
    String username,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor:
                AppColors.primary.withValues(
              alpha: 0.12,
            ),
            child: Text(
              name.substring(0, 1),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style:
                      theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                _instagramHandle(
                  context,
                  username,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'About NChat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // NCHAT HEADER
            // =================================================

            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(
                        alpha: 0.78,
                      ),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(
                        alpha: 0.20,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'NChat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Chat. Connect. Communicate.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // =================================================
            // DESCRIPTION
            // =================================================

            _card(
              context,
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NChat is a simple and easy-to-use '
                    'messaging application designed to help '
                    'you stay connected with the people you know.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // PRIVACY & SECURITY
            // =================================================

            _sectionTitle(
              context,
              Icons.security_outlined,
              'Privacy & Security',
            ),

            const SizedBox(height: 12),

            _card(
              context,
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your privacy matters to us.',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'NChat is designed with privacy and '
                    'security in mind. Your conversations '
                    'and account information are intended '
                    'to be handled securely, and NChat '
                    'does not make your information publicly '
                    'visible to other users unnecessarily.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 19,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your conversations are yours.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // =================================================
            // FOLLOW NCHAT
            // =================================================

            _sectionTitle(
              context,
              Icons.favorite_outline,
              'Follow NChat',
            ),

            const SizedBox(height: 12),

            _card(
              context,
              ListTile(
                contentPadding: EdgeInsets.zero,

                // Instagram logo
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: _instagramLogo(
                      size: 30,
                    ),
                  ),
                ),

                title: const Text(
                  'Instagram',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: _instagramHandle(
                  context,
                  'nchatofficial',
                ),

                trailing: const Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: AppColors.primary,
                ),

                onTap: () {
                  _openInstagram(
                    context,
                    'nchatofficial',
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // =================================================
            // DEVELOPER
            // =================================================

            _sectionTitle(
              context,
              Icons.code_outlined,
              'Developer',
            ),

            const SizedBox(height: 12),

            _card(
              context,
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor:
                        AppColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nishant Kumar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _instagramHandle(
                          context,
                          'nishantyadav_143',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // =================================================
            // NCHAT TEAM
            // =================================================

            _sectionTitle(
              context,
              Icons.groups_outlined,
              'NChat Team',
            ),

            const SizedBox(height: 12),

            _card(
              context,
              Column(
                children: [
                  _teamMember(
                    context,
                    'Ayush Kumar',
                    'ayush_yaduvanshi086',
                  ),
                  _teamMember(
                    context,
                    'Himanshu Kumar',
                    'its_himanshu169gupta',
                  ),
                  _teamMember(
                    context,
                    'Chandan Kumar',
                    'itz__chandu__0.1',
                  ),
                  _teamMember(
                    context,
                    'Aryan Kumar',
                    'ak_yadav_183',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // COPYRIGHT
            // =================================================

            Center(
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(
                        alpha: 0.25,
                      ),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '© 2026 NChat',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}