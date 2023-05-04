library story_viewer;

export 'package:story_viewer/src/story.dart';

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:story_viewer/src/story.dart';
import 'package:video_player/video_player.dart';

class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  const StoryViewer({Key? key, required this.stories}) : super(key: key);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  bool preparingControllers = false;
  List<Story> stories = [];
  PageController pageController = PageController();
  Map<Story, VideoPlayerController> videoControllers = {};
  Timer? storyTimer;
  int storyTimerValue = 0;
  int currentStory = 0;

  @override
  void initState() {
    super.initState();
    stories = widget.stories;
    populateControllers();
    initiateTimer();
  }

  @override
  void dispose(){
    videoControllers.forEach((key, value) => value.dispose());
    super.dispose();
  }

  void populateControllers(){
    preparingControllers = true;
    stories.map((story){
      videoControllers[story] = VideoPlayerController.network(story.storyUrl);
    });
    preparingControllers = false;
  }

  void initiateTimer(){
    storyTimerValue = 0;
    storyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      storyTimerValue += 1;

      /// TODO: Change Timer to dynamic value or length of video in-case
      if (storyTimerValue >= 5){

        /// Cancel current timer on '5
        storyTimer?.cancel();

        /// Move to the next story
        currentStory += 1;
        debugPrint("Current Story: $currentStory");
        pageController.animateToPage(
          currentStory,
          duration: const Duration(seconds: 1),
          curve: Curves.easeIn
        );

        /// Restart the Timer while the currentStory is not the last.
        /// if its the last, the timer just gets cancelled and ends
        if (currentStory < stories.length){
          initiateTimer();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(stories.length.toString());
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue
      ),
      child: PageView.builder(
        // physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        itemCount: stories.length,
        onPageChanged: (value){
          currentStory = value;
          storyTimer?.cancel();
          initiateTimer();
        },
        itemBuilder: (context, index){
          if (stories[index].storyType == StoryType.image){
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black
              ),
              child: CachedNetworkImage(
                imageUrl: stories[index].storyUrl,
                progressIndicatorBuilder: (_, info, progress){
                  return CircularProgressIndicator(value: progress.progress,);
                },
                /// TODO: Add Error Image: When Image cannot load
              ),
            );
          } else if (stories[index].storyType == StoryType.video){
              return videoControllers[stories[index]] != null
                ? VideoPlayer(videoControllers[stories[index]]!)
                : Container(
                decoration: const BoxDecoration(
                  color: Colors.black
                ),
                child: const Text("Cannot display content: Couldn't initiate Controller"),
              );
          } else {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black
              ),
              child: const Text("Cannot display content: Format not supported"),
            );
          }

        }
      ),
    );
  }
}

