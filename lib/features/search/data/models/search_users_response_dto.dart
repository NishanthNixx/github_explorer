import 'github_user_dto.dart';

class SearchUsersResponseDto {
  const SearchUsersResponseDto({required this.totalCount, required this.items});

  factory SearchUsersResponseDto.fromJson(Map<String, dynamic> json) {
    final totalCount = json['total_count'];
    final items = json['items'];
    if (totalCount is! int || items is! List) {
      throw FormatException('Invalid search response payload', json);
    }

    return SearchUsersResponseDto(
      totalCount: totalCount,
      items: items
          .whereType<Map<String, dynamic>>()
          .map(GithubUserDto.fromJson)
          .toList(growable: false),
    );
  }

  final int totalCount;
  final List<GithubUserDto> items;
}
