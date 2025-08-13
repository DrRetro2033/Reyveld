part of 'scustom.dart';

class SCustomInterface extends SInterface<SCustom> {
  @override
  String get className => "SCustom";

  @override
  SInterface? get parent => SObjectInterface();

  @override
  get statics => {
        LEntry(
            name: "create",
            descr: "Create a custom SObject",
            returnType: SCustom,
            args: const {
              LArg<String>(
                name: "type",
                descr: "Type of the SCustom object to create",
              ),
              LArg<Map>(
                  name: "attribs",
                  descr: "Attributes to set on the SCustom object",
                  kind: ArgKind.optionalNamed)
            }, (String type, {Map? attribs}) async {
          return await SCustomCreator(type, attribs?.cast<String, dynamic>())
              .create();
        })
      };

  @override
  get exports => {
        LEntry(
            name: "type",
            descr: "Get the type of this SCustom",
            returnType: String,
            () => object!.type),
        LEntry(
          name: "getInt",
          args: const {
            LArg<String>(name: "key", descr: "Key to get the integer value for")
          },
          returnType: int,
          (String key) {
            return object!.getInt(key);
          },
        ),
        LEntry(
            name: "setInt",
            args: const {
              LArg<String>(name: "key", descr: "Key of the attribute to set."),
              LArg<int>(name: "value", descr: "The value to set.")
            },
            (String key, int value) => object!.setInt(key, value)),
        LEntry(
          name: "getString",
          args: const {
            LArg<String>(name: "key", descr: "Key to get the string value for")
          },
          returnType: String,
          (String key) {
            return object!.getString(key) ?? "";
          },
        ),
        LEntry(
            name: "setString",
            args: const {
              LArg<String>(name: "key", descr: "Key of the attribute to set."),
              LArg<String>(name: "value", descr: "The value to set.")
            },
            (String key, String value) => object!.setString(key, value)),
      };
}
