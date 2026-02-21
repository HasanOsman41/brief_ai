class DataService {
  // Document data with category keys instead of localized strings
  final List<Map<String, dynamic>> _documents = [
    {
      'id': 1,
      'title': 'Mietvertrag Wohnung',
      'categoryKey': 'contracts',
      'date': '15.03.2024',
      'deadline': DateTime.now().add(const Duration(days: 2)),
      'statusKey': 'pending',
      'hasDeadline': true,
      'image': '1.jpeg',
      'image2': '4.jpeg',
    },
    {
      'id': 2,
      'title': 'GEZ Befreiung',
      'categoryKey': 'letters',
      'date': '10.03.2024',
      'deadline': DateTime.now().add(const Duration(days: 5)),
      'statusKey': 'done',
      'hasDeadline': true,
      'image': '2.jpeg',
      'image2': '4.jpeg',
    },
    {
      'id': 3,
      'title': 'Stromrechnung Januar',
      'categoryKey': 'invoices',
      'date': '05.03.2024',
      'deadline': DateTime.now().add(const Duration(days: 12)),
      'statusKey': 'pending',
      'hasDeadline': true,
      'image': '3.jpeg',
    },
    {
      'id': 4,
      'title': 'Krankenkassenbescheid',
      'categoryKey': 'important',
      'date': '01.03.2024',
      'deadline': null,
      'statusKey': 'pending',
      'hasDeadline': false,
      'image': '4.jpeg',
    },
  ];
  List<Map<String, dynamic>> getData() {
    return _documents;
  }

  Map<String, dynamic> getDocumentById(int index) {
    return _documents[index];
  }
}
