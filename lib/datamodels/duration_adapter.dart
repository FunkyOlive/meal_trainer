import 'package:hive/hive.dart';

/// Adapts darts Duration Type for the Hive DB, with second precision
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final typeId = 0;

  @override
  Duration read(BinaryReader reader) {
    return Duration(seconds: reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inSeconds);
  }
}
