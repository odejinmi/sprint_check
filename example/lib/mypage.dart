import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprint_check/sprint_check.dart';
import 'package:sprint_check/sprint_check_method_channel.dart';

class Mypage1 extends StatefulWidget {
  const Mypage1({Key? key}) : super(key: key);

  @override
  State<Mypage1> createState() => _MypageState();
}

class _MypageState extends State<Mypage1> {
  String _platformVersion = 'Unknown';
  final _sprintCheckPlugin = SprintCheck();

  final TextEditingController identifierController = TextEditingController(
    text: "odejinmiabraham@gmail.com",
  );
  final TextEditingController bvnController = TextEditingController();
  final TextEditingController apikeyController = TextEditingController();
  final TextEditingController encryptionkeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      apikeyController.text = "scb1edcd88-64f7485186d9781ca624a903";
      encryptionkeyController.text = "enc67fe4978b16fc1744718200";
    }
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _sprintCheckPlugin.getPlatformVersion() ?? 'Unknown platform version';
      await _sprintCheckPlugin.initialize(
        api_key: apikeyController.text,
        encryption_key: encryptionkeyController.text,
      );
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('SprintCheck Demo', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(theme),
            const SizedBox(height: 24),
            _buildSectionHeader("Configuration"),
            const SizedBox(height: 12),
            _buildConfigCard(),
            const SizedBox(height: 24),
            _buildSectionHeader("Verification Details"),
            const SizedBox(height: 12),
            _buildInputCard(),
            const SizedBox(height: 32),
            _buildSectionHeader("Actions"),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Running on: $_platformVersion',
              style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              controller: apikeyController,
              label: "API Key",
              hint: "Enter your API key",
              icon: Icons.vpn_key_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: encryptionkeyController,
              label: "Encryption Key",
              hint: "Enter your encryption key",
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final msg = await _sprintCheckPlugin.initialize(
                    api_key: apikeyController.text,
                    encryption_key: encryptionkeyController.text,
                  );
                  showresult(msg["message"]);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Initialize SDK", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              controller: identifierController,
              label: "Identifier (Email/Phone)",
              hint: "e.g. user@example.com",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: bvnController,
              label: "BVN / NIN",
              hint: "Enter 11-digit number",
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildActionButton(
          label: "BVN Check",
          icon: Icons.account_balance_outlined,
          color: Colors.indigo,
          onTap: () => _handleCheckout(CheckoutMethod.bvn),
        ),
        _buildActionButton(
          label: "NIN Check",
          icon: Icons.fingerprint_outlined,
          color: Colors.teal,
          onTap: () => _handleCheckout(CheckoutMethod.nin),
        ),
        _buildActionButton(
          label: "Face Match",
          icon: Icons.face_outlined,
          color: Colors.deepPurple,
          onTap: () => _handleCheckout(CheckoutMethod.facial),
        ),
        _buildActionButton(
          label: "ID Card",
          icon: Icons.contact_mail_outlined,
          color: Colors.orange[800]!,
          onTap: () => _handleCheckout(CheckoutMethod.idcard),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckout(CheckoutMethod method) async {
    try {
      final response = await _sprintCheckPlugin.checkout(
        context,
        method,
        identifierController.text,
        bvn: (method == CheckoutMethod.bvn || method == CheckoutMethod.nin) ? bvnController.text : null,
        nin: method == CheckoutMethod.nin ? bvnController.text : null,
      );
      showresult("Response: ${response.message}\nStatus: ${response.status}");
    } catch (e) {
      showresult("Error: $e");
    }
  }

  void showresult(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Result", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      },
    );
  }
}
