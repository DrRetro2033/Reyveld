import 'package:vector_math/vector_math_64.dart';
import 'package:reyveld/scripting/sinterface.dart';

class Vector3Interface extends SInterface<Vector3> {
  @override
  get className => "Vector3";

  @override
  get classDescription => "A 3D vector.";

  @override
  get statics => {
        LEntry(
            name: "new",
            returnType: Vector3,
            args: const {
              LArg<double>(
                  name: "x", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "y", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "z", docDefaultValue: "0", kind: ArgKind.optionalNamed),
            },
            ({double x = 0, double y = 0, double z = 0}) => Vector3(x, y, z)),
        LEntry(name: "zero", returnType: Vector3, () => Vector3.zero()),
        LEntry(name: "one", returnType: Vector3, () => Vector3.all(1)),
        LEntry(name: "up", returnType: Vector3, () => Vector3(0, 1, 0)),
        LEntry(name: "down", returnType: Vector3, () => Vector3(0, -1, 0)),
        LEntry(name: "right", returnType: Vector3, () => Vector3(0, 0, 1)),
        LEntry(name: "left", returnType: Vector3, () => Vector3(0, 0, -1)),
        LEntry(name: "forward", returnType: Vector3, () => Vector3(0, 0, 1)),
        LEntry(name: "back", returnType: Vector3, () => Vector3(0, 0, -1)),
      };

  @override
  get exports => {
        LEntry(name: "x", returnType: double, () => object!.x),
        LEntry(name: "y", returnType: double, () => object!.y),
        LEntry(name: "z", returnType: double, () => object!.z),
      };
}

class Vector4Interface extends SInterface<Vector4> {
  @override
  get className => "Vector4";

  @override
  get classDescription => "A 4D vector.";

  @override
  get statics => {
        LEntry(
            name: "new",
            returnType: Vector4,
            args: const {
              LArg<double>(
                  name: "x", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "y", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "z", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "w", docDefaultValue: "0", kind: ArgKind.optionalNamed),
            },
            ({double x = 0, double y = 0, double z = 0, double w = 0}) =>
                Vector4(x, y, z, w)),
        LEntry(name: "zero", returnType: Vector4, () => Vector4.zero()),
        LEntry(name: "one", returnType: Vector4, () => Vector4.all(1)),
        LEntry(
            name: "all",
            returnType: Vector4,
            args: const {LArg<double>(name: "value")},
            (double value) => Vector4.all(value)),
        LEntry(name: "up", returnType: Vector4, () => Vector4(0, 1, 0, 0)),
        LEntry(name: "down", returnType: Vector4, () => Vector4(0, -1, 0, 0)),
        LEntry(name: "right", returnType: Vector4, () => Vector4(0, 0, 1, 0)),
        LEntry(name: "left", returnType: Vector4, () => Vector4(0, 0, -1, 0)),
        LEntry(name: "forward", returnType: Vector4, () => Vector4(0, 0, 1, 0)),
        LEntry(name: "back", returnType: Vector4, () => Vector4(0, 0, -1, 0)),
      };

  @override
  get exports => {
        LEntry(name: "x", returnType: double, () => object!.x),
        LEntry(name: "y", returnType: double, () => object!.y),
        LEntry(name: "z", returnType: double, () => object!.z),
        LEntry(name: "w", returnType: double, () => object!.w),
      };
}

class QuaternionInterface extends SInterface<Quaternion> {
  @override
  get className => "Quaternion";

  @override
  get classDescription => "A 3D rotation.";

  @override
  get statics => {
        LEntry(
            name: "new",
            returnType: Quaternion,
            args: const {
              LArg<double>(
                  name: "x", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "y", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "z", docDefaultValue: "0", kind: ArgKind.optionalNamed),
              LArg<double>(
                  name: "w", docDefaultValue: "0", kind: ArgKind.optionalNamed),
            },
            ({double x = 0, double y = 0, double z = 0, double w = 0}) =>
                Quaternion(x, y, z, w)),
      };

  @override
  get exports => {
        LEntry(name: "x", returnType: double, () => object!.x),
        LEntry(name: "y", returnType: double, () => object!.y),
        LEntry(name: "z", returnType: double, () => object!.z),
        LEntry(name: "w", returnType: double, () => object!.w),
      };
}
