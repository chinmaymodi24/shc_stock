/// A sub-category belonging to a [CategoryModel], backed by the `sub_categories`
/// table in the backend.
class SubCategoryItem {
  final int id;
  final String name;
  final String description;

  const SubCategoryItem({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory SubCategoryItem.fromJson(Map<String, dynamic> json) {
    return SubCategoryItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// A product category fetched from the backend `categories` API.
///
/// [id] is kept as a String (stringified DB id) so existing widgets that
/// compare/select categories by id don't need to change; use [apiId] when
/// an integer is required for API calls.
class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<SubCategoryItem> subCategories;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl,
    this.subCategories = const [],
  });

  int get apiId => int.parse(id);

  /// Back-compat views: list of sub-category names.
  List<String> get subProducts =>
      subCategories.map((s) => s.name).toList(growable: false);

  /// Back-compat views: list of sub-category descriptions (parallel to [subProducts]).
  List<String> get subDescriptions =>
      subCategories.map((s) => s.description).toList(growable: false);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as int).toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      subCategories: (json['subCategories'] as List<dynamic>? ?? [])
          .map((e) => SubCategoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CategoryModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    List<SubCategoryItem>? subCategories,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      subCategories: subCategories ?? this.subCategories,
    );
  }
}
