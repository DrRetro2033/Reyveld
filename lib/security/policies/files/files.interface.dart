part of 'files.dart';

class SPolicyExterFilesInterface extends SInterface<SPolicyExterFiles> {
  @override
  get className => "SPolicyExterFiles";

  @override
  get parent => SPolicyInterface();

  @override
  get statics => {tagEntry(SPolicyExterFilesFactory())};
}

class SPolicyInterFilesInterface extends SInterface<SPolicyInterFiles> {
  @override
  get className => "SPolicyInterFiles";

  @override
  get parent => SPolicyInterface();

  @override
  get statics => {tagEntry(SPolicyInterFilesFactory())};
}
