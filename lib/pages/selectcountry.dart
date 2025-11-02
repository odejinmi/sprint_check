import 'package:flutter/material.dart';

class Selectcountry extends StatefulWidget {
  final Function(Map<String, dynamic>) onResponse;
  const Selectcountry({super.key, required this.onResponse});

  @override
  _SelectcountryState createState() => _SelectcountryState();
}

class _SelectcountryState extends State<Selectcountry> {
  final List<Map<String, dynamic>> countries = [
    {"name": "Nigeria", "code": "NG"},
    {"name": "Ghana", "code": "GH"},
    {"name": "Togo", "code": "TG"},
    {"name": "Cameroon", "code": "CM"},
    {"name": "Senegal", "code": "SN"},
    {"name": "Guinea", "code": "GN"},
    {"name": "Guinea-Bissau", "code": "GW"},
    {"name": "Mali", "code": "ML"},
    {"name": "Burkina Faso", "code": "BF"},
    {"name": "Côte d'Ivoire", "code": "CI"}
  ];

  List<Map<String, dynamic>> filteredCountries = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCountries = countries;
    _searchController.addListener(_filterCountries);
  }

  void _filterCountries() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      filteredCountries = countries
          .where((country) =>
              country['name']!.toLowerCase().contains(searchTerm))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCountries);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Select Country',
            style: TextStyle(
              color: const Color(0xFF181619),
              fontSize: 18,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              height: 1.78,
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search",
              prefixIcon: Icon(Icons.search),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                borderSide: BorderSide(color: Color(0xFFE1E1E1)),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                borderSide: BorderSide(color: Color(0xFFE1E1E1)),
              ),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      widget.onResponse(filteredCountries[index]);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Image.network(
                              "https://flagcdn.com/w40/${filteredCountries[index]["code"].toLowerCase()}.png"),
                        ),
                        SizedBox(width: 18),
                        Text(
                          filteredCountries[index]["name"],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
