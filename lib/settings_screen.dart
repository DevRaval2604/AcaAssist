import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package
import 'profile_screen.dart';
import 'verify_password_screen.dart';
import 'home_screen.dart'; // Import HomeScreen
import 'change_password_screen.dart'; // Import ChangePasswordScreen
import 'set_password_screen.dart'; // Import SetPasswordScreen
import 'about_us_screen.dart'; // Import AboutUsScreen
import 'contact_us_screen.dart'; // Import ContactUsScreen
import 'study_schedule_screen.dart'; // Import the Study Schedule screen
import 'task_management_screen.dart'; // Import TaskManagementScreen
import 'analytics_screen.dart'; // Import AnalyticsScreen
import 'mic_screen.dart'; // Import MicScreen

class SettingsScreen extends StatefulWidget {
  static const Color backgroundColor = Color(0xFF5C6B7D);
  static const Color primaryColor = Color(0xFF8196B0);
  static const Color textColor = Color(0xFFD6E4F0);

  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 5; // Default to settings page
  String name = ""; // Variable to store the user's name
  String initials = ""; // Variable to store the user's initials
  bool isNotificationsEnabled = false; // Toggle to track notification setting

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          name = userDoc['Name'] ?? "Guest"; // Set the user's name (or "Guest" if not available)
          initials = _getInitials(name); // Set the initials based on the name
        });
      }
    }
  }

  // Function to extract initials from the name
  String _getInitials(String name) {
    return name.trim().isNotEmpty
        ? name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join()
        : "";
  }

  // Function to check if the user has a password set
  Future<bool> _checkIfUserHasPassword() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false; // No user is signed in
    }

    // Check if the user has email/password provider linked
    bool hasPassword = user.providerData.any((provider) => provider.providerId == 'password');

    return hasPassword;
  }

  // Navigate to the appropriate screen based on whether the user has a password
  void _goToManagePassword() async {
    bool hasPassword = await _checkIfUserHasPassword();

    // Check if the widget is still in the tree
    if (!mounted) return;

    // Navigate to the appropriate screen based on whether the user has a password
    if (hasPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetPasswordScreen()),
      );
    }
  }

  // Navigate to About Us screen
  void _goToAboutUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AboutUsScreen()), // Navigate to AboutUsScreen
    );
  }

  // Navigate to Contact Us screen
  void _goToContactUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactUsScreen()), // Navigate to ContactUsScreen
    );
  }

  void _confirmDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    final providers = user?.providerData;
    final hasPassword = providers?.any((p) => p.providerId == 'password') ?? false;

    if (!mounted) return;

    if (hasPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VerifyPasswordScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please set a password first to delete your account.'),
          backgroundColor: SettingsScreen.primaryColor,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SetPasswordScreen(),
        ),
      );
    }
  }

  // Dynamically adjust icon size based on screen width
  double getIconSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth * 0.10; // 10% of the screen width for icons
    return iconSize < 50 ? 50 : iconSize; // Ensure the minimum icon size
  }

  // Dynamically adjust AppBar height based on screen size
  double getAppBarHeight(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.08; // AppBar height will be 8% of the screen height
  }

  // Dynamically adjust font size based on screen width
  double getFontSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.07; // Font size will be 7% of the screen width
  }

  // Update selected icon when clicked
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Getting screen width and height
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    // Set icon size
    double iconSize = getIconSize(context);
    // Set AppBar height (same as BottomAppBar height)
    double appBarHeight = getAppBarHeight(context);
    // Set font size for title
    double fontSize = getFontSize(context);

    return Scaffold(
      backgroundColor: SettingsScreen.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: SettingsScreen.backgroundColor,
        iconTheme: IconThemeData(color: SettingsScreen.textColor),
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Settings",
                style: TextStyle(
                  color: SettingsScreen.textColor,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Profile Picture in AppBar (using initials)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                backgroundColor: SettingsScreen.primaryColor,
                radius: iconSize / 2, // Set size based on icon size
                child: Text(
                  initials,
                  style: TextStyle(
                    color: SettingsScreen.textColor,
                    fontSize: iconSize * 0.4, // Adjust font size based on icon size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main body content
          SingleChildScrollView(
            child: Column(
              children: [
                // Removed the box from Settings page as requested
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.3,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/logo.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.02,
                        ),
                        leading: Icon(Icons.lock, color: SettingsScreen.textColor, size: getIconSize(context) * 0.7),
                        title: Text("Set/Change Password", style: TextStyle(color: SettingsScreen.textColor, fontSize: getFontSize(context) * 0.7)),
                        onTap: _goToManagePassword, // Navigate to Change Password screen
                      ),
                      // New: Delete Account
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.02,
                        ),
                        leading: Icon(Icons.delete, color: SettingsScreen.textColor, size: getIconSize(context) * 0.7),
                        title: Text("Delete Account", style: TextStyle(color: SettingsScreen.textColor, fontSize: getFontSize(context) * 0.7)),
                        onTap: _confirmDeleteAccount, // Show delete confirmation dialog
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.02,
                        ),
                        leading: Icon(Icons.info, color: SettingsScreen.textColor, size: getIconSize(context) * 0.7),
                        title: Text("About Us", style: TextStyle(color: SettingsScreen.textColor, fontSize: getFontSize(context) * 0.7)),
                        onTap: _goToAboutUs, // Navigate to About Us screen
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.02,
                        ),
                        leading: Icon(Icons.contact_mail, color: SettingsScreen.textColor, size: getIconSize(context) * 0.7),
                        title: Text("Contact Us", style: TextStyle(color: SettingsScreen.textColor, fontSize: getFontSize(context) * 0.7)),
                        onTap: _goToContactUs, // Navigate to Contact Us screen
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: SettingsScreen.textColor,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home Icon
              GestureDetector(
                onTap: () {
                  _onItemTapped(0); // Manually set index
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()), // Navigate to Home screen
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _selectedIndex == 0 ? -10 : 0, 0),
                  child: SvgPicture.asset(
                    "assets/home_logo.svg",
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Tasks Icon
              GestureDetector(
                onTap: () {
                  _onItemTapped(1); // Manually set index
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TaskManagementScreen()), // Navigate to TaskManagementScreen
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _selectedIndex == 1 ? -10 : 0, 0),
                  child: SvgPicture.asset(
                    "assets/tasks_logo.svg",
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Goals Icon
              GestureDetector(
                onTap: () {
                  _onItemTapped(2); // Manually set index
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudyScheduleScreen()), // Navigate to StudyScheduleScreen
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _selectedIndex == 2 ? -10 : 0, 0),
                  child: SvgPicture.asset(
                    "assets/schedule_logo.svg",
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Analytics Icon
              GestureDetector(
                onTap: () {
                  _onItemTapped(3); // Manually set index
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()), // Navigate to AnalyticsScreen
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _selectedIndex == 3 ? -10 : 0, 0),
                  child: SvgPicture.asset(
                    "assets/analytics_logo.svg",
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Mic Icon
              GestureDetector(
                onTap: () {
                  _onItemTapped(4); // Manually set index
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MicScreen()), // Navigate to MicScreen
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _selectedIndex == 4 ? -10 : 0, 0),
                  child: SvgPicture.asset(
                    "assets/mic_logo.svg",
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Settings Icon (already in place)
              GestureDetector(
                onTap: () {
                  _onItemTapped(5); // Manually set index
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()), // Navigate to SettingsScreen
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _selectedIndex == 5 ? -10 : 0, 0),
                  child: SvgPicture.asset(
                    "assets/settings_logo.svg",
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
