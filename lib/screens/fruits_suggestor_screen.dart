import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FruitsSuggestorScreen extends StatefulWidget {
  const FruitsSuggestorScreen({Key? key}) : super(key: key);

  @override
  State<FruitsSuggestorScreen> createState() => _FruitsSuggestorScreenState();
}

class _UserProfile {
  final String name;
  final String? photoUrl;
  _UserProfile({required this.name, this.photoUrl});
}

class _FruitsSuggestorScreenState extends State<FruitsSuggestorScreen> {
  final TextEditingController _peopleController = TextEditingController(text: '1');
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  bool _fetching = true;
  bool _isTyping = false;
  String orderSummary = '';
  String nutrients = '';
  bool _showOrderPanel = true;
  bool _showJumpToBottom = false;
  _UserProfile? _userProfile;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInputError = '';

  final List<String> _suggestions = [
    'What fruits are good for summer?',
    'Suggest fruits for diabetes',
    'Best fruits for kids',
    'Fruits for weight loss',
    'Fruits for glowing skin',
    'Seasonal fruits in India',
    'High vitamin C fruits',
    'Low sugar fruits',
  ];
  String _lastUserQuestion = '';
  String _lastLanguage = 'en';

  // Add fallback suggestions for errors
  final List<String> _fallbackSuggestions = [
    'What fruits are good for immunity?',
    'Suggest fruits for weight loss',
    'Best fruits for kids',
    'Fruits for diabetes',
    'Fruits for glowing skin',
    'Seasonal fruits in India',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadUserProfile();
    _loadMessages().then((_) async {
      if (_messages.isEmpty) {
        await _showDefaultRecommendationBasedOnRecentOrders();
      }
    });
    _fetchOrderSummaryAndNutrients();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _peopleController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent - 40;
    if (_showJumpToBottom == atBottom) {
      setState(() {
        _showJumpToBottom = !atBottom;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String name = user.displayName ?? '';
    String? photoUrl = user.photoURL;
    if (name.isEmpty) {
      // Try Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        name = doc.data()?['name'] ?? '';
        photoUrl = doc.data()?['photoUrl'] ?? photoUrl;
      }
    }
    setState(() {
      _userProfile = _UserProfile(name: name.isNotEmpty ? name : 'User', photoUrl: photoUrl);
    });
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('fruits_suggestor_messages');
      if (messagesJson != null) {
        final List<dynamic> messagesList = jsonDecode(messagesJson);
        setState(() {
          _messages.clear();
          _messages.addAll(messagesList.map((m) => _ChatMessage.fromJson(m)));
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = jsonEncode(_messages.map((m) => m.toJson()).toList());
      await prefs.setString('fruits_suggestor_messages', messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  Future<void> _clearMessages() async {
    setState(() {
      _messages.clear();
    });
    await _saveMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchOrderSummaryAndNutrients() async {
    setState(() { _fetching = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          orderSummary = 'Not logged in.';
          nutrients = '-';
          _fetching = false;
        });
        return;
      }
      // Fetch last 5 orders
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();
      final orders = ordersSnap.docs.map((doc) => doc.data()).toList();
      // Aggregate fruit quantities
      final Map<String, int> fruitQuantities = {};
      for (final order in orders) {
        final items = order['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final name = item['name'] ?? '';
          final quantity = item['quantity'] ?? 0;
          if (name.isNotEmpty) {
            fruitQuantities[name] = (fruitQuantities[name] ?? 0) + (quantity is int ? quantity : int.tryParse(quantity.toString()) ?? 0);
          }
        }
      }
      // Build order summary string
      orderSummary = fruitQuantities.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      // Set nutrients to empty since AI will calculate
      nutrients = 'AI will analyze nutrition based on your orders';
      setState(() { _fetching = false; });
    } catch (e) {
      setState(() {
        orderSummary = 'Error fetching orders.';
        nutrients = '-';
        _fetching = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final userMessage = _chatController.text.trim();
    if (userMessage.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(user: true, text: userMessage, timestamp: DateTime.now()));
      _loading = true;
      _isTyping = true;
      _chatController.clear();
    });
    _saveMessages();
    _scrollToBottom();
    FocusScope.of(context).requestFocus(_inputFocusNode);
    setState(() {
      _lastUserQuestion = userMessage;
      _lastLanguage = _detectLanguage(userMessage);
    });
    try {
      final response = await http.post(
        Uri.parse('https://asia-south1-super-fruit-center-69794.cloudfunctions.net/deepseekSuggestor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderSummary': orderSummary,
          'peopleCount': int.tryParse(_peopleController.text) ?? 1,
          'userMessage': userMessage,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = (data['answer'] ?? '').trim();
        setState(() {
          _messages.add(_ChatMessage(
            user: false,
            text: answer.isNotEmpty
              ? answer
              : "Sorry, I couldn't generate a suggestion right now. Please try again or ask a different question!",
            timestamp: DateTime.now(),
            isFallback: data['fallback'] ?? false,
          ));
        });
        _saveMessages();
        _scrollToBottom();
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _messages.add(_ChatMessage(
            user: false, 
            text: 'Error: ${errorData['error'] ?? 'Unknown error occurred'}',
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
        _saveMessages();
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(user: false, text: 'Error: $e', timestamp: DateTime.now(), isError: true));
      });
      _saveMessages();
      _scrollToBottom();
    } finally {
      setState(() {
        _loading = false;
        _isTyping = false;
      });
    }
  }

  Future<void> _showDefaultRecommendation() async {
    setState(() {
      _loading = true;
      _isTyping = true;
    });
    try {
      final response = await http.post(
        Uri.parse('https://asia-south1-super-fruit-center-69794.cloudfunctions.net/deepseekSuggestor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderSummary': '',
          'peopleCount': 1,
          'userMessage': 'Suggest some healthy fruits to add in my day to day life for a balanced diet. Give a short, friendly answer.',
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(_ChatMessage(
            user: false,
            text: data['answer'] ?? 'No answer.',
            timestamp: DateTime.now(),
            isFallback: data['fallback'] ?? false,
          ));
        });
        _saveMessages();
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(user: false, text: 'Error: $e', timestamp: DateTime.now(), isError: true));
      });
      _saveMessages();
      _scrollToBottom();
    } finally {
      setState(() {
        _loading = false;
        _isTyping = false;
      });
    }
  }

  Future<void> _showDefaultRecommendationBasedOnRecentOrders() async {
    setState(() {
      _loading = true;
      _isTyping = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _messages.add(_ChatMessage(
            user: false,
            text: 'Please log in to get personalized fruit recommendations.',
            timestamp: DateTime.now(),
            isFallback: true,
          ));
        });
        _saveMessages();
        _scrollToBottom();
        return;
      }
      // Fetch all orders for the user
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();
      final now = DateTime.now();
      final List<Map<String, dynamic>> recentOrders = [];
      final List<Map<String, dynamic>> allOrders = [];
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        allOrders.add(data);
        final Timestamp? ts = data['created_at'] as Timestamp?;
        if (ts != null) {
          final orderDate = ts.toDate();
          if (now.difference(orderDate).inDays < 7) {
            recentOrders.add(data);
          }
        }
      }
      if (recentOrders.isNotEmpty) {
        // Build order summary string for the last 7 days
        final Map<String, int> fruitQuantities = {};
        for (final order in recentOrders) {
          final items = order['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            final name = item['name'] ?? '';
            final quantity = item['quantity'] ?? 0;
            if (name.isNotEmpty) {
              fruitQuantities[name] = (fruitQuantities[name] ?? 0) + (quantity is int ? quantity : int.tryParse(quantity.toString()) ?? 0);
            }
          }
        }
        final orderSummary = fruitQuantities.entries.map((e) => '${e.key}: ${e.value}').join(', ');
        // Ask AI for a recommendation based on recent orders
        final response = await http.post(
          Uri.parse('https://asia-south1-super-fruit-center-69794.cloudfunctions.net/deepseekSuggestor'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderSummary': orderSummary,
            'peopleCount': 1,
            'userMessage': 'Based on my recent fruit orders, what fruits should I add to my day to day life for a balanced diet? Give a short, friendly answer.',
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _messages.add(_ChatMessage(
              user: false,
              text: data['answer'] ?? 'No answer.',
              timestamp: DateTime.now(),
              isFallback: data['fallback'] ?? false,
            ));
          });
          _saveMessages();
          _scrollToBottom();
        }
      } else if (allOrders.isNotEmpty) {
        // There are orders, but none in the last 7 days
        setState(() {
          _messages.add(_ChatMessage(
            user: false,
            text: 'Please wait some time, I am analyzing your orders. If you have any other questions about fruits, feel free to ask!',
            timestamp: DateTime.now(),
            isFallback: true,
          ));
        });
        _saveMessages();
        _scrollToBottom();
      } else {
        // No orders at all
        setState(() {
          _messages.add(_ChatMessage(
            user: false,
            text: 'You have not placed any orders yet. Place an order or ask a question about fruits to get started!',
            timestamp: DateTime.now(),
            isFallback: true,
          ));
        });
        _saveMessages();
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(user: false, text: 'Error: $e', timestamp: DateTime.now(), isError: true));
      });
      _saveMessages();
      _scrollToBottom();
    } finally {
      setState(() {
        _loading = false;
        _isTyping = false;
      });
    }
  }

  Future<void> _clearMessagesWithConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _clearMessages();
      await _showDefaultRecommendation();
    }
  }

  String _detectLanguage(String text) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(text) ? 'hi' : 'en';
  }

  void _switchLanguage() {
    if (_lastUserQuestion.isEmpty) return;
    String newLang = _lastLanguage == 'en' ? 'hi' : 'en';
    String prompt = newLang == 'en'
        ? 'Answer this in English: $_lastUserQuestion'
        : 'इसका उत्तर हिंदी में दो: $_lastUserQuestion';
    _chatController.text = prompt;
    FocusScope.of(context).requestFocus(_inputFocusNode);
  }

  void _followUpOnLastAI() {
    if (_messages.isEmpty) return;
    final lastAI = _messages.lastWhere((m) => !m.user, orElse: () => _ChatMessage(user: false, text: '', timestamp: DateTime.now()));
    if (lastAI.text.isNotEmpty) {
      _chatController.text = 'Tell me more about: ${lastAI.text.split('\n').first}';
      FocusScope.of(context).requestFocus(_inputFocusNode);
    }
  }

  Future<void> _startListening() async {
    _voiceInputError = '';
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _voiceInputError = error.errorMsg ?? 'Voice input error';
        });
      },
    );
    if (available) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _chatController.text = result.recognizedWords;
          });
        },
        localeId: _lastLanguage == 'hi' ? 'hi_IN' : 'en_IN',
      );
    } else {
      setState(() {
        _isListening = false;
        _voiceInputError = 'Speech recognition unavailable';
      });
    }
  }
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_userProfile?.photoUrl != null)
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(_userProfile!.photoUrl!),
                radius: 16,
              )
            else
              const CircleAvatar(
                child: Icon(Icons.person, size: 18),
                radius: 16,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _userProfile?.name ?? 'Fruits Suggestor',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Chat',
            onPressed: _clearMessagesWithConfirmation,
          ),
        ],
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Collapsible Order Panel (no nutrients)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _showOrderPanel ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: GestureDetector(
                    onTap: () => setState(() => _showOrderPanel = false),
                    child: Card(
                      margin: const EdgeInsets.all(12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 18),
                                const SizedBox(width: 8),
                                const Text('Your Recent Orders', style: TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.expand_less),
                                  onPressed: () => setState(() => _showOrderPanel = false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(orderSummary, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  secondChild: GestureDetector(
                    onTap: () => setState(() => _showOrderPanel = true),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.expand_more),
                          SizedBox(width: 8),
                          Text('Show Recent Orders', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _messages.isEmpty
                          ? _buildWelcomeMessage()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length && _isTyping) {
                                  return _buildTypingIndicator();
                                }
                                final msg = _messages[index];
                                return RepaintBoundary(
                                  child: _buildMessageBubble(msg),
                                );
                              },
                            ),
                      if (_showJumpToBottom)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.green,
                            onPressed: _scrollToBottom,
                            child: const Icon(Icons.arrow_downward, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_loading)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const LinearProgressIndicator(minHeight: 2),
                  ),
                // Always show suggestion chips and chat input
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_suggestions.isNotEmpty)
                          Container(
                            height: 44,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _suggestions.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, i) => ActionChip(
                                label: Text(_suggestions[i]),
                                onPressed: () {
                                  _chatController.text = _suggestions[i];
                                  _sendMessage();
                                },
                                backgroundColor: Colors.green[50],
                                labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            if (_lastUserQuestion.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.language),
                                label: Text(_lastLanguage == 'en' ? 'Ask in Hindi' : 'Ask in English'),
                                onPressed: _switchLanguage,
                              ),
                            if (_messages.any((m) => !m.user))
                              TextButton.icon(
                                icon: const Icon(Icons.question_answer),
                                label: const Text('Follow up'),
                                onPressed: _followUpOnLastAI,
                              ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                  maxHeight: 120,
                                ),
                                child: TextField(
                                  controller: _chatController,
                                  focusNode: _inputFocusNode,
                                  minLines: 1,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: 'Ask anything about fruits...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    suffixIcon: IconButton(
                                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey),
                                      onPressed: _isListening ? _stopListening : _startListening,
                                      tooltip: _isListening ? 'Stop Listening' : 'Voice Input',
                                    ),
                                  ),
                                  enabled: !_loading,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FloatingActionButton(
                              onPressed: _loading ? null : _sendMessage,
                              mini: true,
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                        if (_voiceInputError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _voiceInputError,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Welcome to the Fruits Suggestor!',
            style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about fruits, nutrition, or get personalized recommendations.',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.user;
    final isError = msg.isError;
    final isFallback = msg.isFallback;
    Color bubbleColor;
    Color textColor;
    if (isUser) {
      bubbleColor = Colors.green[100]!;
      textColor = Colors.black87;
    } else if (isError) {
      bubbleColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
    } else if (isFallback) {
      bubbleColor = Colors.orange[50]!;
      textColor = Colors.orange[900]!;
    } else {
      bubbleColor = Colors.grey[100]!;
      textColor = Colors.black87;
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isError
              ? Border.all(color: Colors.red[200]!)
              : isFallback
                  ? Border.all(color: Colors.orange[200]!)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError)
              Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 32, semanticLabel: 'Error'),
                  const SizedBox(height: 8),
                  Text(
                    'Oops! Something went wrong.',
                    style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 16),
                    semanticsLabel: 'Error message',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.text,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                    semanticsLabel: 'Error details',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                    onPressed: () {
                      // Retry last user message
                      if (_lastUserQuestion.isNotEmpty) {
                        _chatController.text = _lastUserQuestion;
                        _sendMessage();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _fallbackSuggestions.map((s) => ActionChip(
                      label: Text(s),
                      onPressed: () {
                        _chatController.text = s;
                        _sendMessage();
                      },
                      backgroundColor: Colors.red[50],
                      labelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    )).toList(),
                  ),
                ],
              )
            else if (isFallback)
              Column(
                children: [
                  Icon(Icons.help_outline, color: Colors.orange[400], size: 32, semanticLabel: 'Fallback'),
                  const SizedBox(height: 8),
                  Text(
                    'I couldn\'t find a specific answer.',
                    style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 16),
                    semanticsLabel: 'Fallback message',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.text,
                    style: TextStyle(color: Colors.orange[900], fontSize: 14),
                    semanticsLabel: 'Fallback details',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _fallbackSuggestions.map((s) => ActionChip(
                      label: Text(s),
                      onPressed: () {
                        _chatController.text = s;
                        _sendMessage();
                      },
                      backgroundColor: Colors.orange[50],
                      labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                    )).toList(),
                  ),
                ],
              )
            else ...[
              if (!isUser)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: msg.text));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 18),
                      tooltip: 'Share',
                      onPressed: () => Share.share(msg.text),
                    ),
                  ],
                ),
              !isUser
                  ? MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: textColor, fontSize: 15),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : Text(
                      msg.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(msg.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI is thinking...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _ChatMessage {
  final bool user;
  final String text;
  final DateTime timestamp;
  final bool isError;
  final bool isFallback;

  _ChatMessage({
    required this.user, 
    required this.text, 
    required this.timestamp,
    this.isError = false,
    this.isFallback = false,
  });

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
    user: json['user'],
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    isError: json['isError'] ?? false,
    isFallback: json['isFallback'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'user': user,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
    'isFallback': isFallback,
  };
} 