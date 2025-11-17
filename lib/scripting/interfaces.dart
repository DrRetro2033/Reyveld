import 'package:reyveld/skit/skit.dart';
import 'package:reyveld/tools/3d/threed.dart';
import 'package:reyveld/version_control/constellation/constellation.dart';
import 'package:reyveld/version_control/star/star.dart';
import 'package:reyveld/scripting/extras/datetime.dart';
import 'package:reyveld/scripting/extras/extras.dart';
import 'package:reyveld/scripting/extras/stringbuffer.dart';
import 'package:reyveld/security/authveld.dart';
import 'package:reyveld/security/contract/contract.dart';
import 'package:reyveld/security/policies/launch_apps/launch_apps.dart';
import 'package:reyveld/security/policies/policies.dart';
import 'package:reyveld/skit/sobjects/sobjects.dart';
import 'package:reyveld/apps.dart';
import 'package:reyveld/reyveld.dart';

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
    };
