import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/images/fitquest_logo.png',
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: emailController,
                    hint: 'Name@Example.Com',
                    label: 'Email Or Phone',
                    icon: Icons.check,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: passwordController,
                    hint: '********',
                    label: 'Password',
                    icon: obscurePassword ? Icons.visibility_off : Icons.visibility,
                    isPassword: true,
                    onIconTap: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Or Login With',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton('Connect With Google', Icons.g_mobiledata, Colors.white, Colors.black),
                  const SizedBox(height: 12),
                  _buildSocialButton('Connect With Facebook', Icons.facebook, Colors.blue, Colors.white),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't Have Account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigatie naar registratiepagina
                        },
                        child: const Text(
                          'Register!',
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onIconTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && obscurePassword,
          style: const TextStyle(color: AppColors.accentGreen),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.accentGreen),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.accentGreen),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.accentGreen),
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: onIconTap != null
                ? IconButton(
                    icon: Icon(icon, color: AppColors.accentGreen),
                    onPressed: onIconTap,
                  )
                : Icon(icon, color: AppColors.accentGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String text, IconData icon, Color color, Color textColor) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: textColor),
        label: Text(
          text,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {},
      ),
    );
  }
}
