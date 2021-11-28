//Updated with Null Safety on 11/28/2021

import "package:flutter/material.dart";
import 'dart:async';




//Models

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
    if (_value < Energy.max) _value += amount;
  }
  
  void decrease(int amount) {
    if (_value > 0) _value -= amount;
  }
}


class Player extends EventEmitter<GameEvent> {
  final int id;
  Game? game;
  bool isReady = false;

  GameCharacter? character;
  final energy = Energy();
  
  void setCharacter(GameCharacter value) {
    character = value;
    character!.isSelected = true;
    isReady = true;
  }
  
  bool get isActive => game != null;
  
  void attack(Player player, Attack attack) {
    if (game == null) return;
    game!.emit(
      PlayerAttackedEvent(
        attacker: this, 
        attacked: player, 
        attack: attack,
        game: game,
      )
    );
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
  final String imageUrl;
  late Image image;
  bool isSelected = false;

  GameCharacter({
    required this.name,
    required this.imageUrl,
  }) {
    image = Image.network(imageUrl);
  }
}


//Events

class EventEmitter<T> {
 final _streamController = StreamController<T>.broadcast();
  
  void dispose() {
    _streamController.sink.close();
    _streamController.close();
  }
  
   void listen(Function fn) {
    _streamController.stream.listen((T event) {
         fn.call(event);
    });
  }
  
   void emit(T event) {
     _streamController.sink.add(event);
  }
}


class Event {}


class CustomEvent extends GameEvent {
  final String text;
  
  CustomEvent(this.text) : super(game: Game(maxPlayers: 0));
}


class GameEvent extends Event {
  final Game game;
  
  GameEvent({required this.game});
}


class GameLoadingEvent extends GameEvent {
  GameLoadingEvent({required game}) : super(game: game);
}


class SelectCharacterEvent extends GameEvent {
  SelectCharacterEvent({required game}) : super(game: game);
}


class GameRoundEvent extends GameEvent {
  final int round;
  
  GameRoundEvent({required this.round, required game}) : super(game: game);
}


class PlayerAttackedEvent extends GameEvent  {
  final Player attacker;
  final Player attacked;
  final Attack attack;
  
  PlayerAttackedEvent({
    required this.attacker,
    required this.attacked,
    required this.attack,
    required game,
  }) : super(game: game);
}


class PlayerSelectedEvent extends GameEvent {
  final Player player;
  final GameCharacter character;

  PlayerSelectedEvent({
    required this.player, 
    required this.character, 
    required game,
 }) : super(game: game);
}


class GameStartedEvent extends GameEvent {
  GameStartedEvent({required game}) : super(game: game);
}


class GameCharacterAddedEvent extends GameEvent {
  final GameCharacter character;
  
  GameCharacterAddedEvent({required this.character, required game}) : super(game: game);
}



//Game

class Game extends EventEmitter<GameEvent> {
 
  final List<GameCharacter> _characters = [];
  final List<Player> _players = [];

  final int maxPlayers;
  Player? currentPlayer;

  
  Game({
    required this.maxPlayers
  }) {
    config();
  }
  
  int get selectedPlayersCount => _players.where((Player item) => item.isReady).length;
  
  List<GameCharacter> findAllCharacters() {
    return _characters;
  }
  
  void selectCharacter(Player player, GameCharacter character) {
    if (selectedPlayersCount >= maxPlayers) return;
    player.setCharacter(character);
    emit(PlayerSelectedEvent(
        game: this,
        player: player, 
        character: character, 
      )
    );
  }
  
  void delay(Function() fn, int milliseconds) {
    Timer(Duration(milliseconds: milliseconds), fn);
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
    emit(GameCharacterAddedEvent(game: this, character: character));
  }

  void config() {
    for (int i = 0; i < maxPlayers; i++) {
      final player = Player(id: i);
      player.addToGame(this);
      _players.add(player);
    }
  }
  
  void start() {
    delay(() => emit(GameLoadingEvent(game: this)), 1.sec);
  }
  
  void stop() {
   
  }
}



//Custom Characters

class Scorpion extends GameCharacter {
  static final spear = Attack(name: "Spear",damage: 20);
  Scorpion() : super(
    name: "Scorpion",
    imageUrl: "https://raw.githubusercontent.com/angelhdz/dartpad_tests/main/fight_game/assets/scorpion_avatar.png"
  );
}

class SubZero extends GameCharacter {
  static final freeze = Attack(name: "Freeze",damage: 20);
  SubZero() : super(
    name: "Sub-Zero",
    imageUrl: "https://raw.githubusercontent.com/angelhdz/dartpad_tests/main/fight_game/assets/subzero_avatar.png"
  );
}


//Custom Games

class MortalKombat extends Game {
  int round = 1;
  MortalKombat() : super(maxPlayers: 2);
  
