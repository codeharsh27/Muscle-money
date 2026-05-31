import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../../auth/presentation/auth_controller.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _incomeController;
  String _knowledgeLevel = 'BEGINNER';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _incomeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic> userProfile) {
    if (_nameController.text.isEmpty) {
      _nameController.text = userProfile['fullName'] ?? '';
      
      final profile = userProfile['profile'] ?? {};
      if (profile['monthlyIncomeMinor'] != null) {
        _incomeController.text = (profile['monthlyIncomeMinor'] / 100).toStringAsFixed(0);
      }
      _knowledgeLevel = profile['knowledgeLevel'] ?? 'BEGINNER';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final monthlyIncomeMinor = int.parse(_incomeController.text) * 100;
      
      await ref.read(profileRepositoryProvider).updateProfile({
        'fullName': _nameController.text.trim(),
        'monthlyIncomeMinor': monthlyIncomeMinor,
        'knowledgeLevel': _knowledgeLevel,
      });

      ref.invalidate(userProfileProvider);
      ref.invalidate(authControllerProvider); // To refresh user name globally if needed
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Personal Information', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
        error: (error, stack) => Center(child: Text('Error loading profile: $error', style: const TextStyle(color: Colors.redAccent))),
        data: (userProfile) {
          // Only populate once initially
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateForm(userProfile);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Full Name', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Enter your full name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Monthly Income (₹)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _incomeController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Enter monthly income'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Must be a valid number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  const Text('Financial Knowledge Level', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _knowledgeLevel,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1B1429),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _knowledgeLevel = newValue);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                          DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                          DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade400,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.black87)
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.5)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
