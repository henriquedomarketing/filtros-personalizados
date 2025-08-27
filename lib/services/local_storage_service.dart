import 'package:shared_preferences/shared_preferences.dart';

const IMAGE_TIMESTAMP_KEY = 'image_timestamp';
const IMAGE_COUNTER_KEY = 'image_counter';

const VIDEO_TIMESTAMP_KEY = 'video_timestamp';
const VIDEO_COUNTER_KEY = 'video_counter';

const MAX_IMAGES = 20;
const MAX_VIDEOS = 8;

class LocalStorageService {
  static int resetTime = Duration(hours: 8).inMilliseconds;

  static Future<void> setImageTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(IMAGE_TIMESTAMP_KEY, timestamp);
  }

  static Future<void> setVideoTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(VIDEO_TIMESTAMP_KEY, timestamp);
  }

  static Future<void> setImageTaken() async {
    final prefs = await SharedPreferences.getInstance();
    final counter = prefs.getInt(IMAGE_COUNTER_KEY) ?? 0;
    await prefs.setInt(IMAGE_COUNTER_KEY, counter + 1);
    final lastImageTimestamp = prefs.getInt(IMAGE_TIMESTAMP_KEY) ?? 0;
    if (lastImageTimestamp == 0) {
      setImageTimestamp();
    } else {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastImageTimestamp;
      if (timeDifference > resetTime) {
        setImageTimestamp();
      }
    }
  }

  static Future<void> setVideoTaken() async {
    final prefs = await SharedPreferences.getInstance();
    final counter = prefs.getInt(VIDEO_COUNTER_KEY) ?? 0;
    await prefs.setInt(VIDEO_COUNTER_KEY, counter + 1);
    final lastVideoTimestamp = prefs.getInt(VIDEO_TIMESTAMP_KEY) ?? 0;
    if (lastVideoTimestamp == 0) {
      setVideoTimestamp();
    } else {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastVideoTimestamp;
      if (timeDifference > resetTime) {
        setVideoTimestamp();
      }
    }
  }

  static Future<bool> canTakeImage() async {
    // TODO: cliente quer deixar sem limite de imagem por hora.
    return true;
    final prefs = await SharedPreferences.getInstance();
    final lastImageTimestamp = prefs.getInt(IMAGE_TIMESTAMP_KEY) ?? 0;
    final imageCount = prefs.getInt(IMAGE_COUNTER_KEY) ?? 0;
    if (lastImageTimestamp == 0) return imageCount < MAX_IMAGES;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastImageTimestamp;
    return timeDifference <= resetTime && imageCount < MAX_IMAGES;
  }

  static Future<bool> canTakeVideo() async {
    return true;
    final prefs = await SharedPreferences.getInstance();
    final lastVideoTimestamp = prefs.getInt(VIDEO_TIMESTAMP_KEY) ?? 0;
    final videoCount = prefs.getInt(VIDEO_COUNTER_KEY) ?? 0;
    if (lastVideoTimestamp == 0) return videoCount < MAX_VIDEOS;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastVideoTimestamp;
    return timeDifference <= resetTime && videoCount < MAX_VIDEOS;
  }
}
