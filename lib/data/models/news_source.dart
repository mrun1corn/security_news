import 'package:equatable/equatable.dart';

enum NewsCategory { cybersecurity, technology, antivirus, virtualization, infrastructure, devops, bookmarks }

class NewsSource extends Equatable {
  final String name;
  final String url;
  final String iconUrl;
  final NewsCategory category;

  const NewsSource({
    required this.name,
    required this.url,
    required this.iconUrl,
    required this.category,
  });

  @override
  List<Object?> get props => [name, url, iconUrl, category];
}
