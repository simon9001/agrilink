import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:story_view/story_view.dart';

import '../../../core/app_export.dart';

class StoryViewerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final VoidCallback onComplete;

  const StoryViewerWidget({
    Key? key,
    required this.stories,
    required this.initialIndex,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<StoryViewerWidget> createState() => _StoryViewerWidgetState();
}

class _StoryViewerWidgetState extends State<StoryViewerWidget> {
  final StoryController _storyController = StoryController();
  late PageController _pageController;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _storyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<StoryItem> _buildStoryItems(Map<String, dynamic> storyData) {
    final List<dynamic> storyItems = storyData['stories'] as List<dynamic>;
    return storyItems.map((item) {
      final Map<String, dynamic> storyItem = item as Map<String, dynamic>;
      return StoryItem.pageImage(
        url: storyItem['imageUrl'] as String,
        controller: _storyController,
        caption: Text(
          storyItem['caption'] as String? ?? '',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            shadows: [
              const Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 5),
      );
    }).toList();
  }

  Widget _buildStoryHeader(Map<String, dynamic> storyData) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: storyData['profileImage'] as String,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storyData['username'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      const Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                Text(
                  storyData['timeAgo'] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    shadows: [
                      const Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onComplete,
            child: CustomIconWidget(
              iconName: 'close',
              color: Colors.white,
              size: 7.w,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          onPageChanged: (index) {
            setState(() {
              _currentStoryIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final storyData = widget.stories[index];
            return Stack(
              children: [
                StoryView(
                  storyItems: _buildStoryItems(storyData),
                  controller: _storyController,
                  onComplete: () {
                    if (index < widget.stories.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      widget.onComplete();
                    }
                  },
                  onVerticalSwipeComplete: (direction) {
                    if (direction == Direction.down) {
                      widget.onComplete();
                    }
                  },
                  onStoryShow: (storyItem, index) {
                    // Handle story show event
                  },
                  progressPosition: ProgressPosition.top,
                  repeat: false,
                  inline: false,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildStoryHeader(storyData),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
