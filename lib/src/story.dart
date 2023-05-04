enum StoryType{
  image,
  video,
}

class Story{
  String storyUrl;
  String format;
  StoryType storyType;

  Story({
    required this.storyUrl,
    required this.format,
    required this.storyType,
  });
}