  @override
  void config() {
    super.config();
    addGameCharacter(Scorpion());
    addGameCharacter(SubZero());
  }
  
  
  @override
  void start() {
    listen((GameEvent event) {
     
     if (event is GameLoadingEvent) {
       delay(() => emit(GameStartedEvent(game: this)), 1.sec);
       
     } else if (event is GameStartedEvent) {
      
       delay(() => emit(SelectCharacterEvent(game: this)), 1.sec);
      
    } else if (event is PlayerSelectedEvent) {
       print("selectedPlayersCount: $selectedPlayersCount");
       if (selectedPlayersCount >= maxPlayers) {
         delay(() => emit(GameRoundEvent(game: this, round: round)), 1.sec);
       }
        
    } else if (event is GameRoundEvent) {
      
    
    } else if (event is PlayerAttackedEvent) {
      event.attacked.energy.decrease(event.attack.damage);
  
      if (event.attacked.energy.value == Energy.zero) {

      }
    } 
  });
    super.start();
  }
}



//Utils

extension Time on int {
  int get sec => this * 1000;
  int get min => sec * 60;
  int get hour => min * 60;
}



//Main
void main() {
 runApp(App());
}


class App extends StatelessWidget {
  @override
  Widget build(context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: "/",
      routes: {
        "/": (_) => HomeScreen(),
        "/mortal-kombat-1": (_) => MortalKombatScreen()
      }
    );
  }
}

class HomeScreen extends StatelessWidget {
    @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
       child: Padding(
         padding: const EdgeInsets.all(40.0),
        child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget> [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
               
              ElevatedButton(
          child: const Text("Play"),
         onPressed: () {
           Navigator.of(context).pushNamed("/mortal-kombat-1");
         }
       ),
           const  Padding(
                padding:  EdgeInsets.only(left: 10.0),
                child:   Text("Mortal Kombat 1")
                ) 
            ]
            ),
         const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
             
              ElevatedButton(
          child: const Text("Play"),
         onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not available yet.")));
         }
       ),
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child:  Text("The Legend Of Zelda: Ocarina of Time")
                ), 
            ]
            )
        ]
       )
       )
    )
    );
  }
}

const mainTextStyle =  TextStyle(
  color: Colors.yellow,
  fontSize: 36,
);

class MortalKombatScreen extends StatefulWidget {
   @override _MortalKombatScreenState createState() => _MortalKombatScreenState();
}

class _MortalKombatScreenState extends State<MortalKombatScreen> {
  final game = MortalKombat();
  final _streamController = StreamController<GameEvent>();
  
@override
  void dispose() {
    game.dispose();
    _streamController.close();
    super.dispose();
  }
  
  @override
  void initState() {
    print("init");
    game.listen((GameEvent event) {
      print(event);
      _streamController.sink.add(event);
    });
    game.start();
    super.initState();
  }
  
  @override
  Widget build( context ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder(
        initialData: CustomEvent( "System starting..." ),
        stream: _streamController.stream,
        builder: ( _, snapshot ) {
          return snapshot.hasData
            ? SceneBuilder(
                event: snapshot.data as GameEvent,
                 builder: ( context, event ) {
                  return Center(
        child: event is GameLoadingEvent
      ? const CircularProgressIndicator()
      : event is GameRoundEvent
      ? GameRoundScene( event: event )
      : event is PlayerSelectedEvent
      ? SelectFighterScene( event: event )
      : event is GameStartedEvent
      ? TitleScene( event: event )
      : event is SelectCharacterEvent
        ? SelectFighterScene( event: event )
        : event is CustomEvent
         ? Text( event.text )
         : const Text( "Unknown event." )
    );
                }
              )
            : snapshot.hasError 
              ? Text(snapshot.error.toString())
              : const Center(child: CircularProgressIndicator());
        }
      )
    );
  }
}



class SceneBuilder extends StatelessWidget  {
  final Function builder;
  final GameEvent event;

  
  const SceneBuilder({required this.builder, required this.event});
  
  @override
  Widget build(context) {
    return builder(context, event);
  }
}

class GameRoundScene extends Scene {
   const GameRoundScene({required event}) : super(event: event);
  
  @override
  Widget build(context) {
    final Size size = MediaQuery.of(context).size;
    return  SizedBox(
         width: size.width,
      height: size.height,
      child:  const  Text( "ROUND ONE... FIGHT!" , style: mainTextStyle )
      );
  }
}

class TitleScene extends Scene {
  const TitleScene({required event}) : super(event: event);
  
  @override
  Widget build(context) {
    final Size size = MediaQuery.of(context).size;
    return  Container(
         width: size.width,
      height: size.height,
      color: Colors.red[800],
      child: const Center(
      child: Text("Mortal Kombat", style: mainTextStyle)
    )
    );
  }
}

class SelectFighterScene extends Scene {
 
  const SelectFighterScene({required event}) : super(event: event);
  
  @override
  Widget build(context) {
    final Size size = MediaQuery.of(context).size;
    
    return  Container(
      width: size.width,
      height: size.height,
      color: Colors.grey,
      child: Column(
       
        crossAxisAlignment: CrossAxisAlignment.center,
       children: <Widget> [
         const Text("Choose Your Fighter", style: mainTextStyle),
         GridView.count(
           shrinkWrap: true,
          crossAxisCount: 6,
          mainAxisSpacing: 4,
           crossAxisSpacing: 4,
           children: event.game.findAllCharacters().map((GameCharacter character) {
             return InkWell(
               onTap: () {
                 final p1 = event.game.findPlayer(0);
                 event.game.selectCharacter(p1, character);
               },
              child: Container(
                decoration: character.isSelected
                  ? BoxDecoration(
                    border: Border.all(
                      color: Colors.red[800] as Color, 
                      style: BorderStyle.solid,
                      width: 6.0,
                    )
                    )
                : null,
               child: character.image
             )
             ); 
            }
           ).toList()
         )
       ]
    )
  );
  }
}




abstract class Scene extends StatelessWidget  {
  final GameEvent event;
  
  const Scene({required this.event});
}




