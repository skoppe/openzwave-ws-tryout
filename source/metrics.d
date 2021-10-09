module metrics;

import std.typecons : Nullable, nullable;
import openzwave.types;
import std.datetime.systime : SysTime;
import types : Node, Value;
import sumtype;

string toSlug(string name) {
  import std.regex;
  import std.string : toLower;
  return name.toLower.replaceAll(regex("[^a-z0-9]+"),"_");
}

@("toSlug")
unittest {
  import unit_threaded;
  "Foo Bar".toSlug.should == "foo_bar";
  "[Foo - Bar]".toSlug.should == "_foo_bar_";
}

struct Gauge(T) {
  string name;
  string[string] labels;
  T value;
  SysTime timestamp;
  string toString() {
    import std.format;
    import std.algorithm : map;
    auto labels = this.labels.byKeyValue().map!(kv => format(`%s="%s"`, kv.key, kv.value));
    return format("%s{%-(%s,%)} %s %s", name.toSlug, labels, value, timestamp.toUnixTime);
  }
}

struct Toggle {
  string name;
  string[string] labels;
  bool value;
  SysTime timestamp;
  string toString() {
    import std.format;
    import std.algorithm : map;
    auto labels = this.labels.byKeyValue().map!(kv => format(`%s="%s"`, kv.key, kv.value));
    return format("%s{%s=\"%s\",%-(%s,%)} %s %s", name.toSlug, name.toSlug, value ? "on": "off", labels, value ? "1" : "0", timestamp.toUnixTime);
  }
}

@("gauge.double.toString")
unittest {
  import unit_threaded;
  import std.datetime.date : DateTime;
  import std.datetime.timezone : UTC;
  auto time = SysTime(DateTime(2018, 1, 1, 10, 30, 0), UTC());
  Gauge!double("Air Temperature", ["node":"Kitchen"], 22.0, time).toString().should == `air_temperature{node="Kitchen"} 22 1514802600`;
}

@("gauge.long.toString")
unittest {
  import unit_threaded;
  import std.datetime.date : DateTime;
  import std.datetime.timezone : UTC;
  auto time = SysTime(DateTime(2018, 1, 1, 10, 30, 0), UTC());
  Gauge!long("Air Temperature", ["node":"Kitchen"], 22, time).toString().should == `air_temperature{node="Kitchen"} 22 1514802600`;
}

@("toggle.toString")
unittest {
  import unit_threaded;
  import std.datetime.date : DateTime;
  import std.datetime.timezone : UTC;
  auto time = SysTime(DateTime(2018, 1, 1, 10, 30, 0), UTC());
  Toggle("Switch", ["node":"light"], false, time).toString().should == `switch{switch="off",node="light"} 0 1514802600`;
}

alias Metric = SumType!(Gauge!long, Gauge!double, Toggle);

class Metrics {
  Metric[string] metrics;
  void valueAdded(ref const Node node, ref const Value value) {
    addMetric(node, value);
  }
  void valueChanged(ref const Node node, ref const Value value) {
    addMetric(node, value);
  }
  void addMetric(ref const Node node, ref const Value value) {
    import std.datetime.systime : Clock;
    string name = value.label.toSlug;
    string[string] labels;
    labels["node"] = node.name;
    auto now = Clock.currTime();
    auto metric = value.value.match!((bool b){
        return nullable(Metric(Toggle(name, labels, b, now)));
      },(ubyte b) {
        return nullable(Metric(Gauge!long(name, labels, b, now)));
      },(float f) {
        return nullable(Metric(Gauge!double(name, labels, f, now)));
      },(int i) {
        return nullable(Metric(Gauge!long(name, labels, i, now)));
      },(short s) {
        return nullable(Metric(Gauge!long(name, labels, s, now)));
      },(ref t) {
        return Nullable!Metric.init;
      });
    if (metric.isNull)
      return;
    metrics[name] = metric.get;
  }
  string toOpenMetrics() {
    import std.array : appender;
    import std.algorithm : each;
    auto app = appender!(string);
    metrics.values.each!((metric) {
        app.put(metric.toString());
        app.put("\n");
      });
    return app.data;
  }
}

@("metrics")
unittest {
  import unit_threaded;
  import std.algorithm : startsWith;
  import types : Value, Node, ValueContent;
  auto ms = new Metrics();
  Node node = Node();
  node.name = "Living Room";
  Value value = Value();
  value.label = "Air Temperature";
  value.value = ValueContent(23.0);
  ms.valueAdded(node, value);
  ms.toOpenMetrics().startsWith(`air_temperature{node="Living Room"} 23`).should == true;
}
