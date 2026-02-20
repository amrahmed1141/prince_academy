
class CoachesModel {
  String? id;
  String? name;

  String? imageUrl;
  String? description;

  CoachesModel({
    this.id,
    this.name,
    this.imageUrl,
    this.description,
  });

}

List<CoachesModel> coaches = [
  CoachesModel(
    id: 'zombie',
    name: 'Islam Nader',
    imageUrl: 'assets/coaches/zombie.jpeg',
    description: 'Black Belt Bjj and PFL Champion .',
  ),
  CoachesModel(
    id: 'shentle',
    name: 'Ahmed Tarek',
    imageUrl: 'assets/coaches/shently.jpeg',
    description: 'MMA Coach and 66Kg Aufc Champion',
  ),
  CoachesModel(
    id: 'Fayo',
    name: 'Omar Fayomi',
    imageUrl: 'assets/coaches/fayo.jpeg',
    description: 'Professional Striker and Wrestling',
  ),
];
