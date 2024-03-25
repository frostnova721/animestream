import 'package:animestream/core/commons/enums.dart';
import 'package:http/http.dart';

Future<String> fetch(String uri) async {
  final res = await get(Uri.parse(uri));
  return res.body;
}

String getCurrentSeason() {
  final month = DateTime.now().month;
  switch (month) {
    case 1:
    case 2:
    case 3:
      return 'WINTER';
    case 4:
    case 5:
    case 6:
      return 'SPRING';
    case 7:
    case 8:
    case 9:
      return 'SUMMER';
    case 10:
    case 11:
    case 12:
      return 'FALL';
    default:
      return 'Unknown';
  }
}

MediaStatus assignItemEnum(String? valueInString) {
  if(valueInString == null) return MediaStatus.CURRENT;
    switch (valueInString) {
      case "CURRENT":
        return MediaStatus.CURRENT;
      case "PLANNING":
        return MediaStatus.PLANNING;
      case "DROPPED":
        return MediaStatus.DROPPED;
      case "COMPLETED":
        return MediaStatus.COMPLETED;
      default:
        throw new Exception("ERR_BAD_STRING");
    }
  }
