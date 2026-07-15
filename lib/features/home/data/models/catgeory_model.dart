
class CategoryModel {
  String? id;
  String? name;
  String? imageUrl;

  CategoryModel({this.id, this.name, this.imageUrl});

} 
  List<CategoryModel> categories = [
    CategoryModel(
      id: '_mma',
      name: 'MMA',
      imageUrl: 'assets/images/mma.jpg',
    ),
    CategoryModel(
      id: '_bjj',
      name: 'JiuJitsu',
      imageUrl: 'assets/images/bjj.jpg',
    ),
    CategoryModel(
      id: '_box',
      name: 'Boxing',
      imageUrl: 'assets/images/box.jpg',
    ),
    CategoryModel(
      id: '_kickbox',
      name: 'Kickboxing',
      imageUrl: 'assets/images/kickbox.jpg',
    ),
  ];