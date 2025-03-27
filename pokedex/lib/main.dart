import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(color: Colors.orange),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const PokedexScreen(),
    );
  }
}

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  List<Map<String, dynamic>> filteredPokemonList = [];
  TextEditingController searchController = TextEditingController();

  Future<void> fetchPokemon(String query) async {
    query = query.trim().toLowerCase();
    if (query.isEmpty) return;

    final response = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon/$query'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        filteredPokemonList = [
          {
            'name': data['name'] ?? 'Unknown',
            'id': data['id'] ?? 0,
            'image': data['sprites']?['front_default'] ?? '',
          },
        ];
      });
    } else {
      setState(() {
        filteredPokemonList = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pokémon not found!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Pokémon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: fetchPokemon,
            ),
          ),
          Expanded(
            child:
                filteredPokemonList.isEmpty
                    ? const Center(child: Text('No Pokémon found.'))
                    : ListView.builder(
                      itemCount: filteredPokemonList.length,
                      itemBuilder: (context, index) {
                        final pokemon = filteredPokemonList[index];
                        return ListTile(
                          leading:
                              pokemon['image'].isNotEmpty
                                  ? Image.network(pokemon['image'])
                                  : const Icon(Icons.image_not_supported),
                          title: Text(pokemon['name'].toString().toUpperCase()),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PokemonDetailScreen(
                                      name: pokemon['name'],
                                      index: pokemon['id'],
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class PokemonDetailScreen extends StatelessWidget {
  final String name;
  final int index;

  const PokemonDetailScreen({
    super.key,
    required this.name,
    required this.index,
  });

  Future<Map<String, dynamic>> fetchPokemonDetails() async {
    final response = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon/$index/'),
    );
    final speciesResponse = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$index/'),
    );
    if (response.statusCode == 200 && speciesResponse.statusCode == 200) {
      final data = json.decode(response.body);
      final speciesData = json.decode(speciesResponse.body);
      final description =
          (speciesData['flavor_text_entries'] as List).firstWhere(
            (entry) => entry['language']['name'] == 'en',
            orElse: () => {'flavor_text': 'No description available.'},
          )['flavor_text'];
      return {
        'id': data['id'],
        'name': data['name'],
        'image': data['sprites']['front_default'],
        'height': data['height'],
        'weight': data['weight'],
        'types': (data['types'] as List)
            .map((t) => t['type']['name'])
            .join(', '),
        'description': description,
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name.toUpperCase())),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPokemonDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('Error loading Pokémon data.'));
          }

          final pokemon = snapshot.data!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(pokemon['image'], height: 150, fit: BoxFit.cover),
                const SizedBox(height: 20),
                DataTable(
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Attribute',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        DataCell(Text('ID')),
                        DataCell(Text('${pokemon['id']}')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('Height')),
                        DataCell(Text('${pokemon['height'] / 10} m')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('Weight')),
                        DataCell(Text('${pokemon['weight'] / 10} kg')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('Types')),
                        DataCell(Text(pokemon['types'])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    pokemon['description'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
