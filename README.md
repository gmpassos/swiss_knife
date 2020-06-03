# Swiss Knife

[![pub package](https://img.shields.io/pub/v/swiss_knife.svg)](https://pub.dartlang.org/packages/swiss_knife)
[![pub package](https://img.shields.io/github/v/tag/gmpassos/swiss_knife)](https://github.com/gmpassos/swiss_knife/releases)
[![pub package](https://img.shields.io/github/languages/code-size/gmpassos/swiss_knife)](https://github.com/gmpassos/swiss_knife)
[![license](https://img.shields.io/github/license/gmpassos/swiss_knife)](https://github.com/gmpassos/swiss_knife/blob/master/LICENSE)
[![pub package](https://img.shields.io/liberapay/patrons/gmpassos)](https://en.liberapay.com/gmpassos/)


Dart Useful Tools - collections, math, date, uri, json, events, resources, etc...

## Usage

A simple usage example:

```dart
import 'package:swiss_knife/swiss_knife.dart';

class User {

  final EventStream<String> onNotification = new EventStream() ;

  void notify(String msg) {
    onNotification.add(msg) ;
  }

}

void main() {

  User user = new User() ;

  user.onNotification.listen((msg) {
    print("NOTIFICATION> $msg") ;
  });

}

```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gmpassos/swiss_knife/issues

## Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

Dart free & open-source [license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).
