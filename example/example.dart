import 'package:swiss_knife/swiss_knife.dart';

class Sys {
  final EventStream<bool> onLoad = EventStream();

  void initialize() {
    onLoad.add(true);

    for (var user in users) {
      user.notify('System initialized!');
    }
  }

  final List<User> users = [];

  void addUser(User user) {
    users.add(user);
  }
}

class User {
  final EventStream<String> onNotification = EventStream();

  void notify(String msg) {
    onNotification.add(msg);
  }
}

void main() {
  var sys = Sys();

  sys.onLoad.listenAsFuture().then((loaded) {
    print('${dateFormat_YYYY_MM_dd_HH_mm_ss()}> System loaded: $loaded');
  });

  var user = User();
  sys.addUser(user);

  user.onNotification.listen((msg) {
    print('${getCurrentTimeMillis()}[${getDateAmPm()}]> NOTIFICATION> $msg');
  });

  sys.initialize();
}
