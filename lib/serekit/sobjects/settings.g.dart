part of 'settings.dart';

class ArceusSettingsFactory extends SFactory<ArceusSettings> {
  @override
  String get tag => "settings";

  @override
  ArceusSettings load(SKit kit, XmlNode node) => ArceusSettings(kit, node);

  @override
  // TODO: implement creator
  get creator =>
      (XmlBuilder builder, [Map<String, dynamic>? attributes]) async {
        builder.element("settings", nest: () {
          builder.attribute("date-format", DateFormat.dayMonthYear.index);
          builder.attribute("time-format", TimeFormat.h12.index);
        });
      };
}
