// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaceAdapter extends TypeAdapter<Place> {
  @override
  final int typeId = 1;

  @override
  Place read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Place(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      imageUrl: (fields[3] as List).cast<String>(),
      latitude: fields[4] as double?,
      longitude: fields[5] as double?,
      categories: (fields[6] as List).cast<String>(),
      subcategories: (fields[7] as List).cast<String>(),
      workingHours: fields[8] as String,
      ticketPrice: fields[9] as String,
      address: fields[10] as String,
      videoUrl: fields[12] as String?,
      regionId: fields[11] as String,
      likesCount: fields[13] as int,
      commentsCount: fields[14] as int,
      phone: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Place obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.categories)
      ..writeByte(7)
      ..write(obj.subcategories)
      ..writeByte(8)
      ..write(obj.workingHours)
      ..writeByte(9)
      ..write(obj.ticketPrice)
      ..writeByte(10)
      ..write(obj.address)
      ..writeByte(11)
      ..write(obj.regionId)
      ..writeByte(12)
      ..write(obj.videoUrl)
      ..writeByte(13)
      ..write(obj.likesCount)
      ..writeByte(14)
      ..write(obj.commentsCount)
      ..writeByte(15)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
