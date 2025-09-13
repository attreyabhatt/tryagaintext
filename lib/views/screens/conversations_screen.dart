import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_client.dart';
import '../../models/suggestion.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String _situation = 'stuck_after_reply';
  final _conversationCtrl = TextEditingController();
  final _herInfoCtrl = TextEditingController();
  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isExtractingImage = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // Initialize API client
  final _apiClient = ApiClient('https://tryagaintext.com');

  Future<void> _generateSuggestions() async {
    if (_situation != 'just_matched' && _conversationCtrl.text.trim().isEmpty) {
      _showError('Please paste the conversation first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
    });

    try {
      final suggestions = await _apiClient.generate(
        lastText: _situation == 'just_matched'
            ? 'just_matched'
            : _conversationCtrl.text,
        situation: _situation,
        herInfo: _situation == 'just_matched' ? _herInfoCtrl.text : '',
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate suggestions: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadScreenshot() async {
    try {
      // Show bottom sheet with options
      final ImageSource? source = await _showImageSourceSheet();
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Compress slightly for faster upload
      );

      if (image == null) return;

      setState(() {
        _isExtractingImage = true;
        _errorMessage = null;
      });

      // Extract conversation from image using API
      final extractedConversation = await _apiClient.extractFromImage(
        File(image.path),
      );

      // Update the conversation text field
      setState(() {
        _conversationCtrl.text = extractedConversation;
        _isExtractingImage = false;
        _suggestions = []; // Clear previous suggestions
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation extracted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isExtractingImage = false;
        _errorMessage = 'Failed to extract conversation: ${e.toString()}';
      });
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _copySuggestion(String message) {
    // You can add clipboard functionality here if needed
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Suggestion copied!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TryAgainText'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_isLoading || _isExtractingImage)
            ? null
            : _generateSuggestions,
        label: Text(
          _isLoading
              ? 'Generating...'
              : _isExtractingImage
              ? 'Extracting...'
              : 'Generate Reply',
        ),
        icon: (_isLoading || _isExtractingImage)
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.whatshot),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'just_matched', label: Text('Just matched')),
              ButtonSegment(
                value: 'stuck_after_reply',
                label: Text('Help with message'),
              ),
              ButtonSegment(value: 'left_on_read', label: Text('Left on read')),
            ],
            selected: {_situation},
            onSelectionChanged: (s) => setState(() {
              _situation = s.first;
              _suggestions = []; // Clear suggestions when switching modes
              _errorMessage = null;
            }),
          ),
          const SizedBox(height: 20.0),

          if (_situation == 'just_matched') ...[
            const SizedBox(height: 20.0),
            TextField(
              controller: _herInfoCtrl,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Has a cat. Loves poems.',
                labelText: "Her info (bio/hobbies/vibe) - Optional",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20.0),
          ],

          if (_situation != 'just_matched') ...[
            Row(
              children: [
                const Text('Paste chat or '),
                TextButton.icon(
                  onPressed: _isExtractingImage ? null : _uploadScreenshot,
                  icon: _isExtractingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image),
                  label: Text(
                    _isExtractingImage ? 'Extracting...' : 'Select screenshot',
                  ),
                ),
              ],
            ),
            TextField(
              controller: _conversationCtrl,
              minLines: 5,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: _situation == 'stuck_after_reply'
                    ? "you: How was your day?\nher: It was great"
                    : "you: hey, free thursday?\nher: (seen, no reply)",
                border: const OutlineInputBorder(),
                suffixIcon: _conversationCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _conversationCtrl.clear();
                            _suggestions = [];
                          });
                        },
                        tooltip: 'Clear conversation',
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20.0),
          ],

          const Text(
            'Suggestions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),

          if (_errorMessage != null) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating suggestions...'),
                  ],
                ),
              ),
            ),
          ] else if (_isExtractingImage) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Extracting conversation from image...'),
                  ],
                ),
              ),
            ),
          ] else if (_suggestions.isEmpty && _errorMessage == null) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No suggestions generated yet.\nFill in the details above and tap "Generate Reply".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ] else ...[
            ..._suggestions
                .map(
                  (suggestion) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        suggestion.message,
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: _getConfidenceColor(suggestion.confidence),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Confidence: ${(suggestion.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: _getConfidenceColor(suggestion.confidence),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copySuggestion(suggestion.message),
                        tooltip: 'Copy suggestion',
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                )
                .toList(),
          ],

          // Add some bottom padding so FAB doesn't overlap content
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _conversationCtrl.dispose();
    _herInfoCtrl.dispose();
    super.dispose();
  }
}
