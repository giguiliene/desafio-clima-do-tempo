import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(GitHubApp());
}

class GitHubApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Github Repositories',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system, // Alterna entre claro/escuro
      home: GithubHomePage(),
    );
  }
}

class GithubHomePage extends StatefulWidget {
  @override
  _GithubHomePageState createState() => _GithubHomePageState();
}

class _GithubHomePageState extends State<GithubHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _repositories = [];
  String? _errorMessage;
  bool _isLoading = false;
  int _currentPage = 1; // Página atual
  bool _hasMore = true; // Controle de paginação

  Future<void> fetchRepositories(String username, {int page = 1}) async {
    final url = 'https://github.com/giguiliene/desafio-clima-do-tempo.git;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> newRepos = json.decode(response.body);
        setState(() {
          if (newRepos.isEmpty) {
            _hasMore = false; // Não há mais resultados
          } else {
            _repositories.addAll(newRepos);
          }
          _errorMessage = null;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage = 'Limite de requisições atingido. Tente novamente mais tarde.';
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao buscar dados: ${response.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar repositórios. Tente novamente mais tarde.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _controller.clear();
      _repositories = [];
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Github Repositories'),
        actions: [
          TextButton(
            onPressed: _clearSearch,
            child: Text(
              'Limpar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Digite o nome de usuário do Github',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _clearSearch();
                      fetchRepositories(_controller.text.trim());
                    },
                    child: Text('Buscar Repositórios'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            if (_repositories.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _repositories.length + 1, // Inclui o botão de carregamento
                  itemBuilder: (context, index) {
                    if (index == _repositories.length) {
                      return _hasMore
                          ? Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  fetchRepositories(_controller.text.trim(), page: ++_currentPage);
                                },
                                child: Text(_isLoading ? 'Carregando...' : 'Carregar Mais'),
                              ),
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Sem mais resultados.'),
                              ),
                            );
                    }
                    final repo = _repositories[index];
                    return Card(
                      child: ListTile(
                        title: Text(repo['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(repo['description'] ?? 'Sem descrição'),
                            Text('Linguagem: ${repo['language'] ?? 'Desconhecida'}'),
                            Text('Criado em: ${repo['created_at']}'),
                          ],
                        ),
                        trailing: Text('⭐ ${repo['stargazers_count']}'),
                        onTap: () async {
                          final url = repo['html_url'];
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Não foi possível abrir o link.')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
