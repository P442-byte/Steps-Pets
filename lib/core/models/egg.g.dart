// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'egg.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EggAdapter extends TypeAdapter<Egg> {
  @override
  final int typeId = 1;

  @override
  Egg read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Egg(
      id: fields[0] as String,
      name: fields[1] as String,
      rarityIndex: fields[2] as int,
      stepsRequired: fields[3] as int,
      stepsWalked: fields[4] as int,
      receivedAt: fields[5] as DateTime,
      imageAsset: fields[6] as String,
      petSpeciesOnHatch: fields[7] as String,
      isHatched: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Egg obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.rarityIndex)
      ..writeByte(3)
      ..write(obj.stepsRequired)
      ..writeByte(4)
      ..write(obj.stepsWalked)
      ..writeByte(5)
      ..write(obj.receivedAt)
      ..writeByte(6)
      ..write(obj.imageAsset)
      ..writeByte(7)
      ..write(obj.petSpeciesOnHatch)
      ..writeByte(8)
      ..write(obj.isHatched);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EggAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
