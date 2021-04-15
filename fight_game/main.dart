import 'dart:html';
import 'dart:async';

class Attack {
  final int damage;
  final String name;
  
  Attack({
    required this.damage,
    required this.name,
  });
}

class Energy {
  static const int max = 100;
  static const int low = 49;
  static const int half = 50;
  static const int zero = 0;
  
  int _value;
  
  Energy([this._value = Energy.max]);
  
  int get value => _value;
  
  void increase(int amount) {
    if (this._value < Energy.max) this._value += amount;
  }
  
  void decrease(int amount) {
    if (this._value > 0) this._value -= amount;
  }
}

class EventEmitter<T> {
  StreamController<T>? _streamController = StreamController();
  
  void dispose() {
    _streamController!.close();
    _streamController = null;
  }
  
   void listen(Function fn) {
     _streamController = StreamController<T>();
    _streamController!.stream.listen((T event) {
      Timer(Duration(seconds: 3), () {
         fn.call(event);
     });
    
    });
  }
  
   void emit(T event) {
     _streamController!.sink.add(event);
  }
}

class Player extends EventEmitter<GameEvent> {
  final int id;
  Game? game;
  bool isReady = false;

  GameCharacter? character;
  final energy = Energy();
  
  void setCharacter(GameCharacter value) {
    this.character = value;
    isReady = true;
  }
  
  bool get isActive => game != null;
  
  void attack(Player player, Attack attack) {
    if (game == null) return;
    this.game!.emit(PlayerAttackedEvent(this, player, attack));
  }
  
  Player({required this.id});
  
  void addToGame(Game game) {
    this.game = game;
  }
  
  void removeFromGame(Game game) {
    if (this.game == game) {
      this.game = null;
      isReady = false;
    }
  }
}

class GameCharacter extends EventEmitter<GameEvent> {
 final String name;

  GameCharacter({
    required this.name
  });
}

class GameEvent {

}

class PlayerAttackedEvent extends GameEvent  {
  final Player attacker;
  final Player attacked;
  final Attack attack;
  
  PlayerAttackedEvent(
    this.attacker,
    this.attacked,
    this.attack,
  );
}

class PlayerSelectedEvent extends GameEvent {
  final Player player;
  final GameCharacter character;
  final int selectedPlayersCount;
  
  PlayerSelectedEvent(this.player, this.character, this.selectedPlayersCount);
}

class GameStartedEvent extends GameEvent {
  final Game game;
  
  GameStartedEvent(this.game);
}

class GameCharacterAddedEvent extends GameEvent {
  final GameCharacter character;
  
  GameCharacterAddedEvent(this.character);
}

class Game extends EventEmitter<GameEvent> {
 
  final List<GameCharacter> _characters = [];
  final List<Player> _players = [];

  final int maxPlayers;
  Player? currentPlayer = null;
  late HtmlElement stage;
  
  Game({
    required this.maxPlayers
  }) {
    config();
  }
  
  void selectCharacter(Player player, GameCharacter character) {
    player.setCharacter(character);
    final int selectedPlayersCount = _players.where((item) => item.isReady).length;
    emit(PlayerSelectedEvent(player, character, selectedPlayersCount));
  }
  
  void mount(String htmlElementId) {
    stage = querySelector(htmlElementId) as HtmlElement;
  }
  
  Player findPlayer(int id) {
    return _players.firstWhere((Player item) => item.id == id);
  }
  
  GameCharacter findCharacter(String name) {
    return _characters.firstWhere((GameCharacter item) {
      return item.name == name;
    });
  }
  
  void addGameCharacter(GameCharacter character) async {
    _characters.add(character);
    emit(GameCharacterAddedEvent(character));
  }
  
  //void _handlePlayerEvent(GameEvent event) {
    
  //}
  
  void config() {
    for (int i = 0; i < this.maxPlayers; i++) {
      final player = Player(id: i);
      player.addToGame(this);
      _players.add(player);
    }
  }
  
  void start() {
    return emit(GameStartedEvent(this));
  }
  
  void stop() {
   
  }
}

class Scorpion extends GameCharacter {
  static final spear = Attack(name: "Spear",damage: 20);
  Scorpion() : super(name: "Scorpion");
}

class SubZero extends GameCharacter {
  static final freeze = Attack(name: "Freeze",damage: 20);
  SubZero() : super(name: "Sub-Zero");
}

