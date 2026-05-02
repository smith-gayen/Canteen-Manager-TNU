import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _uidController = TextEditingController();
  final _roomController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedHostel;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isBoy = false;
  bool _isGirl = false;

  final List<String> _allHostels = ['H3', 'H4', 'H5', 'H7'];

  @override
  void initState() {
    super.initState();
    _uidController.addListener(_onUidChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _uidController.dispose();
    _roomController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUidChanged() {
    final uid = _uidController.text.trim().toUpperCase();
    bool newIsBoy = false;
    bool newIsGirl = false;

    // Check after the year section (assuming TNU2024...)
    if (uid.length > 7) {
      final afterYear = uid.substring(7);
      if (afterYear.contains('91')) {
        newIsBoy = true;
      } else if (afterYear.contains('92')) {
        newIsGirl = true;
      }
    }

    if (_isBoy != newIsBoy || _isGirl != newIsGirl) {
      setState(() {
        _isBoy = newIsBoy;
        _isGirl = newIsGirl;

        if (_isGirl) {
          _selectedHostel = 'H3';
        } else if (_isBoy) {
          if (_selectedHostel == 'H3') {
            _selectedHostel = null;
          }
        } else {
          _selectedHostel = null;
        }
      });
    }
  }

  List<String> get _availableHostels {
    if (_isGirl) {
      return ['H3'];
    } else if (_isBoy) {
      return ['H4', 'H5', 'H7'];
    }
    return _allHostels;
  }

  String? _validateName(String? val, {bool isRequired = true}) {
    if (val == null || val.trim().isEmpty) {
      return isRequired ? 'Required' : null;
    }
    final trimmed = val.trim();
    if (trimmed.length < 2) return 'Minimum 2 characters';
    if (trimmed.length > 50) return 'Maximum 50 characters';
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(trimmed)) {
      return 'Letters, spaces, and hyphens only';
    }
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Required';
    final trimmed = val.trim();
    if (trimmed.contains(' ')) return 'No spaces allowed';
    if (!trimmed.endsWith('@tnu.in')) return 'Must end exactly with @tnu.in';
    if (trimmed.length <= 7) return 'Invalid email format';

    final regex = RegExp(r'^[\w\-\.]+@tnu\.in$');
    if (!regex.hasMatch(trimmed)) return 'Invalid email characters';
    return null;
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) return 'Required';
    final trimmed = val.trim();
    if (trimmed.contains(' ')) return 'No spaces allowed';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
      return 'Must be a valid 10-digit Indian mobile number';
    }
    return null;
  }

  String? _validateUid(String? val) {
    if (val == null || val.trim().isEmpty) return 'Required';
    final trimmed = val.trim().toUpperCase();
    if (!trimmed.startsWith('TNU')) return 'Must start with TNU';
    if (trimmed.length != 16) return 'Must be exactly 16 characters';
    if (!RegExp(r'^TNU\d{13}$').hasMatch(trimmed)) {
      return 'Invalid UID format (TNU + 13 numbers)';
    }
    final afterYear = trimmed.substring(7);
    if (!afterYear.contains('91') && !afterYear.contains('92')) {
      return 'Invalid gender code (Must contain 91 or 92)';
    }
    return null;
  }

  String? _validateRoom(String? val) {
    if (val == null || val.trim().isEmpty) return 'Required';
    final trimmed = val.trim();
    if (trimmed.length > 10) return 'Maximum 10 characters';
    if (!RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(trimmed)) {
      return 'Letters, numbers, and hyphens only';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Required';
    if (val.contains(' ')) return 'No spaces allowed';
    if (val.length < 8) return 'Minimum 8 characters';
    if (val.length > 32) return 'Maximum 32 characters';
    if (!RegExp(r'[A-Z]').hasMatch(val)) return 'At least 1 uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(val)) return 'At least 1 lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(val)) return 'At least 1 number';
    if (!RegExp(r'[!@#\$&*~%^()-+=|<>.?/_\-]').hasMatch(val)) {
      return 'At least 1 special character';
    }

    final uid = _uidController.text.trim();
    final email = _emailController.text.trim();
    if (uid.isNotEmpty && val.toUpperCase() == uid.toUpperCase()) {
      return 'Cannot be the same as UID';
    }
    if (email.isNotEmpty && val.toLowerCase() == email.toLowerCase()) {
      return 'Cannot be the same as Email';
    }

    return null;
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedHostel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid hostel')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final uid = _uidController.text.trim().toUpperCase();

    String capitalize(String s) =>
        s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : '';

    final fn = _firstNameController.text.trim();
    final ln = _lastNameController.text.trim();
    final mn = _middleNameController.text.trim();

    final error = await AuthService.registerUser(
      firstName: capitalize(fn),
      middleName: capitalize(mn),
      lastName: capitalize(ln),
      email: email,
      phone: phone,
      uid: uid,
      hostel: _selectedHostel!,
      room: _roomController.text.trim().toUpperCase(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration Successful!')));
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(children: [_buildTopSection(), _buildBottomSection()]),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      height: 240,
      color: const Color(0xFF1B1C19),
      child: Stack(
        children: [
          Positioned(
            left: -39,
            top: -35,
            child: _archCircle(468, 423, const Color(0xFF944A00)),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _archCircle(390, 353, const Color(0xFF944A00)),
          ),
          Positioned(
            left: 39,
            top: 35,
            child: _archCircle(312, 282, const Color(0xFF944A00)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF944A00).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF944A00).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Join Hostel Mess',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _archCircle(double w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: AppColors.background,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'STUDENT REGISTRATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Name Fields
              _buildInputField(
                label: 'FIRST NAME',
                hint: 'e.g. Aryan',
                controller: _firstNameController,
                icon: Icons.person_outline,
                validator: (val) => _validateName(val, isRequired: true),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'MIDDLE NAME',
                hint: 'e.g. Kumar (Optional)',
                controller: _middleNameController,
                icon: Icons.person_outline,
                validator: (val) => _validateName(val, isRequired: false),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'LAST NAME',
                hint: 'e.g. Shah',
                controller: _lastNameController,
                icon: Icons.person_outline,
                validator: (val) => _validateName(val, isRequired: true),
              ),
              const SizedBox(height: 20),

              // Email & Phone
              _buildInputField(
                label: 'INSTITUTIONAL EMAIL',
                hint: 'student@tnu.in',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'PHONE NUMBER',
                hint: 'e.g. 9876543210',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
                validator: _validatePhone,
              ),
              const SizedBox(height: 20),

              // UID
              _buildInputField(
                label: 'UNIVERSITY ID (UID)',
                hint: 'e.g. TNU2024069100014',
                controller: _uidController,
                icon: Icons.badge_outlined,
                validator: _validateUid,
              ),
              const SizedBox(height: 8),
              if (_isBoy)
                const Text(
                  ' Male student detected. Select H4, H5, or H7.',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              if (_isGirl)
                const Text(
                  ' Female student detected. Auto-assigned to H3.',
                  style: TextStyle(color: Colors.pink, fontSize: 12),
                ),
              const SizedBox(height: 20),

              // Hostel
              const Text(
                'HOSTEL SELECTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedHostel,
                    hint: const Text(
                      'Select your hostel',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    items: _availableHostels.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: _isGirl
                        ? null
                        : (newValue) {
                            setState(() {
                              _selectedHostel = newValue;
                            });
                          },
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Room
              _buildInputField(
                label: 'ROOM NUMBER',
                hint: 'e.g. A-402',
                controller: _roomController,
                icon: Icons.door_front_door_outlined,
                validator: _validateRoom,
              ),
              const SizedBox(height: 20),

              // Passwords
              _buildInputField(
                label: 'PASSWORD',
                hint: 'Min. 8 characters',
                controller: _passwordController,
                obscureText: _obscurePassword,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'CONFIRM PASSWORD',
                hint: 'Re-enter password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    required IconData icon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          validator: validator,
          decoration: InputDecoration(
            fillColor: AppColors.inputBackground,
            filled: true,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            errorStyle: const TextStyle(height: 1, color: Colors.red),
          ),
        ),
      ],
    );
  }
}
