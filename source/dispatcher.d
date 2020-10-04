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
  alias OnNodeUpdated = void delegate(ref const Node node);
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
    static if (hasMember!(T, "nodeUpdated")) {
      nodeUpdated ~= &t.nodeUpdated;
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
    static if (hasMember!(T, "nodeUpdated")) {
      nodeUpdated = nodeUpdated.remove(nodeUpdated.countUntil(&t.nodeUpdated));
    }
  }
  void onValueAdded(immutable ValueAdded message) {
    values[message.value.id] = message.value;
    dispatch!(valueAdded)(nodes[message.value.getNodeIdentifier],message.value);
  }
  void onValueChanged(immutable ValueChanged message) {
    values[message.valueId].value = message.content;
    auto value = values[message.valueId];
    dispatch!(valueChanged)(nodes[value.getNodeIdentifier],value);
  }
  void onValueRemoved(ValueRemoved message) {
    auto oldVal = values[message.valueId];
    values.remove(message.valueId);
    dispatch!(valueRemoved)(nodes[oldVal.getNodeIdentifier()],oldVal);
  }
  void onNodeAdded(NodeAdded message) {
    nodes[message.node.id] = message.node;
    dispatch!(nodeAdded)(message.node);
  }
  void onNodeRemoved(NodeRemoved message) {
    auto oldNode = nodes[message.nodeId];
    nodes.remove(message.nodeId);
    dispatch!(nodeRemoved)(oldNode);
  }
  void onNodeUpdated(NodeUpdated message) {
    nodes[message.node.id] = message.node;
    dispatch!(nodeUpdated)(message.node);
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
  OnNodeUpdated[] nodeUpdated;
}

struct NodeAdded {
  Node node;
}
struct NodeUpdated {
  Node node;
}
struct NodeRemoved {
  size_t nodeId;
}
struct ValueAdded {
  Value value;
}
struct ValueChanged {
  size_t valueId;
  ValueContent content;
}
struct ValueRemoved {
  size_t valueId;
}