class GameRoundEvent extends GameEvent {
  final int round;
  
  GameRoundEvent(this.round);
}

class MortalKombat extends Game {
  int round = 1;
  MortalKombat() : super(maxPlayers: 2);
  
  @override
  void config() {
    super.config();
    addGameCharacter(Scorpion());
    addGameCharacter(SubZero());
  }
  
  void delay(Function() fn, int milliseconds) {
    Timer(Duration(milliseconds: milliseconds), fn);
  }
  
  @override
  void start() {
    listen((GameEvent event) {
      final Player playerOne = findPlayer(0);
      final Player playerTwo = findPlayer(1);
      
    if (event is GameStartedEvent) {
      print("Game started");

      final GameCharacter scorpion = findCharacter("Scorpion");
      final GameCharacter subZero = findCharacter("Sub-Zero");
      
      delay(() => selectCharacter(playerOne, subZero), 2000);
      delay(() =>selectCharacter(playerTwo, scorpion), 4000);
    } else if (event is PlayerSelectedEvent) {
      final int playerId = event.player.id;
      final String characterName = event.character.name;
      final text = "Player $playerId selected $characterName.";
      
      stage.innerHtml = '<h1 class="game-text-yellow">${text}</h1>';
      
      if (event.selectedPlayersCount == maxPlayers) {
        emit(GameRoundEvent(round));
      }
    } else if (event is GameRoundEvent) {
      final int round = event.round;
      final text = "Round $round, FIGHT!";
      final String charOne = playerOne.character!.name;
      final int energyOne = playerOne.energy.value;
      final int energyTwo = playerTwo.energy.value;
      final String charTwo = playerTwo.character!.name;
      print(text);
      
      String html = "";
      
      html = '''
        <div class="header">
         <div class="status-group">
         <span class="game-text-yellow">$charOne</span><progress class="status-bar" value="$energyOne" max="${Energy.max}"/>
         </div>
          <div class="status-group">
          <span class="game-text-yellow">$charTwo</span><progress class="status-bar" value="$energyTwo" max="${Energy.max}"/>
          </div>
        </div>
      ''';
      html += '<h1 class="game-text-yellow">${text}</h1>';
      stage.innerHtml = html;
      
      delay(() => playerOne.attack(playerTwo, SubZero.freeze), 2000);
      delay(() => playerTwo.attack(playerOne, Scorpion.spear), 4000);
      delay(() => playerOne.attack(playerTwo, SubZero.freeze), 6000);
      delay(() => playerTwo.attack(playerOne, Scorpion.spear), 8000);
      delay(() => playerOne.attack(playerTwo, SubZero.freeze), 10000);
      delay(() => playerOne.attack(playerTwo, SubZero.freeze), 12000);
      delay(() => playerOne.attack(playerTwo, SubZero.freeze), 14000);
    } else if (event is PlayerAttackedEvent) {
      event.attacked.energy.decrease(event.attack.damage);
      final String attacker = event.attacker.character!.name;
      final String attacked = event.attacked.character!.name;
      final String attack = event.attack.name;
      final int energy = event.attacked.energy.value;
      final int attackedId = event.attacked.id;
      
      final String charOne = playerOne.character!.name;
      final int energyOne = playerOne.energy.value;
      final int energyTwo = playerTwo.energy.value;
      final String charTwo = playerTwo.character!.name;
       String html = "";
      
      html = '''
        <div class="header">
         <div class="status-group">
         <span class="game-text-yellow">$charOne</span><progress class="status-bar" value="$energyOne" max="${Energy.max}"/>
         </div>
          <div class="status-group">
          <span class="game-text-yellow">$charTwo</span><progress class="status-bar" value="$energyTwo" max="${Energy.max}"/>
          </div>
        </div>
      ''';
      
      stage.innerHtml = html;
      final style = attacker == "Scorpion" 
        ? "scorpion"
        : "sub-zero";
      html += '<h1 class="$style">${attack}!</h1>';
      stage.innerHtml = html;
      print("$attacker attacked $attacked with $attack!");
      print("Player $attackedId energy: $energy/${Energy.max}");
      
      if (energy == Energy.zero) {
        html += '<h1 class="game-text-white">$attacker wins!</h1>';
        stage.innerHtml = html;
        print("$attacker wins!");
      }
    } 
  });
    super.start();
  }
}




void main() {
  final game = MortalKombat();
  game.mount("#game");
  game.start();
}


