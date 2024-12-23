import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  // Configuration
  const repoOwner = 'DrRetro2033'; // Replace with your GitHub username or org
  const repoName = 'Arceus'; // Replace with your repository name

  final apiBase = 'https://api.github.com/repos/$repoOwner/$repoName';
  final token = String.fromEnvironment('GITHUB_TOKEN');
  if (args.isEmpty) {
    print('Usage: dart release.dart <path-to-project>');
    exit(1);
  }
  bool draft = false;
  final pathOfProject =
      args.firstWhere((element) => !element.startsWith('--'), orElse: () => '');
  if (args.contains('--draft')) {
    draft = true;
  }
  if (!Directory(pathOfProject).existsSync()) {
    print('Error: Directory not found: $pathOfProject');
    exit(1);
  }
  final downloadedFiles = <File>[]; // List of downloaded artifacts
  try {
    // Step 1: Fetch the most recent workflow run
    print('Fetching latest workflow run...');
    final workflowsResponse = await http.get(
      Uri.parse('$apiBase/actions/runs'),
      headers: {'Authorization': 'token $token'},
    );

    if (workflowsResponse.statusCode != 200) {
      throw Exception(
          'Failed to fetch workflow runs: ${workflowsResponse.body}');
    }

    final workflowsData = jsonDecode(workflowsResponse.body);
    final latestRun = workflowsData['workflow_runs']?.first;
    if (latestRun == null) {
      throw Exception('No workflow runs found.');
    }

    final runId = latestRun['id'];
    print('Latest workflow run ID: $runId');

    // Step 2: Fetch artifacts from the latest run
    print('Fetching artifacts...');
    final artifactsResponse = await http.get(
      Uri.parse('$apiBase/actions/runs/$runId/artifacts'),
      headers: {'Authorization': 'token $token'},
    );

    if (artifactsResponse.statusCode != 200) {
      throw Exception('Failed to fetch artifacts: ${artifactsResponse.body}');
    }

    final artifactsData = jsonDecode(artifactsResponse.body)['artifacts'];
    if (artifactsData.isEmpty) {
      throw Exception('No artifacts found for the latest workflow run.');
    }

    // Download artifacts
    for (final artifact in artifactsData) {
      final artifactId = artifact['id'];
      final artifactName = artifact['name'];
      print('Downloading artifact: $artifactName...');

      final artifactDownloadResponse = await http.get(
        Uri.parse('$apiBase/actions/artifacts/$artifactId/zip'),
        headers: {'Authorization': 'token $token'},
      );

      if (artifactDownloadResponse.statusCode != 200) {
        throw Exception(
            'Failed to download artifact: ${artifactDownloadResponse.body}');
      }

      final outputFile = File('$artifactName.zip');
      await outputFile.writeAsBytes(artifactDownloadResponse.bodyBytes);
      downloadedFiles.add(outputFile);
      print('Artifact downloaded: ${outputFile.path}');
    }

    // Step 3: Create a release
    print('Creating release...');
    final createReleaseResponse = await http.post(
      Uri.parse('$apiBase/releases'),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tag_name':
            'v${loadYaml(File("$pathOfProject/pubspec.yaml").readAsStringSync())['version']}',
        'name':
            'v${loadYaml(File("$pathOfProject/pubspec.yaml").readAsStringSync())['version']}',
        'body': File('$pathOfProject/CHANGELOG.md').readAsStringSync(),
        'draft': draft,
        'prerelease':
            (loadYaml(File("$pathOfProject/pubspec.yaml").readAsStringSync())[
                    'version'] as String)
                .contains("alpha"),
      }),
    );

    if (createReleaseResponse.statusCode != 201) {
      throw Exception(
          'Failed to create release: ${createReleaseResponse.body}');
    }

    final releaseData = jsonDecode(createReleaseResponse.body);
    final uploadUrl =
        releaseData['upload_url'].toString().replaceAll('{?name,label}', '');

    print('Release created: ${releaseData['html_url']}');

    // Step 4: Upload artifacts to the release
    for (final file in downloadedFiles) {
      print('Uploading artifact: ${file.path}...');
      final uploadResponse = await http.post(
        Uri.parse(
            '$uploadUrl?name=${Uri.encodeComponent(file.uri.pathSegments.last)}'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/octet-stream',
        },
        body: await file.readAsBytes(),
      );

      if (uploadResponse.statusCode != 201) {
        throw Exception('Failed to upload artifact: ${uploadResponse.body}');
      }

      final uploadedAsset = jsonDecode(uploadResponse.body);
      print('Artifact uploaded: ${uploadedAsset['browser_download_url']}');
    }

    print('Release process completed successfully!');
  } catch (e) {
    print('Error: $e');
  }
  for (File downloadedFile in downloadedFiles) {
    downloadedFile.deleteSync();
  }
}
