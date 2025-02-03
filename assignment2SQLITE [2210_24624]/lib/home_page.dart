import 'package:flutter/material.dart';
import 'LocalDB.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalDatabase _localDB = LocalDatabase.instance;
  final TextEditingController _roomTypeController = TextEditingController();
  final TextEditingController _roomPriceController = TextEditingController();
  final TextEditingController _roomAvailabilityController = TextEditingController();

  int? _selectedRoomId;
  String _selectedSortOption = 'price_high_low';
  final List<String> _sortOptions = [
    'price_high_low',
    'price_low_high',
    'name_asc',
    'name_desc',
    'available_first',
    'occupied_first'
  ];

  @override
  void initState() {
    super.initState();

  }

  void _clearFields() {
    _roomTypeController.clear();
    _roomPriceController.clear();
    _roomAvailabilityController.clear();
    setState(() {
      _selectedRoomId = null;
    });
  }

  bool _parseAvailability(String value) {
    value = value.toLowerCase().trim();
    return value == 'yes'; // Returns true for 'yes', false otherwise
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  bool _validateFields() {
    String roomType = _roomTypeController.text;
    String roomPrice = _roomPriceController.text;
    String roomAvailability = _roomAvailabilityController.text;

    // Check if any field is empty and show a dialog
    if (roomType.isEmpty || roomPrice.isEmpty || roomAvailability.isEmpty) {
      _showErrorDialog("All fields are mandatory.");
      return false;
    }

    // Room Type Validation: Alphabets only and max 30 characters
    if (roomType.isEmpty || !RegExp(r'^[a-zA-Z\s]+$').hasMatch(roomType) || roomType.length > 30) {
      _showErrorDialog("Room type must be alphabetic and less than or equal to 30 characters.");
      return false;
    }

    // Price Validation: Must be a number greater than 0 and max 6 digits
    double price = double.tryParse(roomPrice) ?? 0.0;
    if (roomPrice.isEmpty || price <= 0 || roomPrice.length > 6) {
      _showErrorDialog("Price must be a positive number with no more than 6 digits.");
      return false;
    }

    // Availability Validation: Must be "yes" or "no"
    String availability = _roomAvailabilityController.text.toLowerCase().trim();
    if (availability.isEmpty || (availability != 'yes' && availability != 'no')) {
      _showErrorDialog("Availability must be 'yes' or 'no'.");
      return false;
    }

    return true;
  }

  void _createRoom() async {
    if (_validateFields()) {
      String roomType = _roomTypeController.text;
      double price = double.tryParse(_roomPriceController.text) ?? 0.0;
      bool availability = _parseAvailability(_roomAvailabilityController.text);

      await _localDB.addRoom(roomType, price, availability);
      _clearFields();
      setState(() {}); // Refresh room list
      showDialog(
        context: context,
        builder: (context) => SuccessDialog(message: "Room created successfully!"),
      );
    }
  }

  void _updateRoom() async {
    if (_validateFields() && _selectedRoomId != null) {
      bool availability = _parseAvailability(_roomAvailabilityController.text);

      await _localDB.updateRoom(_selectedRoomId!, {
        'type': _roomTypeController.text,
        'price': double.tryParse(_roomPriceController.text) ?? 0.0,
        'availability': availability,
      });

      _clearFields();
      setState(() {}); // Refresh room list
      showDialog(
        context: context,
        builder: (context) => SuccessDialog(message: "Room updated successfully!"),
      );
    }
  }

  void _deleteRoom(int id) async {
    await _localDB.deleteRoom(id);
    _clearFields();
    setState(() {}); // Refresh room list
    showDialog(
      context: context,
      builder: (context) => SuccessDialog(message: "Room deleted successfully!"),
    );
  }

  List<Map<String, dynamic>> _sortRooms(List<Map<String, dynamic>> rooms) {
    // Clone the list to avoid modifying the original
    List<Map<String, dynamic>> sortedRooms = List.from(rooms);

    switch (_selectedSortOption) {
      case 'price_high_low':
        sortedRooms.sort((a, b) =>
            (b['price'] as double).compareTo(a['price'] as double));
        break;
      case 'price_low_high':
        sortedRooms.sort((a, b) =>
            (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'name_asc':
        sortedRooms.sort((a, b) =>
            (a['type'] as String).compareTo(b['type'] as String));
        break;
      case 'name_desc':
        sortedRooms.sort((a, b) =>
            (b['type'] as String).compareTo(a['type'] as String));
        break;
      case 'available_first':
        sortedRooms.sort((a, b) =>
            (b['availability'] as int).compareTo(a['availability'] as int));
        break;
      case 'occupied_first':
        sortedRooms.sort((a, b) =>
            (a['availability'] as int).compareTo(b['availability'] as int));
        break;
    }
    return sortedRooms;
  }

    String _getSortOptionText(String value) {
    switch (value) {
      case 'price_high_low':
        return 'Price: High to Low';
      case 'price_low_high':
        return 'Price: Low to High';
      case 'name_asc':
        return 'Name: A-Z';
      case 'name_desc':
        return 'Name: Z-A';
      case 'available_first':
        return 'Available First';
      case 'occupied_first':
        return 'Occupied First';
      default:
        return 'Sort By';
    }
  }
  // ... [Keep _getSortOptionText, _getAvailabilityColor, _buildHoverButton methods] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(" Omar Hotel Room Management- SQLITE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Title
                    Center(
                      child: Text(
                        "Room Details Form",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Display the Room ID field as a read-only field
                    if (_selectedRoomId != null)
                      Text("Room ID: $_selectedRoomId",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),

                    // Rest of the form fields
                    TextField(
                      controller: _roomTypeController,
                      decoration: InputDecoration(
                        labelText: "Room Type",
                        prefixIcon: Icon(Icons.bed),
                        hintText: "E.g, Single, Double, Suite",
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _roomPriceController,
                      decoration: InputDecoration(
                        labelText: "Price per Night (Rs)",
                        prefixIcon: Icon(Icons.money),
                        hintText: "Price for one night stay",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _roomAvailabilityController,
                      decoration: InputDecoration(
                        labelText: "Availability (Yes/No)",
                        prefixIcon: Icon(Icons.event_available),
                        hintText: "'Yes' if available or 'No' if not available",
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_selectedRoomId == null)
                          _buildHoverButton("Create", Colors.green, Icons.add, _createRoom),
                        if (_selectedRoomId != null)
                          _buildHoverButton("Update", Colors.orange, Icons.update, _updateRoom),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildHoverButton("Clear Form", Colors.red, Icons.clear, _clearFields),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            SizedBox(height: 16),

            // Header and Sorting Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'List of Rooms',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedSortOption,
                    icon: Icon(Icons.sort, color: Colors.blueAccent),
                    underline: Container(height: 0),
                    items: _sortOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          _getSortOptionText(value),
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSortOption = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _localDB.getAllRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return Center(child: Text("Error loading rooms"));

                  List<Map<String, dynamic>> rooms = _sortRooms(snapshot.data ?? []);

                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final roomId = room['id'] as int;
                      final isAvailable = room['availability'] == 1;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Icon(Icons.king_bed,
                              color: _getAvailabilityColor(isAvailable), size: 36),
                          title: Text(room['type'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Price: Rs${room['price']} - ${isAvailable ? 'Available' : 'Not Available'}"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRoom(roomId),
                          ),
                          onTap: () {
                            _roomTypeController.text = room['type'];
                            _roomPriceController.text = room['price'].toString();
                            _roomAvailabilityController.text = isAvailable ? 'Yes' : 'No';
                            setState(() {
                              _selectedRoomId = roomId;
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Color _getAvailabilityColor(bool isAvailable) {
  return isAvailable ? Colors.green : Colors.redAccent;
}
Widget _buildHoverButton(String text, Color color, IconData icon, VoidCallback onPressed) {
  return InkWell(
    onTap: onPressed,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}


class SuccessDialog extends StatelessWidget {
  final String message;

  const SuccessDialog({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Success"),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("OK"),
        ),
      ],
    );
  }
}