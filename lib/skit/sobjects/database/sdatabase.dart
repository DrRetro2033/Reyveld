import '/skit/sobject.dart';
import '/skit/sobjects/custom/scustom.dart';

part 'sdatabase.g.dart';
part 'sdatabase.creator.dart';
part 'sdatabase.interface.dart';

@SGen("db")
class SDatabase extends SRoot {
  SDatabase(super._node);
  @override
  childAllowed(SObject object) {
    if (object is SCustom) {
      return (true, "");
    }
    return (false, "Only SCustom objects are allowed.");
  }

  @override
  Future<SRDatabase> newIndent() async => SRDatabaseCreator(id).create();
}

class SRDatabase extends SIndent<SDatabase> {
  SRDatabase(super._node);
}

typedef SRDatabaseCreator = SIndentCreator<SRDatabase>;
