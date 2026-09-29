import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(
          right: BorderSide(
            color: Color(0xFF1F2937),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildBrand(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('MAIN MENU'),

                  const SizedBox(height: 8),

                  _menuItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                  ),

                  _menuItem(
                    index: 1,
                    icon: Icons.people_alt_rounded,
                    title: 'Students',
                  ),

                  _menuItem(
                    index: 2,
                    icon: Icons.school_rounded,
                    title: 'Teachers',
                  ),

                  _menuItem(
                    index: 3,
                    icon: Icons.menu_book_rounded,
                    title: 'Courses',
                  ),

                  _menuItem(
                    index: 4,
                    icon: Icons.assignment_rounded,
                    title: 'Assignments',
                  ),

                  _menuItem(
                    index: 5,
                    icon: Icons.calendar_month_rounded,
                    title: 'Attendance',
                  ),

                  _menuItem(
                    index: 6,
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports',
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('MANAGEMENT'),

                  const SizedBox(height: 8),

                  _menuItem(
                    index: 7,
                    icon: Icons.payments_rounded,
                    title: 'Payments',
                  ),

                  _menuItem(
                    index: 8,
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                  ),

                  _menuItem(
                    index: 9,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                  ),
                ],
              ),
            ),
          ),
          _buildAdminProfile(),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AdminPanel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Management System',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _menuItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFD1D5DB),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminProfile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4B5563),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin User',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Administrator',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},
            tooltip: 'More',
            splashRadius: 20,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}