import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class VerifyPasswordScreen extends StatefulWidget {
  static const Color backgroundColor = Color(0xFF5C6B7D);
  static const Color primaryColor = Color(0xFF8196B0);
  static const Color textColor = Color(0xFFD6E4F0);

  const VerifyPasswordScreen({super.key});
  @override
  VerifyPasswordScreenState createState() => VerifyPasswordScreenState();
}

class VerifyPasswordScreenState extends State<VerifyPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  Future<void> _verifyPassword() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your password.'),
          backgroundColor: VerifyPasswordScreen.primaryColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String? email = user?.email;

      if (user != null && email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        // Reauthenticate user
        await user.reauthenticateWithCredential(credential);

        if (mounted) {
          _showDeleteConfirmationDialog();
        }
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not logged in',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect password. Please try again.'),
            backgroundColor: VerifyPasswordScreen.primaryColor,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: VerifyPasswordScreen.backgroundColor,
          title: Text(
            'Confirm Deletion',
            style: TextStyle(color: VerifyPasswordScreen.textColor),
          ),
          content: Text(
            'Are you sure you want to permanently delete your account?',
            style: TextStyle(color: VerifyPasswordScreen.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isLoading = false;
                });
              },
              child: Text('Cancel', style: TextStyle(color: VerifyPasswordScreen.textColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteAccount(); // Proceed to deletion
              },
              child: Text('Delete', style: TextStyle(color: VerifyPasswordScreen.textColor)),
            ),
          ],
        );
      },
    ).then((_) {
      // Reset loader if dialog was dismissed in any way (back button or cancel)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _deleteAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;
        final userRef = firestore.collection('Users').doc(uid);

        // Subcollection names
        final subcollections = ['GeneratedTimetable', 'StudySchedule', 'TaskManagement'];

        // Loop through each subcollection
        for (String subcollection in subcollections) {
          final subRef = userRef.collection(subcollection);
          final snapshot = await subRef.get();

          if (snapshot.docs.isNotEmpty) {
            for (var doc in snapshot.docs) {
              await doc.reference.delete();
            }
          }
        }

        // Delete the main user document
        await userRef.delete();

        // Delete the Firebase Auth user
        await user.delete();

        // Sign out
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Account successfully deleted.'),
            backgroundColor: VerifyPasswordScreen.primaryColor,
          ));

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting account.'),
          backgroundColor: VerifyPasswordScreen.primaryColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: VerifyPasswordScreen.backgroundColor,
      appBar: AppBar(
        backgroundColor: VerifyPasswordScreen.backgroundColor,
        iconTheme: IconThemeData(color: VerifyPasswordScreen.textColor),
        elevation: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Text(
            "Verify Password",
            style: TextStyle(
              color: VerifyPasswordScreen.textColor,
              fontSize: screenWidth * 0.04 * 1.5,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.03),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.25,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/logo.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Column(
                      children: [
                        _buildLabel("Enter password to delete account", screenWidth),
                        _buildInputField(
                          _passwordController,
                          _isPasswordHidden,
                              () => setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          }),
                          obscureText: _isPasswordHidden,
                          hintText: "Enter password",
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        ElevatedButton(
                          onPressed: _verifyPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VerifyPasswordScreen.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                              horizontal: screenWidth * 0.1,
                            ),
                          ),
                          child: Text(
                            "Delete",
                            style: TextStyle(
                              color: VerifyPasswordScreen.textColor,
                              fontSize: fontSize * 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Color.fromRGBO(0, 0, 0, 0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: VerifyPasswordScreen.textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, double screenWidth) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: VerifyPasswordScreen.textColor,
          fontWeight: FontWeight.bold,
          fontSize: screenWidth * 0.044,
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller,
      bool isHidden,
      VoidCallback toggleVisibility, {
        bool obscureText = false,
        String? hintText,
      }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double inputHeight = constraints.maxWidth * 0.12;

        return Container(
          height: inputHeight,
          decoration: BoxDecoration(
            color: VerifyPasswordScreen.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              style: TextStyle(color: VerifyPasswordScreen.textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: VerifyPasswordScreen.textColor),
                suffixIcon: GestureDetector(
                  onTap: toggleVisibility,
                  child: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    color: VerifyPasswordScreen.textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}