import '/skit/skit.dart';
import '/tools/3d/threed.dart';
import '/tools/db/sqlite.dart';
import '/version_control/constellation/constellation.dart';
import '/version_control/star/star.dart';
import '/scripting/extras/datetime.dart';
import '/scripting/extras/extras.dart';
import '/scripting/extras/stringbuffer.dart';
import '/security/authveld.dart';
import '/security/policies/launch_apps/launch_apps.dart';
import '/security/policies/policies.dart';
import '/skit/sobjects/sobjects.dart';
import '/apps.dart';
import '/reyveld.dart';

Set<SInterface> get interfaces => {
      ReyveldInterface(),
      ListInterface(),
      DateTimeInterface(),
      SHeaderInterface(),
      SKitInterface(),
      ConstellationInterface(),
      StarInterface(),
      SArchiveInterface(),
      SFileInterface(),
      SObjectInterface(),
      SessionInterface(),
      DirectoryInterface(),
      StreamInterface(),
      GlobsInterface(),
      WhitelistInterface(),
      BlacklistInterface(),
      SAuthorInterface(),
      SCustomInterface(),
      TalkerInterface(),
      AuthVeldInterface(),
      SPolicyInterface(),
      SPolicySKitInterface(),
      SPolicyLaunchAppsInterface(),
      SPolicyAllInterface(),
      SPolicyFilesInterface(),
      StringBufferInterface(),
      AppLauncherInterface(),
      SContractInterface(),
      Matrix4Interface(),
      Vector3Interface(),
      Vector4Interface(),
      QuaternionInterface(),
      SQLDatabaseInterface(),
    };
