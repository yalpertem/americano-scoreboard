import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(AmericanoApp());
}

class AmericanoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Americano Scoreboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: AmericanoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Penalty {
  final int id;
  final String name;
  final String short;
  final String symbol;

  Penalty({
    required this.id,
    required this.name,
    required this.short,
    required this.symbol,
  });
}

class RoundResult {
  final String player;
  final int penalties;
  final int originalPenalties;
  final int bonus;
  final int islerKagitCezasi;
  final int totalChange;
  final int newTotal;
  final bool isWinner;
  final bool gotBonus;
  final bool attiIslerKagit;
  final bool jokerEtkisi;
  final bool cezayiSoyleyenAcamadi;

  RoundResult({
    required this.player,
    required this.penalties,
    required this.originalPenalties,
    required this.bonus,
    required this.islerKagitCezasi,
    required this.totalChange,
    required this.newTotal,
    required this.isWinner,
    required this.gotBonus,
    required this.attiIslerKagit,
    required this.jokerEtkisi,
    required this.cezayiSoyleyenAcamadi,
  });
}

class GameRound {
  final int round;
  final int penaltyId;
  final String penaltyName;
  final String penaltyShort;
  final String penaltySymbol;
  final String penaltyCaller;
  final String islerKagitAtan;
  final String jokerIleBitiren;
  final String cezayiSoyleyenAcamadi;
  final List<RoundResult> results;
  final String winner;
  final String time;

  GameRound({
    required this.round,
    required this.penaltyId,
    required this.penaltyName,
    required this.penaltyShort,
    required this.penaltySymbol,
    required this.penaltyCaller,
    required this.islerKagitAtan,
    required this.jokerIleBitiren,
    required this.cezayiSoyleyenAcamadi,
    required this.results,
    required this.winner,
    required this.time,
  });
}

class AmericanoHomePage extends StatefulWidget {
  @override
  _AmericanoHomePageState createState() => _AmericanoHomePageState();
}

