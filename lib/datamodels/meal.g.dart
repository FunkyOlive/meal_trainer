// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinalMealInfoAdapter extends TypeAdapter<FinalMealInfo> {
  @override
  final int typeId = 1;

  @override
  FinalMealInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinalMealInfo(
      targetMealSize: fields[4] as int?,
      targetMealLength: fields[3] as Duration,
      eatingPatient: fields[1] as String,
      initialBiteSize: fields[2] as int?,
      startedAt: fields[0] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FinalMealInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.startedAt)
      ..writeByte(1)
      ..write(obj.eatingPatient)
      ..writeByte(2)
      ..write(obj.initialBiteSize)
      ..writeByte(3)
      ..write(obj.targetMealLength)
      ..writeByte(4)
      ..write(obj.targetMealSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinalMealInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordedUnmeasuredMealAdapter
    extends TypeAdapter<RecordedUnmeasuredMeal> {
  @override
  final int typeId = 4;

  @override
  RecordedUnmeasuredMeal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecordedUnmeasuredMeal(
      endedAt: fields[3] as DateTime,
      finalMealInfo: fields[50] as FinalMealInfo,
    );
  }

  @override
  void write(BinaryWriter writer, RecordedUnmeasuredMeal obj) {
    writer
      ..writeByte(2)
      ..writeByte(3)
      ..write(obj.endedAt)
      ..writeByte(50)
      ..write(obj.finalMealInfo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordedUnmeasuredMealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordedMeasuredMealAdapter extends TypeAdapter<RecordedMeasuredMeal> {
  @override
  final int typeId = 5;

  @override
  RecordedMeasuredMeal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecordedMeasuredMeal(
      targetWeights: (fields[0] as Map).cast<Duration, int>(),
      measuredWeights: (fields[1] as Map).cast<Duration, int>(),
      measuredBiteSize: fields[2] as int?,
      endedAt: fields[3] as DateTime,
      finalMealInfo: fields[50] as FinalMealInfo,
    );
  }

  @override
  void write(BinaryWriter writer, RecordedMeasuredMeal obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.targetWeights)
      ..writeByte(1)
      ..write(obj.measuredWeights)
      ..writeByte(2)
      ..write(obj.measuredBiteSize)
      ..writeByte(3)
      ..write(obj.endedAt)
      ..writeByte(50)
      ..write(obj.finalMealInfo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordedMeasuredMealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordedCalibrationMealAdapter
    extends TypeAdapter<RecordedCalibrationMeal> {
  @override
  final int typeId = 6;

  @override
  RecordedCalibrationMeal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecordedCalibrationMeal(
      measuredWeights: (fields[1] as Map).cast<Duration, int>(),
      measuredBiteSize: fields[2] as int?,
      finalMealInfo: fields[50] as FinalMealInfo,
      endedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecordedCalibrationMeal obj) {
    writer
      ..writeByte(4)
      ..writeByte(1)
      ..write(obj.measuredWeights)
      ..writeByte(2)
      ..write(obj.measuredBiteSize)
      ..writeByte(3)
      ..write(obj.endedAt)
      ..writeByte(50)
      ..write(obj.finalMealInfo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordedCalibrationMealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
