import 'package:arceus/arceus.dart';
import 'package:arceus/skit/sobject.dart';
import 'package:arceus/skit/sobjects/file_system.dart';
part 'header.g.dart';

/// The header node of a SERE kit file.
/// This is the top level node of the kit file, and contains information about the kit, like constellation structures, users, addon info, etc.
@SGen("sere")
class SHeader extends SObject {
  SHeader(super.kit, super._node);

  DateTime get createdOn =>
      DateTime.parse(get("createdOn") ?? DateTime.now().toIso8601String());
  set createdOn(DateTime value) {
    if (!has("createdOn")) {
      set("createdOn", value.toIso8601String());
    }
  }

  DateTime get lastModified =>
      DateTime.parse(get("lastModified") ?? DateTime.now().toIso8601String());
  set lastModified(DateTime value) {
    set("lastModified", value.toIso8601String());
  }

  String get version => get("version") ?? Arceus.currentVersion.toString();

  SKitType get type => SKitType.values[int.parse(get("type") ?? "0")];

  @override
  void addChild(SObject child) {
    if (child is SArchive || child is SFile) {
      /// Stops anyone from adding an SArchive or SFile to the kit header.
      /// This is because the kit header should be as small as possible to
      /// save memory when accessing information about the kit.
      ///
      /// If you need to add an reference to an SArchive to the kit header,
      /// use the [SRArchive] object instead.
      throw Exception("Cannot add a SArchive or SFile to KitHeader!");
    }
    super.addChild(child);
  }
}

class SHeaderInterface extends SObjectInterface<SHeader> {
  @override
  get className => "SHeader";

  @override
  get description => """
The header node of a SERE kit file.
This is the top level node of the kit file, and contains information about the kit, like constellation structures, addon info, etc.
""";

  @override
  get exports => {
        "createdOn": (lua) async {
          if (lua.state.isString(1)) {
            final value = await lua.getFromTop<String>();
            object?.createdOn = DateTime.parse(value);
          } else {
            return object?.createdOn.toIso8601String();
          }
        },
        "lastModified": (lua) async {
          if (lua.state.isString(1)) {
            final value = await lua.getFromTop<String>();
            object?.lastModified = DateTime.parse(value);
          } else {
            return object?.lastModified.toIso8601String();
          }
        },
        "version": (state) {
          return object?.version;
        },
        "type": (_) => object?.type.index,
      };
}

class SHeaderCreator extends SCreator<SHeader> {
  final SKitType type;

  SHeaderCreator(this.type);

  @override
  get creator => (builder) {
        builder.attribute("createdOn", DateTime.now().toIso8601String());
        builder.attribute("lastModified", DateTime.now().toIso8601String());
        builder.attribute("version", Arceus.currentVersion.toString());
        builder.attribute("type", type.index.toString());
      };
}
