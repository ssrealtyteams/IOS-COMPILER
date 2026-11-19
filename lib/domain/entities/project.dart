import 'package:equatable/equatable.dart';

class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.address,
    this.lat,
    this.lng,
    this.websiteUrl,
    this.youtubeUrl,
    this.brochureUrl,
    this.amenities = const [],
    this.pricing = const {},
    this.media = const [],
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? address;
  final double? lat;
  final double? lng;
  final String? websiteUrl;
  final String? youtubeUrl;
  final String? brochureUrl;
  final List<String> amenities;
  final Map<String, String> pricing;
  final List<ProjectMedia> media;
  final bool isActive;

  List<ProjectMedia> get images =>
      media.where((m) => m.type == MediaType.image).toList();
  List<ProjectMedia> get videos =>
      media.where((m) => m.type == MediaType.video).toList();
  ProjectMedia? get brochure =>
      media.where((m) => m.type == MediaType.pdf).firstOrNull;

  String? get thumbnailUrl =>
      images.isNotEmpty ? images.first.thumbnailUrl ?? images.first.url : null;

  @override
  List<Object?> get props => [id, name, isActive];
}

enum MediaType { image, video, pdf, other }

class ProjectMedia extends Equatable {
  const ProjectMedia({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.filename,
    this.fileSize,
    this.sortOrder = 0,
  });

  final String id;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? filename;
  final int? fileSize;
  final int sortOrder;

  @override
  List<Object?> get props => [id, url];
}
