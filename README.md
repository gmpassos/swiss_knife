# Swiss Knife

[![pub package](https://img.shields.io/pub/v/swiss_knife.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/swiss_knife)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fgmpassos%2Fswiss_knife.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fgmpassos%2Fswiss_knife?ref=badge_shield)

[![CI](https://img.shields.io/github/workflow/status/gmpassos/swiss_knife/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/swiss_knife/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/swiss_knife?logo=git&logoColor=white)](https://github.com/gmpassos/swiss_knife/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/swiss_knife/latest?logo=git&logoColor=white)](https://github.com/gmpassos/swiss_knife/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/swiss_knife?logo=git&logoColor=white)](https://github.com/gmpassos/swiss_knife/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/swiss_knife?logo=github&logoColor=white)](https://github.com/gmpassos/swiss_knife/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/swiss_knife?logo=github&logoColor=white)](https://github.com/gmpassos/swiss_knife)
[![License](https://img.shields.io/github/license/gmpassos/swiss_knife?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/swiss_knife/blob/master/LICENSE)

Dart Useful Tools:

- collections
- data
- date
- events
- io
- json
- loader
- math
- regexp
- resources
- string
- uri

and more...

## API

See Swiss Knife [API documentation](https://pub.dev/documentation/swiss_knife/latest/) for full functionalities.

## Usage

A simple `EventStream` usage example:

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


[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fgmpassos%2Fswiss_knife.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fgmpassos%2Fswiss_knife?ref=badge_large)