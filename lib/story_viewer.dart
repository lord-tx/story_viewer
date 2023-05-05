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
  Map<Story, double> progressController = {};
  Timer? storyTimer;
  int storyTimerValue = 0;
  int currentStoryIndex = 0;
  Story? currentStory;
  Story? previousStory;

  VideoPlayerController? controller;

  @override
  void initState() {
    super.initState();
    stories = widget.stories;
    populateControllers();
  }

  @override
  void dispose(){
    videoControllers.forEach((key, value) => value.dispose());
    super.dispose();
  }

  void populateControllers(){
    debugPrint("Starting Controllers");
    preparingControllers = true;
    for (Story story in stories){
      videoControllers[story] = VideoPlayerController.network(story.storyUrl);
      progressController[story] = 0.0;
      debugPrint("Setting Progress Controller: ${progressController[story]}");
      debugPrint("Setting Progress Controller For Story: $story");
    }
    if (stories.isNotEmpty){
      currentStory = stories.first;
    }
    preparingControllers = false;
    initiateTimer();
  //
  }

  /// NOTE: The progress value determines how long a story would be viewed for
  ///
  /// progressValue = 0.0 to 1.0.
  ///
  /// If this value is incremented by 0.02 per 100 milliseconds (i.e 0.1 second), the0
  /// total duration of the story would be 5 seconds (i.e (10)/(0.02 * 100)) to
  /// get the increment per second, which would be 0.2 per second
  ///
  /// To set a progressValue increment of 30 seconds, this wouls be 30 / 0.2 to
  /// get the increment value for each second, then divide this value by the
  /// timer value.
  ///
  /// The Timer Value, starts at 0 and increments by 1 for every 100 milliseconds
  /// The value [50] denotes 5 seconds, meaning 1 second is denoted by 10.
  /// i.e 30 seconds would be 30 * 10 => 300, so the timer value to be passed in
  /// would represent the number of seconds the story would be viewed for
  ///
  ///
  /// So, the progress Controller for a 30 second story would be (10)/x * 100 = 30
  /// i.e x = (10)/30 * 100 or (10)/([seconds] * 100)
  void initiateTimer({double seconds = 5}) async {
    double internalSeconds = seconds;
    if (currentStory?.storyType == StoryType.video){
      debugPrint("Story is video");
      await videoControllers[currentStory]?.initialize();
      internalSeconds = videoControllers[currentStory]?.value.duration.inSeconds.toDouble() ?? 30;
      debugPrint("Duration: ${videoControllers[currentStory]?.value.duration}");
      await videoControllers[currentStory]?.play();
    }
    debugPrint("Seconds: $internalSeconds");

    storyTimerValue = 0;
    previousStory = currentStory;
    storyTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      storyTimerValue += 1;
      setState(() {
        if (currentStory != null && progressController.containsKey(currentStory)){
          double currentValue = progressController[currentStory!]!;
          // debugPrint("Current Double Value: $currentValue");
          progressController[currentStory!] = currentValue + (10)/(internalSeconds * 100);
        }
      });

      // debugPrint("Progress Value: ${progressController[currentStory!]}");

      /// TODO: Change Timer to dynamic value or length of video in-case
      if (storyTimerValue >= internalSeconds * 10){

        /// Cancel current timer on '5
        storyTimer?.cancel();

        /// Move to the next story
        currentStoryIndex += 1;
        previousStory = currentStory;
        if (currentStoryIndex < stories.length){
          currentStory = stories[currentStoryIndex];
        }
        debugPrint("Current Story: $currentStoryIndex");
        debugPrint("Current Story: ${currentStory?.storyUrl}");
        pageController.animateToPage(
          currentStoryIndex,
          duration: const Duration(seconds: 1),
          curve: Curves.easeIn
        );
        setState(() {
          progressController[currentStory!] = 0.0;
          progressController[previousStory!] = 0.0;
        });

        /// Restart the Timer while the currentStory is not the last.
        /// if its the last, the timer just gets cancelled and ends
        if (currentStoryIndex < stories.length){
          if (currentStory?.storyType == StoryType.video){
            initiateTimer(seconds: 30);
          } else {
            initiateTimer();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
        decoration: const BoxDecoration(
          color: Colors.blue
        ),
        child: PageView.builder(
          // physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          itemCount: stories.length,
          onPageChanged: (value){
            currentStoryIndex = value;
            currentStory = stories[value];
            if (previousStory.hashCode != currentStory.hashCode){
              progressController[previousStory!] = 0.0;
              videoControllers[previousStory]?.pause();
              videoControllers[previousStory]?.dispose();
            }
            storyTimer?.cancel();
            if (currentStory?.storyType == StoryType.video){
              initiateTimer(seconds: 30);
            } else {
              initiateTimer();
            }
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
              currentStory = stories[index];
                return videoControllers[stories[index]] != null
                  ? SizedBox(
                    height: 250,
                    width: 300,
                    child: VideoPlayer(videoControllers[stories[index]]!)
                    )
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
      ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(stories.length, (index){
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.649 / stories.length,
              child: LinearProgressIndicator(
                value: progressController[stories[index]] == null || progressController[stories[index]] == 0.0 ? 0.0 : progressController[stories[index]],
              ),
            );
          }),
        ),
      ],
    );
  }
}

