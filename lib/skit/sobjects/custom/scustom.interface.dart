part of 'scustom.dart';

class SCustomInterface extends SInterface<SCustom> {
  @override
  String get className => "SCustom";

  @override
  get statics => {
        LEntry(name: "create", args: const {
          "type": LArg<String>(
            descr: "Type of the SCustom object to create",
          ),
          "attrib": LArg<Map>(
              descr: "Attributes to set on the SCustom object",
              required: false,
              positional: false)
        }, (String type, {Map<String, dynamic>? attrib}) {
          return SCustomCreator(type, attrib).create();
        })
      };

  @override
  get exports => {
        LEntry(
          name: "getInt",
          args: const {
            "key": LArg<String>(descr: "Key to get the integer value for")
          },
          returnType: int,
          (String key) {
            return (SCustom sCustom) => sCustom.getInt(key);
          },
        ),
      };
}
