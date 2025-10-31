import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'calling_screen.dart';
import 'package:random_avatar/random_avatar.dart';
import '../services/api_service.dart';
import '../widgets/pranthora_loader.dart';

class Agent {
  final String id;
  String name;
  String description;
  final String? avatarUrl;
  String systemPrompt;
  double temperature;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    this.systemPrompt = 'You are a helpful AI assistant.',
    this.temperature = 0.7,
  });
  
  Agent copyWith({
    String? name,
    String? description,
    String? systemPrompt,
    double? temperature,
  }) {
    return Agent(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
    );
  }
}

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _titleAnimationStarted = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Agents data fetched from API
  List<Agent> _allAgents = [];

  List<Agent> _filteredAgents = [];

  @override
  void initState() {
    super.initState();
    _filteredAgents = [];
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    _searchController.addListener(_onSearchChanged);
    
    // Fetch agents from API
    _fetchAgents();
    
    // Start title animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _titleAnimationStarted = true;
        });
      }
    });
  }

  Future<void> _fetchAgents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final agentsData = await ApiService().getAgents();
      
      // Map API response to Agent objects
      final agents = agentsData.map((data) {
        // Handle nested agent structure from API response
        final agentData = data['agent'] ?? data;
        
        return Agent(
          id: agentData['id']?.toString() ?? '',
          name: agentData['name'] ?? 'Unnamed Agent',
          description: agentData['description'] ?? 'No description available',
          systemPrompt: agentData['system_prompt'] ?? 
                       agentData['systemPrompt'] ?? 
                       'You are a helpful AI assistant.',
          temperature: (agentData['temperature'] ?? 0.7).toDouble(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _allAgents = agents;
        _filteredAgents = agents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load agents: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredAgents = _allAgents.where((agent) {
        return agent.name.toLowerCase().contains(_searchQuery) ||
            agent.description.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  void _openCallScreen(String agentId) {
    final agent = _allAgents.firstWhere((a) => a.id == agentId);
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CallingScreen(
          agentName: agent.name,
          agentDescription: agent.description,
          agentId: agent.id,
          returnToAgents: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    _titleAnimationStarted
                        ? AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Assistants',
                                textStyle: const TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                speed: const Duration(milliseconds: 150),
                                cursor: '_',
                              ),
                            ],
                            totalRepeatCount: 1,
                          )
                        : const Text(
                            '',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                    const Spacer(),
                    Text(
                      '${_allAgents.length} agents',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search agents...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: Color(0x99FFFFFF),
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: Color(0x99FFFFFF),
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Agents List
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _filteredAgents.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _filteredAgents.length,
                                itemBuilder: (context, index) {
                                  return _buildAgentCard(_filteredAgents[index], index);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: PranthoraLoader(size: 90, showLabel: true),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 60,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchAgents,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No agents found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Agent agent, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _openCallScreen(agent.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1E1E),
                ),
                child: ClipOval(
                  child: RandomAvatar(
                    agent.id.isNotEmpty ? agent.id : agent.name,
                    height: 44,
                    width: 44,
                    trBackground: true,
                  ),
                ),
              ),
              // Agent Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0x99FFFFFF),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}