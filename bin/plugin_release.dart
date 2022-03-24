import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

import 'custom_logger.dart';
import 'github_action.dart';

void main() async {
  var env = Platform.environment;

  var eventData =
      jsonDecode(File(env['GITHUB_EVENT_PATH']!).readAsStringSync());
  var commits = eventData['commits'] as List;
  var commitIds = commits.map((e) => e['id']).toList();

  //プッシュされたコミット(複数)のバージョン
  var pluginDataList = <CommitData>[];
  for (var i = 0; i < commitIds.length; i++) {
    var commitId = commitIds[i];
    var yml = await getPluginYml(commitId);
    pluginDataList.add(CommitData(commitId, yml['version'], yml['name']));
  }

  //プッシュ前のバージョン
  var beforeCommitId = eventData['before'];
  var lastPluginVersion = '';
  if (beforeCommitId != null) {
    var yml = await getPluginYml(beforeCommitId);
    lastPluginVersion = yml['version'];
  }

  //最初のバージョンが違えばリリース
  var releaseVersions = <String>[];
  var releaseCommitDataList = <CommitData>[];

  //新しい→古いでforEachを回す
  pluginDataList.forEach((commitData) {
    if (!releaseVersions.contains(commitData.pluginVersion)) {
      print('last:$lastPluginVersion, ${commitData.pluginVersion}');
      if (lastPluginVersion != commitData.pluginVersion) {
        releaseCommitDataList.add(commitData);
        releaseVersions.add(commitData.pluginVersion);
      }
    }
  });

  await release(releaseCommitDataList);
}

Future<dynamic> getPluginYml(String commitId) async {
  var basicAuth = 'Basic ' + base64Encode(utf8.encode('suinua:${token()}'));
  var header = {'authorization': basicAuth};
  var response = await http.get(
      Uri.parse('https://api.github.com/repos/${repository()}/contents/plugin.yml?ref=$commitId'),
      headers: header);

  var downloadUrl = jsonDecode(response.body)['download_url']!;

  var downloadResponse =
      await http.get(Uri.parse(downloadUrl), headers: header);
  return loadYaml(downloadResponse.body);
}

Future<void> release(List<CommitData> commitDataList) async {
  //Set git user
  await Process.run('git', ['config', '--global', 'user.name', actorName()]);
  await Process.run('git', [
    'config',
    '--global',
    'user.email',
    '${actorName()}@users.noreply.github.com'
  ]);

  for (var i = 0; i < commitDataList.length; i++) {
    var commitData = commitDataList[i];
    var dirName = commitData.pluginVersion;
    var dir = Directory(commitData.pluginVersion);
    await dir.create();

    Directory.current = dir.absolute.path;
    //clone
    var cloneResult = await Process.run('git', [
      'clone',
      'https://${actorName()}:${token()}@github.com/${repository()}'
    ]);
    CustomLogger.simple.v(
        'git clone https://${actorName()}:${token()}@github.com/${repository()} > stdout: ${cloneResult.stdout}');
    CustomLogger.simple.v(
        'git clone https://${actorName()}:${token()}@github.com/${repository()} > stderr: ${cloneResult.stderr}');

    //reset
    var resetResult =
        await Process.run('git', ['reset', '--hard', commitData.commitId]);
    CustomLogger.simple.v(
        'git reset --hard ${commitData.commitId} > stdout: ${resetResult.stdout}');
    CustomLogger.simple.v(
        'git reset --hard ${commitData.commitId} > stderr: ${resetResult.stderr}');

    //build phar
    var devtoolCloneResult = await Process.run('git', ['clone','https://github.com/pmmp/DevTools']);
    CustomLogger.simple.v(
        'git clone https://github.com/pmmp/DevTools > stdout: ${devtoolCloneResult.stdout}');
    CustomLogger.simple.v(
        'git clone https://github.com/pmmp/DevTools > stderr: ${devtoolCloneResult.stderr}');

    var ls = await Process.run('ls', []);
    CustomLogger.simple.v(
        'ls > stdout: ${ls.stdout}');
    CustomLogger.simple.v(
        'ls > stderr: ${ls.stderr}');
    var pharPath = '${commitData.pluginName}${commitData.pluginVersion}.phar';
    var arg = [
      '-dphar.readonly=0',
      path.join('DevTools', 'src', 'ConsoleScript.php'),
      '--make',
      dirName,
      '--out',
      pharPath,
      '--stub',
      path.join('Devtools', 'stub.php')
    ];

    var builtPharResult = await Process.run('php', arg);
    CustomLogger.simple.v('php ${arg.join(' ')}> stdout: ${builtPharResult.stdout}');
    CustomLogger.simple.v('php ${arg.join(' ')}> stderr: ${builtPharResult.stderr}');

    await createRelease(commitData, pharPath);
  }
}

Future<void> createRelease(CommitData commitData, String pharPath) async {
  var basicAuth = 'Basic ' + base64Encode(utf8.encode('suinua:${token()}'));
  var createReleaseHeader = {'authorization': basicAuth};
  var createReleaseBody = {'tag-name': commitData.pluginVersion};
  var createRelease = await http.post(Uri.parse('https://api.github.com/repos/${repository()}/releases'), headers: createReleaseHeader, body: createReleaseBody);
  CustomLogger.normal.v(createRelease.body);

  var releaseId = jsonDecode(createRelease.body)['id'];
  var phar = File(pharPath);
  var uploadHeader = {
    'authorization': basicAuth,
    'Content-Length': phar.readAsBytesSync().length.toString(),
    'Content-Type' : 'application/octet-stream'
  };
  var upload = await http.post(Uri.parse('https://uploads.github.com/repos/${repository()}/releases/$releaseId/assets?name=$pharPath'), headers: uploadHeader, body: phar.readAsBytesSync());
  CustomLogger.normal.v(upload.body);
}

class CommitData {
  final String commitId;
  final String pluginVersion;
  final String pluginName;

  CommitData(this.commitId, this.pluginVersion, this.pluginName);
}