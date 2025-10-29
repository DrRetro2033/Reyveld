import 'package:vector_math/vector_math_64.dart';
import 'package:reyveld/scripting/sinterface.dart';

class Matrix4Interface extends SInterface<Matrix4> {
  @override
  get className => "Matrix4";

  @override
  get classDescription => """""";

  @override
  get statics => {
        LEntry(
            name: "zero",
            descr: "Returns a zero matrix.",
            returnType: Matrix4,
            () => Matrix4.zero()),
        LEntry(
            name: "identity",
            descr: "Returns an identity matrix.",
            returnType: Matrix4,
            () => Matrix4.identity()),
      };

  @override
  get exports => {
        LEntry(
            name: "copy",
            descr: "Returns a copy of this matrix.",
            returnType: Matrix4,
            () => object!.clone()),
        LEntry(
            name: "translate4",
            descr: "Translates the matrix by the given vector.",
            args: const {LArg<Vector4>(name: "translation")},
            returnType: Vector4,
            (Vector4 translation) => object!.transform(translation)),
        LEntry(
            name: "translate3",
            descr: "Translates the matrix by the given vector.",
            args: const {LArg<Vector3>(name: "translation")},
            returnType: Vector3,
            (Vector3 translation) => object!.transform3(translation)),
        LEntry(
            name: "scale4",
            descr: "Scale the matrix by the given vector.",
            args: const {LArg<Vector4>(name: "scale")},
            returnType: Matrix4,
            (Vector4 scale) => object!..scaleByVector4(scale)),
        LEntry(
            name: "scale3",
            descr: "Scale the matrix by the given vector.",
            args: const {LArg<Vector3>(name: "scale")},
            returnType: Matrix4,
            (Vector3 scale) => object!..scaleByVector3(scale)),
        LEntry(
            name: "rotate",
            descr: "Rotates the matrix by the given axis and angle.",
            args: const {
              LArg<Vector3>(name: "axis"),
              LArg<double>(name: "angle")
            },
            returnType: Matrix4,
            (Vector3 axis, double angle) => object!.rotate(axis, angle)),
      };
}
