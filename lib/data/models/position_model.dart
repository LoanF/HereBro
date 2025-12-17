class Position {
  final double latitude;
  final double longitude;

  Position({required this.latitude, required this.longitude});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(latitude: json['latitude'], longitude: json['longitude']);
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}
