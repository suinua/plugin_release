import 'dart:io';

String actorName() {
  return Platform.environment['GITHUB_ACTOR']!;
}

String token() {
  return Platform.environment['GITHUB_TOKEN']!;
}

String repository() {
  return Platform.environment['GITHUB_REPOSITORY']!;
}
