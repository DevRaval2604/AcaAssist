import 'dart:convert';
import 'package:aca_assist/secrets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class RecommendResourcesScreen extends StatefulWidget {
  static const Color backgroundColor = Color(0xFF5C6B7D);
  static const Color primaryColor = Color(0xFF8196B0);
  static const Color textColor = Color(0xFFD6E4F0);

  const RecommendResourcesScreen({super.key});

  @override
  RecommendResourcesScreenState createState() =>
      RecommendResourcesScreenState();
}

class RecommendResourcesScreenState extends State<RecommendResourcesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedSubject;
  bool _isLoading = false; // This will track the loading state
  final TextEditingController _topicController = TextEditingController();
  List<String> _recommendedResources = [];

  Future<void> _recommendResources() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a subject."),
          backgroundColor: RecommendResourcesScreen.primaryColor,
        ),
      );
    } else {
      String topic = _topicController.text.trim();

      // Show the loading spinner
      setState(() {
        _isLoading = true;
      });

      // Fetch resources from the API
      List<String> resources = await _fetchResourcesFromAPI(_selectedSubject!, topic);

      // Hide the loading spinner once data is fetched
      setState(() {
        _isLoading = false;
        _recommendedResources = resources;
      });

      // Check if resources were found
      if (_recommendedResources.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No resources found for the selected subject/topic."),
              backgroundColor: RecommendResourcesScreen.primaryColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Resources recommended successfully!"),
              backgroundColor: RecommendResourcesScreen.primaryColor,
            ),
          );
        }
      }
    }
  }

  Future<List<String>> _fetchResourcesFromAPI(String subject, String topic) async {
    List<String> resources = [];
    String youtubeApiKey = Secrets.youtubeApiKey;
    String youtubeSearchUrl = '';
    String query = Uri.encodeComponent(subject);

    if (topic.isNotEmpty) {
      query += " ${Uri.encodeComponent(topic)}";
    }

    // Determine search type based on topic presence
    if (topic.isNotEmpty) {
      youtubeSearchUrl =
      "https://www.googleapis.com/youtube/v3/search?part=id&q=$query&type=video&order=relevance&key=$youtubeApiKey";
    } else {
      youtubeSearchUrl =
      "https://www.googleapis.com/youtube/v3/search?part=id&q=$query&type=channel&order=relevance&key=$youtubeApiKey";
    }

    try {
      final searchResponse = await http.get(Uri.parse(youtubeSearchUrl)).timeout(Duration(seconds: 15));

      if (searchResponse.statusCode == 200) {
        Map<String, dynamic> searchData = jsonDecode(searchResponse.body);
        if (searchData.containsKey('items') && searchData['items'] is List) {
          List<dynamic> items = searchData['items'];
          List<String> ids = [];

          if (topic.isNotEmpty) {
            for (var item in items) {
              if (item['id'] != null && item['id']['videoId'] != null) {
                ids.add(item['id']['videoId']);
              }
            }
          } else {
            for (var item in items) {
              if (item['id'] != null && item['id']['channelId'] != null) {
                ids.add(item['id']['channelId']);
              }
            }
          }

          if (ids.isNotEmpty) {
            String idString = ids.join(',');

            // New logic to get video details and filter by privacy status
            if (topic.isNotEmpty) {
              final videoDetailsUrl = "https://www.googleapis.com/youtube/v3/videos?part=status,statistics&id=$idString&key=$youtubeApiKey";
              final videoDetailsResponse = await http.get(Uri.parse(videoDetailsUrl));

              if (videoDetailsResponse.statusCode == 200) {
                Map<String, dynamic> videoDetailsData = jsonDecode(videoDetailsResponse.body);
                List<dynamic> videoItems = videoDetailsData['items'];

                // Sort by view count in descending order
                videoItems.sort((a, b) {
                  int viewsA = int.tryParse(a['statistics']['viewCount'] ?? '0') ?? 0;
                  int viewsB = int.tryParse(b['statistics']['viewCount'] ?? '0') ?? 0;
                  return viewsB.compareTo(viewsA);
                });

                for (var videoItem in videoItems.take(5)) {
                  String privacyStatus = videoItem['status']['privacyStatus'];
                  if (privacyStatus == 'public') {
                    String videoUrl = "https://www.youtube.com/watch?v=${videoItem['id']}";
                    resources.add(videoUrl);
                  }
                }
              }
            } else {
              // New logic for channels - check if channel exists and get view count
              final channelDetailsUrl = "https://www.googleapis.com/youtube/v3/channels?part=statistics&id=$idString&key=$youtubeApiKey";
              final channelDetailsResponse = await http.get(Uri.parse(channelDetailsUrl));

              if (channelDetailsResponse.statusCode == 200) {
                Map<String, dynamic> channelDetailsData = jsonDecode(channelDetailsResponse.body);
                List<dynamic> channelItems = channelDetailsData['items'];

                // Sort by view count in descending order
                channelItems.sort((a, b) {
                  int viewsA = int.tryParse(a['statistics']['viewCount'] ?? '0') ?? 0;
                  int viewsB = int.tryParse(b['statistics']['viewCount'] ?? '0') ?? 0;
                  return viewsB.compareTo(viewsA);
                });

                for (var channelItem in channelItems.take(5)) {
                  String channelUrl = "https://www.youtube.com/channel/${channelItem['id']}";
                  resources.add(channelUrl);
                }
              }
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load YouTube data. Status code: ${searchResponse.statusCode}'),
            backgroundColor: RecommendResourcesScreen.primaryColor,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching YouTube data: $e'),
          backgroundColor: RecommendResourcesScreen.primaryColor,
        ));
      }
    }

    // Now, add AI-generated resources (from your generative API)
    String prompt = "Recommend 5 relevant and available YouTube videos and 5 reliable websites for the subject '$subject'.";
    if (topic.isNotEmpty) {
      prompt += " The topic is '$topic'.";
    }
    prompt += "\nProvide only the resource links (strictly no descriptions or extra text).Only reply in the below format do not write anything else coz this is an api call";
    prompt += "\n\nPlease format the response as follows:";
    prompt += "\nFor each link, use this format: `1). ChannelName/WebsiteName - Link`";
    prompt += "\nThe YouTube links should be listed first and then the website links.";
    prompt += "\nPlease ensure the links provided are active and the resources are available.";
    prompt += "\nPlease return the links in a numbered list format with their corresponding names.";

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: Secrets.aiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 500,
        responseMimeType: 'text/plain',
      ),
    );

    final chat = model.startChat();
    final content = Content.text(prompt);
    final responseAI = await chat.sendMessage(content);

    void log(String message) {
      if (kDebugMode) {
        print(message);
      }
    }

    String resourcesText = responseAI.text?.trim() ?? '';
    if (resourcesText.isNotEmpty) {
      List<String> aiResources = _parseResources(resourcesText);

      // New logic to filter and validate website links
      List<String> verifiedWebsites = [];
      for (String resource in aiResources) {
        // Only check websites, YouTube links are handled above
        if (!resource.contains("youtube.com") && !resource.contains("youtu.be")) {
          try {
            final RegExp urlRegex = RegExp(r'(https?://\S+)');
            final extractedUrl = urlRegex.firstMatch(resource)?.group(0);

            if (extractedUrl != null) {
              final uri = Uri.parse(extractedUrl);
              final response = await http.head(uri).timeout(Duration(seconds: 5));
              // Check for a 200 OK status code. You can add other success codes if needed.
              if (response.statusCode == 200) {
                verifiedWebsites.add(resource);
              }
            }
          } catch (e) {
            // Ignore resources that fail the check (e.g., network issues, invalid URL)
            log('Skipping resource due to error: $e');
          }
        }
      }
      resources.addAll(verifiedWebsites);
    }

    // Limit the total resources to 10 if you want
    if (resources.length > 10) {
      return resources.take(10).toList();
    }

    return resources;
  }

  // Method to parse the response into resource links
  List<String> _parseResources(String resourcesText) {
    List<String> resources = [];

    // Split the response into lines
    List<String> lines = resourcesText.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        resources.add(line);
      }
    }

    return resources;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: RecommendResourcesScreen.backgroundColor,
      appBar: AppBar(
        backgroundColor: RecommendResourcesScreen.backgroundColor,
        iconTheme: IconThemeData(color: RecommendResourcesScreen.textColor),
        elevation: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Text(
            "Recommend Resources",
            style: TextStyle(
              color: RecommendResourcesScreen.textColor,
              fontSize: fontSize * 1.5,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main content scrollable view
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
                        _buildLabel("Select Subject", fontSize),
                        _buildDropdownField(),
                        SizedBox(height: screenHeight * 0.03),
                        if (_selectedSubject != null) ...[
                          _buildLabel("Enter Topic Name (Optional)", fontSize),
                          _buildInputField(_topicController, "Enter topic name"),
                          SizedBox(height: screenHeight * 0.03),
                        ],
                        ElevatedButton(
                          onPressed: _recommendResources,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RecommendResourcesScreen.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                              horizontal: screenWidth * 0.1,
                            ),
                          ),
                          child: Text(
                            "Recommend Resources",
                            style: TextStyle(
                              color: RecommendResourcesScreen.textColor,
                              fontSize: fontSize * 1.1,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        // Always include a SizedBox to keep the height of the Card, even if it's empty
                        SizedBox(
                          height: _recommendedResources.isNotEmpty ? screenHeight * 0.4 : screenHeight * 0.4,
                          child: _recommendedResources.isNotEmpty
                              ? Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                              horizontal: screenWidth * 0.01,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: RecommendResourcesScreen.primaryColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      "Recommended Resources",
                                      style: TextStyle(
                                        color: RecommendResourcesScreen.textColor,
                                        fontSize: fontSize * 1.3,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Divider(
                                    color: RecommendResourcesScreen.textColor,
                                    thickness: 1,
                                    indent: 0,
                                    endIndent: 0,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Expanded(
                                    child: Scrollbar(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: _recommendedResources.map((resource) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final RegExp urlRegex = RegExp(r'(https?://\S+)');
                                                  final extractedUrl = urlRegex.firstMatch(resource)?.group(0);

                                                  if (extractedUrl == null) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text("Invalid link format."),
                                                          backgroundColor: RecommendResourcesScreen.primaryColor,
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }
                                                  final Uri uri = Uri.parse(extractedUrl);
                                                  if (await canLaunchUrl(uri)) {
                                                    // If the resource is a YouTube link, launch it in the YouTube app or external browser
                                                    if (resource.contains("youtube.com") || resource.contains("youtu.be")) {
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    } else {
                                                      // Otherwise, treat it as a regular website and launch it in the browser
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    }
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text("Could not open the link."),
                                                          backgroundColor: RecommendResourcesScreen.primaryColor,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: Text(
                                                  resource,
                                                  style: TextStyle(
                                                    color: RecommendResourcesScreen.textColor,
                                                    fontSize: fontSize,
                                                    decoration: resource.contains("http") ? TextDecoration.underline : null,
                                                    decorationColor: RecommendResourcesScreen.textColor,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              : Container(), // If resources are not present, show an empty container
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Show loading overlay if _isLoading is true
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Color.fromRGBO(0, 0, 0, 0.5), // Semi-transparent black overlay
                child: Center(
                  child: CircularProgressIndicator(
                    color: RecommendResourcesScreen.textColor, // Centered loader
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, double fontSize) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: RecommendResourcesScreen.textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize * 1.1,
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double inputHeight = constraints.maxWidth * 0.12;

        return Container(
          height: inputHeight,
          decoration: BoxDecoration(
            color: RecommendResourcesScreen.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextFormField(
              controller: controller,
              style: TextStyle(color: RecommendResourcesScreen.textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: RecommendResourcesScreen.textColor),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownField() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Users')
          .doc(_auth.currentUser?.uid)
          .collection('StudySchedule')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: RecommendResourcesScreen.textColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No subjects added yet.",
              style: TextStyle(color: RecommendResourcesScreen.textColor),
            ),
          );
        }

        List<String> subjects = snapshot.data!.docs
            .map((doc) => doc['SubjectName'] as String)
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            double inputHeight = constraints.maxWidth * 0.12;

            return GestureDetector(
              onTap: () {},
              child: Container(
                height: inputHeight,
                decoration: BoxDecoration(
                  color: RecommendResourcesScreen.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButton<String>(
                    dropdownColor: RecommendResourcesScreen.primaryColor,
                    value: _selectedSubject,
                    hint: Text(
                      'Select a subject',
                      style: TextStyle(
                        color: RecommendResourcesScreen.textColor,
                        fontSize: constraints.maxWidth * 0.04,
                      ),
                    ),
                    isExpanded: true,
                    style: TextStyle(color: RecommendResourcesScreen.textColor),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                    },
                    items: subjects
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.04,
                          ),
                        ),
                      );
                    }).toList(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: RecommendResourcesScreen.textColor,
                    ),
                    underline: SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}