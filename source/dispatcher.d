import openzwave.types;
import std.traits : hasMember;
import types;
import core.sync.mutex : Mutex;

// todo refactor app.Dispatcher into receiver and dispatcher
class Dispatcher {
  alias OnValueAdded = void delegate(ref const Node node, ref const Value value);
  alias OnValueChanged = void delegate(ref const Node node, ref const Value value);
  alias OnValueRemoved = void delegate(ref const Node node, ref const Value value);
  alias OnNodeRemoved = void delegate(ref const Node node);
  alias OnNodeAdded = void delegate(ref const Node node);
  this(){
    mutex = new Mutex;
  }
  void add(T)(auto ref T t) @trusted {
    mutex.lock();
    scope(exit) mutex.unlock();
    static if (hasMember!(T, "nodeAdded")) {
      nodeAdded ~= &t.nodeAdded;
      foreach(n; nodes.values)
        t.nodeAdded(n);
    }
    static if (hasMember!(T, "valueAdded")) {
      valueAdded ~= &t.valueAdded;
      foreach(v; values.values)
        t.valueAdded(nodes[v.getNodeIdentifier], v);
    }
    static if (hasMember!(T, "valueChanged")) {
      valueChanged ~= &t.valueChanged;
    }
    static if (hasMember!(T, "valueRemoved")) {
      valueRemoved ~= &t.valueRemoved;
    }
    static if (hasMember!(T, "nodeRemoved")) {
      nodeRemoved ~= &t.nodeRemoved;
    }
  }
  void remove(T)(auto ref T t) {
    mutex.lock();
    scope(exit) mutex.unlock();
    import std.algorithm : remove, countUntil;
    static if (hasMember!(T, "valueAdded")) {
      valueAdded = valueAdded.remove(valueAdded.countUntil(&t.valueAdded));
    }
    static if (hasMember!(T, "valueChanged")) {
      valueChanged = valueChanged.remove(valueChanged.countUntil(&t.valueChanged));
    }
    static if (hasMember!(T, "valueRemoved")) {
      valueRemoved = valueRemoved.remove(valueRemoved.countUntil(&t.valueRemoved));
    }
    static if (hasMember!(T, "nodeRemoved")) {
      nodeRemoved = nodeRemoved.remove(nodeRemoved.countUntil(&t.nodeRemoved));
    }
    static if (hasMember!(T, "nodeAdded")) {
      nodeAdded = nodeAdded.remove(nodeAdded.countUntil(&t.nodeAdded));
    }
  }
  void onValueAdded(const ref Value value) {
    values[value.id] = value;
    dispatch!(valueAdded)(nodes[value.getNodeIdentifier()],value);
  }
  void onValueChanged(const ref Value value) {
    values[value.id] = value;
    dispatch!(valueChanged)(nodes[value.getNodeIdentifier()],value);
  }
  void onValueRemoved(const ref Value value) {
    values.remove(value.id);
    dispatch!(valueRemoved)(nodes[value.getNodeIdentifier()],value);
  }
  void onNodeAdded(const ref Node node) {
    nodes[node.id] = node;
    dispatch!(nodeAdded)(node);
  }
  void onNodeRemoved(const ref Node node) {
    nodes.remove(node.id);
    dispatch!(nodeRemoved)(node);
  }
  Node[ulong] nodes;
  Value[ulong] values;
private:
  void dispatch(alias list, Ts...)(Ts ts) {
    mutex.lock();
    scope(exit) mutex.unlock();
    foreach(item; list)
      item(ts);
  }
  Mutex mutex;
  OnValueAdded[] valueAdded;
  OnValueChanged[] valueChanged;
  OnValueRemoved[] valueRemoved;
  OnNodeRemoved[] nodeRemoved;
  OnNodeAdded[] nodeAdded;
}
