class CategoryModel {
  final int categoryId;
  final int shopId;
  final String name;
  final bool status;

  CategoryModel({
    required this.categoryId,
    required this.shopId,
    required this.name,
    required this.status,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'] ?? 0,
      shopId: json['shop_id'] ?? 0,
      name: json['name'] ?? "",
      status: json['status'] ?? true,
    );
  }
}
