class CategoryModel {
  final int categoryId;
  final String name;

  CategoryModel({required this.categoryId, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'],
      name: json['name'] ?? "",
    );
  }
}
