
//import 'dart:async';
//import 'dart:convert';

enum Alteration {
  none,
  flat, 
  sharp,
}

class Note implements ChordOrNote {
  final String name;
  Alteration alteration;
  int octave;
  Note({
    required this.name,
    this.alteration = Alteration.none,
    this.octave = 0,
  });
  
  Note copyWith({name, alteration, octave}) {
    return Note(
      name: name ?? this.name, 
      alteration: alteration ?? this.alteration, 
      octave: octave ?? this.octave);
  }
}

class Key {
  final Note note;
  
  Key({required this.note});
}

class Chord implements ChordOrNote {
  List<Note> _notes = [];
  
  Chord over(Note baseNote) {
    _notes.insert(0, baseNote);
    return this;
  }
}

class KeyboardSize {
  static const int small = 52;
    static const int standard = 61;
  static const int large = 72;
  static const int full = 88;
}

abstract class ChordOrNote {
  
}

class Keyboard {
  static final c = Key(note: Note(name: "C"));
  static final cSharp = Key(note: Note(name: "C", alteration: Alteration.sharp));
  static final d = Key(note: Note(name: "D"));
  static final dSharp = Key(note: Note(name: "D", alteration: Alteration.sharp));
  static final e = Key(note: Note(name: "E"));
  static final f = Key(note: Note(name: "F"));
  static final fSharp = Key(note: Note(name: "F", alteration: Alteration.sharp));
  static final g = Key(note: Note(name: "G"));
  static final gSharp = Key(note: Note(name: "G", alteration: Alteration.sharp));
  static final a = Key(note: Note(name: "A"));
  static final aSharp = Key(note: Note(name: "A", alteration: Alteration.sharp));
  static final b = Key(note: Note(name: "B"));

  final List<Key> _keys = [];
  final List<Key> _mainKeys = [
    Keyboard.c,
    Keyboard.cSharp,
    Keyboard.d,
    Keyboard.dSharp,
    Keyboard.e,
    Keyboard.f,
    Keyboard.fSharp,
    Keyboard.g,
    Keyboard.gSharp,
    Keyboard.a,
    Keyboard.aSharp,
    Keyboard.b,
  ];
  
  List<Key> get keys => _keys;
  
  int getKeyIndex(Key key) {
    return _mainKeys.indexOf(key);
  }
  
  int _cursor = 0;
  int _octave = 0;
  
  void _next() {
    _cursor++;
    
    if (_cursor >= _mainKeys.length) {
      _cursor = 0;
      _octave++;
    }
  }
  
  void play(List<ChordOrNote> items) {
    
  }
  
  void _createKeys(Key firstKey, Key firstOctaveKey, int keysCount) {
    if (keysCount == 0) return;
    _cursor = getKeyIndex(firstKey);

    int octave;
    for (int i = 0; i < keysCount; i++) {     
      if (_octave < firstOctaveKey.note.octave) {
        octave = 0;
      } else {
        octave = _octave;
      }
      final Note note = _mainKeys[_cursor].note;
      final Key key = Key(note: note.copyWith(octave: octave));
      _keys.add(key);
      _next();
    }
  }
  
  int get length => _keys.length;
  
   Keyboard.full() {
    final firstKey = Keyboard.a
                      ..note
                      .octave = 0;
     final firstOctaveKey = Keyboard.c..note.octave = 1;
    
     _createKeys(firstKey, firstOctaveKey, KeyboardSize.full);
  }
  
   Keyboard.standard() {
    final firstKey = Keyboard.c
                      ..note
                      .octave = 1;
     final firstOctaveKey = firstKey;
    
     _createKeys(firstKey, firstOctaveKey, KeyboardSize.standard);
  }
}



class Piano {
  final keyboard = Keyboard.standard();
  
  
}


void main() {
  final piano = Piano();
  piano.keyboard.play([Chord().over(Keyboard.c.note)]);
  piano.keyboard.keys.forEach((Key key) {
   print("${key.note.name} ${key.note.alteration} ${key.note.octave}");
  });
}
