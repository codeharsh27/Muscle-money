import 'package:flutter/material.dart';

// Notifications Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSwitchTile('Push Notifications', true),
          const SizedBox(height: 16),
          _buildSwitchTile('Email Updates', false),
          const SizedBox(height: 16),
          _buildSwitchTile('Savings Alerts', true),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        value: value,
        onChanged: (bool v) {},
        activeColor: Colors.tealAccent,
      ),
    );
  }
}

// Privacy & Security Screen
class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Your Data is Secure',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'At Muscle Money, we take your privacy and security seriously. We use bank-level encryption (AES-256) to protect your personal and financial data. We never sell your data to third parties, and your simulated investments are completely isolated from your real bank accounts.\n\n'
            'We strictly adhere to industry standards and comply with major data protection regulations to ensure your peace of mind while you focus on building wealth.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Security Settings',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionTile(Icons.lock_outline, 'Change Password'),
          const SizedBox(height: 16),
          _buildActionTile(Icons.fingerprint, 'Biometric Authentication'),
          const SizedBox(height: 16),
          _buildActionTile(Icons.data_usage, 'Data Export'),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: () {},
      ),
    );
  }
}

// Help & About Screen
class HelpAboutScreen extends StatelessWidget {
  const HelpAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('About Muscle Money', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.fitness_center, size: 64, color: Colors.tealAccent),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Muscle Money',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'What is Muscle Money?',
            style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Muscle Money is your ultimate financial fitness coach. Just as building physical muscle requires discipline and consistency, building wealth requires steady financial habits. We gamify and simplify personal finance.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'How we help you',
            style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We combine automated micro-savings (like round-ups on your purchases), bite-sized financial learning modules, and a risk-free stock market simulator. This unique ecosystem ensures you save money effortlessly, learn how to invest it wisely, and practice in a simulated market before risking real cash.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Why we exist',
            style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our mission is to democratize financial literacy and wealth creation. We believe that everyone, regardless of their background or current income, deserves the tools and knowledge to achieve financial freedom. Start building your financial muscle today!',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email, color: Colors.black87),
            label: const Text('Contact Support', style: TextStyle(color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
