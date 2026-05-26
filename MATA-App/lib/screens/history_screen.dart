import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../widgets/accessible_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/narrator_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _historyItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarratorService().speak("History screen. Your past learning sessions.", interrupt: true);
    });
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.getHistory();
      if (mounted) {
        setState(() {
          _historyItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NarratorService().playEarcon(Earcon.error);
        NarratorService().speak("Failed to load history.");
      }
    }
  }

  Future<void> _deleteItem(String sessionId, int index) async {
    try {
      await ApiService.deleteHistory(sessionId);
      if (mounted) {
        setState(() {
          _historyItems.removeAt(index);
        });
        NarratorService().playEarcon(Earcon.success);
        NarratorService().speak("Item deleted.");
      }
    } catch (e) {
      NarratorService().speak("Failed to delete item.");
    }
  }

  String _getEmojiForSubject(String subject) {
    String lower = subject.toLowerCase();
    if (lower.contains("math")) return "📐";
    if (lower.contains("science") || lower.contains("physics") || lower.contains("chemistry")) return "🔬";
    if (lower.contains("history")) return "🏛️";
    if (lower.contains("geography")) return "🌍";
    if (lower.contains("english") || lower.contains("literature")) return "📚";
    return "📄";
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        NarratorService().playEarcon(Earcon.navigate);
        NarratorService().speak("Filtered by $label");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryLight : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedFilter == 'All' 
        ? _historyItems 
        : _historyItems.where((item) => (item['subject'] ?? '').toString().toLowerCase().contains(_selectedFilter.toLowerCase())).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('History', style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text("Your past learning sessions.", style: AppTextStyles.bodyMd),
                ),
                
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      _buildFilterChip("All"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Math"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Science"),
                      const SizedBox(width: 8),
                      _buildFilterChip("History"),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : filteredItems.isEmpty
                          ? const Center(child: Text("No history available.", style: AppTextStyles.bodyMd))
                          : RefreshIndicator(
                              onRefresh: _fetchHistory,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final sessionId = item['id'];
                                  final dateStr = item['timestamp'].toString().substring(0, 10);
                                  final subject = item['subject'] ?? "General Session";
                                  final emoji = _getEmojiForSubject(subject);

                                  return Dismissible(
                                    key: Key(sessionId),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(20)),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    onDismissed: (_) => _deleteItem(sessionId, index),
                                    child: AccessibleWidget(
                                      label: "$subject. $dateStr. Double tap to review.",
                                      onActivate: () {
                                        NarratorService().playEarcon(Earcon.navigate);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ResultScreen(
                                              sessionId: sessionId,
                                              explanation: item['explanation'] ?? '',
                                              audioUrl: item['audio_url'],
                                              initialChatHistory: item['chat_history'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: GlassCard(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ResultScreen(
                                                sessionId: sessionId,
                                                explanation: item['explanation'] ?? '',
                                                audioUrl: item['audio_url'],
                                                initialChatHistory: item['chat_history'],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(subject, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 4),
                                                  Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.play_arrow_rounded, color: AppColors.primaryLight),
                                            )
                                          ],
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1),
                                  );
                                },
                              ),
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
