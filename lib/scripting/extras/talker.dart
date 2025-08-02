import 'package:arceus/scripting/sinterface.dart';
import 'package:talker/talker.dart';

class TalkerInterface extends SInterface<Talker> {
  @override
  get className => "Talker";

  @override
  get classDescription =>
      """Talker is Arceus's logging interface. It is used to log debugging and error messages to a log file.
The log file is created in the application data directory, and a new log will be generated each day. The reason for this behavior is so that if the log needs to be sent for debugging, 
all the pertinent information is in one file and not spread across multiple logs.""";

  @override
  get exports => {
        LEntry(
            name: "log",
            descr: "Send a log message.",
            args: const {
              "message": LArg<Object>(descr: "The message to send"),
              "prefix": LArg<String>(
                  descr: "The prefix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
              "suffix": LArg<String>(
                  descr: "The suffix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
            },
            (String message, {String prefix = "", String suffix = ""}) =>
                object!.log("$prefix$message$suffix")),
        LEntry(
            name: "debug",
            descr: "Send a debug message.",
            args: const {
              "message": LArg<Object>(descr: "The message to send"),
              "prefix": LArg<String>(
                  descr: "The prefix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
              "suffix": LArg<String>(
                  descr: "The suffix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
            },
            (String message, {String prefix = "", String suffix = ""}) =>
                object!.debug("$prefix$message$suffix")),
        LEntry(
            name: "error",
            descr: "Send an error message.",
            args: const {
              "message": LArg<Object>(descr: "The message to send"),
              "prefix": LArg<String>(
                  descr: "The prefix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
              "suffix": LArg<String>(
                  descr: "The suffix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
            },
            (String message, {String prefix = "", String suffix = ""}) =>
                object!.error("$prefix$message$suffix")),
        LEntry(
            name: "warning",
            descr: "Send a warning message.",
            args: const {
              "message": LArg<Object>(descr: "The message to send"),
              "prefix": LArg<String>(
                  descr: "The prefix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
              "suffix": LArg<String>(
                  descr: "The suffix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
            },
            (String message, {String prefix = "", String suffix = ""}) =>
                object!.warning("$prefix$message$suffix")),
        LEntry(
            name: "info",
            descr: "Send an info message.",
            args: const {
              "message": LArg<Object>(descr: "The message to send"),
              "prefix": LArg<String>(
                  descr: "The prefix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
              "suffix": LArg<String>(
                  descr: "The suffix to add to the message.",
                  docDefaultValue: "",
                  kind: ArgKind.optionalNamed),
            },
            (String message, {String prefix = "", String suffix = ""}) =>
                object!.info("$prefix$message$suffix")),
      };
}
