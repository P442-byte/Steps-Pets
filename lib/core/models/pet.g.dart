// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetAdapter extends TypeAdapter<Pet> {
  @override
  final int typeId = 0;

  @override
  Pet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pet(
      id: fields[0] as String,
      name: fields[1] as String,
      species: fields[2] as String,
      rarityIndex: fields[3] as int,
      typeIndex: fields[4] as int,
      level: fields[5] as int,
      experience: fields[6] as int,
      hatchedAt: fields[7] as DateTime,
      totalStepsWalked: fields[8] as int,
      imageAsset: fields[9] as String,
      isFavorite: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Pet obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.species)
      ..writeByte(3)
      ..write(obj.rarityIndex)
      ..writeByte(4)
      ..write(obj.typeIndex)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.experience)
      ..writeByte(7)
      ..write(obj.hatchedAt)
      ..writeByte(8)
      ..write(obj.totalStepsWalked)
      ..writeByte(9)
      ..write(obj.imageAsset)
      ..writeByte(10)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
