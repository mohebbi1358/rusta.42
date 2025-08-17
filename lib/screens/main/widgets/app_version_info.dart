import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo extends StatelessWidget {
  const AppVersionInfo({super.key});

  Future<Map<String, String>> _getVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    return {
      'version': info.version,
      'build': info.buildNumber,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getVersionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final version = snapshot.data!['version']!;
        final build = snapshot.data!['build']!;

        return Text(
          'نسخه $version  (بیلد $build)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
