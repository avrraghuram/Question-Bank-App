import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiChatWidget extends StatefulWidget {
  const AiChatWidget({super.key});

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  bool _loading = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  Future<void> _toggleOpen() async {
    setState(() {
      _open = !_open;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _controller.clear();
      _loading = true;
    });
    _scrollToBottom();
    try {
      final reply = await _sendToBackend(text);
      setState(() {
        _messages.add({'sender': 'assistant', 'text': reply});
      });
    } catch (_) {
      setState(() {
        _messages.add({
          'sender': 'assistant',
          'text': 'AI is unavailable right now. Please try again later.'
        });
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  Future<String> _sendToBackend(String message) async {
    final uri = Uri.parse('http://127.0.0.1:8080/api/ai');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode != 200) {
      throw StateError('Backend request failed');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return payload['reply']?.toString() ?? 'No reply received.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 64 : 12,
        right: isUser ? 12 : 64,
        top: 8,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue.shade700 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _open ? 360 : 64,
          height: _open ? 520 : 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_open ? 24 : 32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: _open ? _buildChatWindow(context) : _buildFloatingBubble(),
        ),
      ),
    );
  }

  Widget _buildFloatingBubble() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: _toggleOpen,
        splashColor: Colors.blue.withOpacity(0.15),
        child: const Center(
          child: Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Study AI Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleOpen,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _messages.isEmpty && !_loading
                  ? const Center(
                      child: Text(
                        'Ask your GCSE helper a question.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_loading && index == _messages.length) {
                          return _buildChatBubble('AI is thinking...', false);
                        }
                        final message = _messages[index];
                        final isUser = message['sender'] == 'user';
                        return _buildChatBubble(message['text'] ?? '', isUser);
                      },
                    ),
            ),
          ),
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a keyword or question...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
