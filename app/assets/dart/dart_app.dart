import 'dart:html';
import 'dart:convert';
import 'package:websocket_rails/websocket_rails.dart';
import 'package:logging/logging.dart';

Logger log;
WebSocketRails railsWs;

void main() {
  final ButtonElement startButton = querySelector('button#start');
  final SelectElement logLevelSelect = querySelector('select#log-level');
  final TextAreaElement logOut = querySelector('textarea#log');
  final TextAreaElement statusOut = querySelector('textarea#status');

  Logger.root.level = Level.ALL;
  Level.LEVELS.forEach((Level _) => logLevelSelect.append(new OptionElement()
    ..label = _.name
    ..value = _.value.toString())
  );
  logLevelSelect.onChange.listen((Event _) {
    OptionElement selectedOption = logLevelSelect.selectedOptions[0];
    Logger.root.level = new Level(selectedOption.label, int.parse(selectedOption.value));
    logOut.appendText('Logger level changed LEVEL = ${Logger.root.level}\n');
  });
  Logger.root.onRecord.listen((LogRecord rec) {
    logOut.appendText('\n${rec.sequenceNumber} ${rec.level.name} ${rec.loggerName}: ${rec.message}');
    logOut.scrollTop = logOut.scrollHeight;
  });
  log = new Logger('TestApp');
  logOut.appendText('Logger initialized LEVEL = ${Logger.root.level}\n');

  int serial = 0;
  dynamic appendTestDataCb = (TestData data) {
    statusOut.appendText('${serial++} TestData: ${data.title}\n\t${data.body}\n\n');
    statusOut.scrollTop = statusOut.scrollHeight;
  };

  startButton.onClick.listen((_) {
    startButton.attributes['disabled'] = 'disabled';
    railsWs = new WebSocketRails('${window.location.host}/websocket');
    railsWs.connect();
    WsChannel nCh = railsWs.subscribe('testdata');
    nCh.getEventStream('push').listen((_) => TestData.fromJSONArray(_).forEach(appendTestDataCb));

    railsWs.getEventStream('data').listen((WsData _) {
      TestData.fromJSONArray(_.data).forEach(appendTestDataCb);
    });

    railsWs.trigger('pull');
  });
}

final int serial = 0;
void appendTestData(TestData data) {

}

class TestData {
  String title, body;

  TestData(Map<String,String> data) {
    this.title = data['title'];
    this.body = data['body'];
  }

  static decodeJSON(String jsonData) {
    dynamic decoded = JSON.decode(jsonData);
    if(decoded is List) return decoded.map((_) => new TestData(_));
    else if(decoded is Map) return new TestData(decoded);
  }

  static List<TestData> fromJSONArray(List data) {
    return data.map((_) => new TestData(_));
  }
}
