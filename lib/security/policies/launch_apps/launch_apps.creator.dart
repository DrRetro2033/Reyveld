part of 'launch_apps.dart';

class SPolicyLaunchAppsCreator extends SCreator<SPolicyLaunchApps> {
  final String? reasoning;
  final List<String> apps;

  SPolicyLaunchAppsCreator({this.reasoning, this.apps = const []});
  @override
  build(builder) {
    if (reasoning != null) {
      builder.sobject(SDescriptionCreator(reasoning!).create());
    }
  }
}