class _AmericanoHomePageState extends State<AmericanoHomePage>
    with TickerProviderStateMixin {
  bool gameStarted = false;
  int playerCount = 4;
  List<String> players = ['', '', '', ''];
  bool darkMode = false;

  final List<Penalty> penalties = [
    Penalty(id: 1, name: "3'lü Seri", short: "3S", symbol: "①"),
    Penalty(id: 2, name: "3'lü Küt", short: "3K", symbol: "②"),
    Penalty(id: 3, name: "3'lü Seri + 3'lü Küt", short: "3S3K", symbol: "③"),
    Penalty(id: 4, name: "2 3'lü Seri", short: "23S", symbol: "④"),
    Penalty(id: 5, name: "2 3'lü Küt", short: "23K", symbol: "⑤"),
    Penalty(id: 6, name: "4'lü Seri", short: "4S", symbol: "⑥"),
    Penalty(id: 7, name: "4'lü Küt", short: "4K", symbol: "⑦"),
    Penalty(id: 8, name: "4 Seri 4 Küt", short: "4S4K", symbol: "⑧"),
    Penalty(id: 9, name: "2 4'lü Seri", short: "24S", symbol: "⑨"),
    Penalty(id: 10, name: "2 4'lü Küt", short: "24K", symbol: "⑩"),
    Penalty(id: 11, name: "5'li Seri", short: "5S", symbol: "⑪"),
    Penalty(id: 12, name: "Çift", short: "Ç", symbol: "⑫"),
    Penalty(id: 13, name: "Elden", short: "E", symbol: "⑬"),
  ];

  int currentRound = 1;
  int? selectedPenalty;
  String penaltyCaller = '';
  Map<String, int> roundPenalties = {};
  String roundWinner = '';
  String islerKagitAtan = '';
  String jokerIleBitiren = '';
  String cezayiSoyleyenAcamadi = '';
  String gameStake = '';
  List<GameRound> gameHistory = [];
  Set<int> playedPenalties = {};
  int activeTab = 0;

  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void addPlayer() {
    if (playerCount < 5) {
      hapticFeedback();
      setState(() {
        playerCount++;
        players.add('Oyuncu $playerCount');
      });
    }
  }

  void removePlayer() {
    if (playerCount > 3) {
      hapticFeedback();
      setState(() {
        playerCount--;
        players.removeLast();
      });
    }
  }

  void updatePlayerName(int index, String name) {
    setState(() {
      players[index] = name;
    });
  }

  void startGame() {
    hapticFeedback();
    setState(() {
      gameStarted = true;
      roundPenalties = {for (String player in players) player: 0};
      islerKagitAtan = '';
      jokerIleBitiren = '';
      cezayiSoyleyenAcamadi = '';
      activeTab = 0;
    });
  }

  void backToSetup() {
    hapticFeedback();
    setState(() {
      gameStarted = false;
      gameStake = '';
      activeTab = 0;
    });
    resetGame();
  }

  List<Penalty> getAvailablePenalties() {
    final available = penalties
        .where((penalty) => !playedPenalties.contains(penalty.id))
        .toList();
    if (available.length > 1 && available.any((p) => p.id == 13)) {
      return available.where((penalty) => penalty.id != 13).toList();
    }
    return available;
  }

  Map<String, int> getCurrentScores() {
    final scores = <String, int>{};
    for (String player in players) {
      scores[player] = 0;
    }

    for (GameRound round in gameHistory) {
      for (RoundResult result in round.results) {
        scores[result.player] =
            (scores[result.player] ?? 0) + result.totalChange;
      }
    }

    return scores;
  }

  void calculateRoundScore() {
    if (selectedPenalty == null) {
      _showAlert('Lütfen oynanan cezayı seçin!');
      return;
    }
    if (penaltyCaller.isEmpty) {
      _showAlert('Lütfen cezayı söyleyen oyuncuyu seçin!');
      return;
    }
    if (roundWinner.isEmpty) {
      _showAlert('Lütfen eli bitiren oyuncuyu seçin!');
      return;
    }

    hapticFeedback();
    final currentScores = getCurrentScores();
    final roundResults = <RoundResult>[];
    final penalty = penalties.firstWhere((p) => p.id == selectedPenalty);

    for (String player in players) {
      int originalPenalty = roundPenalties[player] ?? 0;
      int penaltyCount = originalPenalty;

      if (player == cezayiSoyleyenAcamadi && cezayiSoyleyenAcamadi.isNotEmpty) {
        penaltyCount = originalPenalty * 2;
      }

      if (jokerIleBitiren.isNotEmpty) {
        if (player == cezayiSoyleyenAcamadi &&
            cezayiSoyleyenAcamadi.isNotEmpty) {
          penaltyCount = originalPenalty * 2 * 2;
        } else {
          penaltyCount = originalPenalty * 2;
        }
      }

      if (player == roundWinner) {
        penaltyCount = 0;
        originalPenalty = 0;
      }

      int bonusPoints = 0;
      final isLastRound = selectedPenalty == 13;
      if (player == roundWinner && player == penaltyCaller && !isLastRound) {
        bonusPoints = 50;
      }

      final islerKagitCezasi = player == islerKagitAtan ? -50 : 0;
      final totalChange = -penaltyCount + bonusPoints + islerKagitCezasi;

      roundResults.add(RoundResult(
        player: player,
        penalties: penaltyCount,
        originalPenalties: originalPenalty,
        bonus: bonusPoints,
        islerKagitCezasi: islerKagitCezasi,
        totalChange: totalChange,
        newTotal: currentScores[player]! + totalChange,
        isWinner: player == roundWinner,
        gotBonus: bonusPoints > 0,
        attiIslerKagit: player == islerKagitAtan,
        jokerEtkisi: jokerIleBitiren.isNotEmpty,
        cezayiSoyleyenAcamadi:
            player == cezayiSoyleyenAcamadi && cezayiSoyleyenAcamadi.isNotEmpty,
      ));
    }

    setState(() {
      gameHistory.add(GameRound(
        round: currentRound,
        penaltyId: penalty.id,
        penaltyName: penalty.name,
        penaltyShort: penalty.short,
        penaltySymbol: penalty.symbol,
        penaltyCaller: penaltyCaller,
        islerKagitAtan: islerKagitAtan,
        jokerIleBitiren: jokerIleBitiren,
        cezayiSoyleyenAcamadi: cezayiSoyleyenAcamadi,
        results: roundResults,
        winner: roundWinner,
        time: TimeOfDay.now().format(context),
      ));

      playedPenalties.add(penalty.id);

      // Reset for next round
      selectedPenalty = null;
      penaltyCaller = '';
      islerKagitAtan = '';
      jokerIleBitiren = '';
      cezayiSoyleyenAcamadi = '';
      roundPenalties = {for (String player in players) player: 0};
      roundWinner = '';
      currentRound++;
    });
  }

  void resetGame() {
    hapticFeedback();
    setState(() {
      currentRound = 1;
      selectedPenalty = null;
      penaltyCaller = '';
      islerKagitAtan = '';
      jokerIleBitiren = '';
      cezayiSoyleyenAcamadi = '';
      roundPenalties = {for (String player in players) player: 0};
      roundWinner = '';
      gameHistory.clear();
      playedPenalties.clear();
    });
  }

  String? getLeader() {
    final scores = getCurrentScores();
    final maxScore = scores.values
        .fold<int>(0, (prev, score) => score > prev ? score : prev);
    if (maxScore <= 0) return null;
    return scores.entries.firstWhere((entry) => entry.value == maxScore).key;
  }

  bool canCalculate() {
    final allPenaltiesFilled = players.every((player) => player == roundWinner
        ? true
        : roundPenalties[player] != null && roundPenalties[player]! > 0);
    return selectedPenalty != null &&
        penaltyCaller.isNotEmpty &&
        roundWinner.isNotEmpty &&
        allPenaltiesFilled;
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Uyarı'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkMode
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: gameStarted ? _buildGameScreen() : _buildSetupScreen(),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('🃏 Americano Kurulum'),
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                darkMode = !darkMode;
              });
              hapticFeedback();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPlayerCountSection(),
            SizedBox(height: 16),
            _buildPlayerNamesSection(),
            SizedBox(height: 16),
            _buildGameStakeSection(),
            SizedBox(height: 24),
            _buildStartGameButton(),
            SizedBox(height: 16),
            _buildRulesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCountSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Oyuncu Sayısı',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: playerCount <= 3 ? null : removePlayer,
                  icon: Icon(Icons.remove_circle),
                  iconSize: 48,
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$playerCount',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: playerCount >= 5 ? null : addPlayer,
                  icon: Icon(Icons.add_circle),
                  iconSize: 48,
                ),
              ],
            ),
            Text('3-5 oyuncu'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerNamesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Oyuncu İsimleri',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            ...players.asMap().entries.map((entry) {
              final index = entry.key;
              final player = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Oyuncu ${index + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(text: player),
                  onChanged: (value) => updatePlayerName(index, value),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStakeSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Bu Oyun Neye Oynanıyor?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Örnek: Kahve ısmarlama...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              controller: TextEditingController(text: gameStake),
              onChanged: (value) => setState(() => gameStake = value),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['☕ Kahve', '🍕 Yemek', '🍦 Dondurma', '🎉 Eğlence']
                  .map((option) => ElevatedButton(
                        onPressed: () {
                          setState(() => gameStake = option.substring(2));
                          hapticFeedback();
                        },
                        child: Text(option),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartGameButton() {
    final hasEmptyNames = players.any((player) => player.trim().isEmpty);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: hasEmptyNames ? null : startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '🎯 Oyunu Başlat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRulesSection() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oyun Kuralları:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green.shade800,
                  ),
            ),
            SizedBox(height: 8),
            ...([
              '• 3, 4 veya 5 oyuncuyla oynanır',
              '• 13 farklı ceza türü vardır',
              '• "Elden" cezası mecburen son elde (13. el) oynanır',
              '• Cezayı söyleyen VE bitiren aynı kişiyse +50 puan',
              '• Cezayı söyleyen başarısız: x2 ceza puanı alır',
              '• Son elde (Elden) bonus yok',
              '• İşler kağıt atan oyuncu -50 ceza puanı alır',
              '• Joker ile bitiren herkese x2 ceza puanı yedirir',
              '• Kazanma: En yüksek puan kazanır',
            ].map((rule) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    rule,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ))),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('🃏 Americano - El $currentRound'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: backToSetup,
            ),
            IconButton(
              icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  darkMode = !darkMode;
                });
                hapticFeedback();
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.play_arrow), text: 'Oyun'),
              Tab(icon: Icon(Icons.table_chart), text: 'Skorlar'),
              Tab(icon: Icon(Icons.info), text: 'Kurallar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGameTab(),
            _buildScoresTab(),
            _buildRulesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTab() {
    final availablePenalties = getAvailablePenalties();
    final remainingPenalties =
        penalties.where((p) => !playedPenalties.contains(p.id)).toList();
    final currentScores = getCurrentScores();
    final leader = getLeader();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Leader Card
          if (leader != null)
            Card(
              color: Colors.purple.shade100,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Lider: $leader (${currentScores[leader]} puan)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 16),

          // Player Scores Grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: playerCount == 3 ? 3 : 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final score = currentScores[player] ?? 0;
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: score >= 0
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${score > 0 ? '+' : ''}$score',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: score >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 16),

          // Round Input Section
          if (remainingPenalties.isNotEmpty)
            _buildRoundInputSection(availablePenalties),

          // Game Over Section
          if (remainingPenalties.isEmpty && gameHistory.isNotEmpty)
            _buildGameOverSection(),

          SizedBox(height: 16),

          // Remaining Penalties
          _buildRemainingPenaltiesSection(remainingPenalties),
        ],
      ),
    );
  }

  Widget _buildRoundInputSection(List<Penalty> availablePenalties) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El $currentRound - Puan Girişi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),

            // Penalty Selection
            Text('Bu Elde Oynanan Ceza:'),
            SizedBox(height: 8),
            availablePenalties.length == 1 && availablePenalties[0].id == 13
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      '⑬ Elden (Son El - Mecburi)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : DropdownButtonFormField<int>(
                    value: selectedPenalty,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    hint: Text('Ceza seçin...'),
                    items: availablePenalties.map((penalty) {
                      return DropdownMenuItem<int>(
                        value: penalty.id,
                        child: Text(
                            '${penalty.symbol} ${penalty.name} (${penalty.short})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPenalty = value;
                      });
                    },
                  ),

            SizedBox(height: 16),

            // Penalty Caller Selection
            Text('Cezayı Söyleyen Oyuncu:'),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: penaltyCaller.isEmpty ? null : penaltyCaller,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              hint: Text('Oyuncu seçin...'),
              items: players.map((player) {
                return DropdownMenuItem<String>(
                  value: player,
                  child: Text(player),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  penaltyCaller = value ?? '';
                });
              },
            ),

            SizedBox(height: 16),

            // Player Penalties Input
            ...players.map((player) => _buildPlayerPenaltyInput(player)),

            SizedBox(height: 16),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: canCalculate() ? calculateRoundScore : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  canCalculate()
                      ? 'Eli Kaydet ve Sonrakine Geç'
                      : 'Tüm Alanları Doldurun',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPenaltyInput(String player) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              player,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),

            // Penalty Count Input
            Text('Bu Elde Ceza Sayısı:', style: TextStyle(fontSize: 12)),
            SizedBox(height: 4),
            player == roundWinner
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      '0 (Eli Bitirdi)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : TextField(
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        roundPenalties[player] = int.tryParse(value) ?? 0;
                      });
                    },
                  ),

            SizedBox(height: 8),

            // Action Buttons
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildActionChip(
                  label: roundWinner == player ? '✓ Bitirdi' : 'Eli Bitirdi',
                  isSelected: roundWinner == player,
                  onTap: () {
                    setState(() {
                      roundWinner = player;
                    });
                    hapticFeedback();
                  },
                  color: Colors.green,
                ),
                _buildActionChip(
                  label: jokerIleBitiren == player ? '✓ Joker' : '🃏 Joker',
                  isSelected: jokerIleBitiren == player,
                  onTap: () {
                    setState(() {
                      jokerIleBitiren = jokerIleBitiren == player ? '' : player;
                      if (jokerIleBitiren == player) {
                        roundWinner = player;
                      }
                    });
                    hapticFeedback();
                  },
                  color: Colors.orange,
                ),
                _buildActionChip(
                  label: islerKagitAtan == player ? '✓ İşler' : 'İşler Kağıt',
                  isSelected: islerKagitAtan == player,
                  onTap: () {
                    setState(() {
                      islerKagitAtan = islerKagitAtan == player ? '' : player;
                    });
                    hapticFeedback();
                  },
                  color: Colors.red,
                ),
                _buildActionChip(
                  label:
                      cezayiSoyleyenAcamadi == player ? '✓ Açamadı' : 'Açamadı',
                  isSelected: cezayiSoyleyenAcamadi == player,
                  onTap: penaltyCaller == player
                      ? () {
                          setState(() {
                            cezayiSoyleyenAcamadi =
                                cezayiSoyleyenAcamadi == player ? '' : player;
                          });
                          hapticFeedback();
                        }
                      : null,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverSection() {
    final leader = getLeader();
    final currentScores = getCurrentScores();

    return Card(
      color: Colors.green.shade400,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '🎉 OYUN BİTTİ! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kazanan: $leader (${currentScores[leader]} puan)',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade700,
              ),
              child: Text('Yeni Oyun'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingPenaltiesSection(List<Penalty> remainingPenalties) {
    return Card(
      color: Colors.yellow.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Kalan Cezalar - ${remainingPenalties.length}/13',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 12),
            if (remainingPenalties.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: remainingPenalties.length,
                itemBuilder: (context, index) {
                  final penalty = remainingPenalties[index];
                  return Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          penalty.id == 13 ? Colors.red.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: penalty.id == 13
                            ? Colors.red.shade300
                            : Colors.yellow.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: penalty.id == 13
                                ? Colors.red.shade200
                                : Colors.yellow.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              penalty.symbol,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                penalty.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '(${penalty.short})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Text(
                'Tüm cezalar oynandı! 🎉',
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '📊 Kümülatif Puan Tablosu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              if (gameHistory.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('El')),
                      DataColumn(label: Text('Ceza')),
                      ...players
                          .map((player) => DataColumn(label: Text(player))),
                    ],
                    rows: gameHistory.map((round) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${round.round}')),
                          DataCell(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(round.penaltySymbol,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(round.penaltyName,
                                    style: TextStyle(fontSize: 10)),
                                Text('👤 ${round.penaltyCaller}',
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.blue)),
                              ],
                            ),
                          ),
                          ...players.map((player) {
                            final result = round.results
                                .firstWhere((r) => r.player == player);
                            return DataCell(
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${result.newTotal}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: result.newTotal >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    '(${result.totalChange > 0 ? '+' : ''}${result.totalChange})',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  if (result.gotBonus)
                                    Icon(Icons.emoji_events,
                                        size: 12, color: Colors.amber),
                                  if (result.isWinner && !result.gotBonus)
                                    Text('🏁', style: TextStyle(fontSize: 8)),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Henüz oynanmış el yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📖 Detaylı Americano Kuralları',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              _buildRuleSection('🎯 Oyun Malzemeleri:', [
                '52\'lik deste + 4 Joker ile oynanan kağıt oyunudur',
                'Min 3, Max 5 kişi ile oynanır',
                'Her oyuncuya 13 kağıt dağıtılır',
              ]),
              _buildRuleSection('📚 Terimler Sözlüğü:', [
                'Küt: Aynı rakamın farklı kart çeşitleri (örnek: 3♠, 3♥, 3♦)',
                'Seri: Bir kart çeşidinin sıralı şekilde bulunması (örnek: 2♠, 3♠, 4♠)',
                'Joker: İstenilen kart yerine geçer',
                'İşler Kağıt: Yere atılan ve başka oyuncuya yaramayan kart (-50 puan)',
                'Ceza Kartı: Sırası olmayan oyuncunun çektiği ekstra kart',
              ]),
              _buildRuleSection('🏆 Puan Sistemi:', [
                'Cezayı söyleyen + bitiren: +50 bonus puan',
                'Cezayı söyleyen başarısız: Görevini yapamadan (açamadan) başkası bitirirse x2 ceza puanı alır',
                'İşler kağıt atan: -50 ceza puanı',
                'Joker ile bitiren: Herkese x2 ceza puanı',
                'Son elde bonus yok: Elden cezasında +50 bonus alınamaz',
              ]),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: backToSetup,
                  child: Text('⚙️ Oyuncu Ayarları'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleSection(String title, List<String> rules) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 8),
          ...rules.map((rule) => Padding(
                padding: EdgeInsets.only(bottom: 4, left: 16),
                child: Text('• $rule'),
              )),
        ],
      ),
    );
  }
}
