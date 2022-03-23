import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  var env = Platform.environment;
  final pluginDirPath = path.join(env['GITHUB_WORKSPACE']!,env['PLUGIN_DIR']);
  final pluginYamlPath = path.join(pluginDirPath, 'plugin.yml');
  print(env['GITHUB_EVENT_PATH']);
}
