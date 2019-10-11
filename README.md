# Swiss Knife

Dart useful tools: collections, math, date, etc...

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
