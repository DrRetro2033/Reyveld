part of 'launch_apps.dart';

class SPolicyLaunchAppsInterface extends SInterface<SPolicyLaunchApps> {
  @override
  get className => "SPolicySKit";

  @override
  get parent => SPolicyInterface();

  @override
  get statics => {tagEntry(SPolicyLaunchAppsFactory())};
}
