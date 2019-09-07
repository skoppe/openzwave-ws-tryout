import std.stdio;

import openzwave.types;
import openzwave.manager;
import openzwave.valueid;
import openzwave.options;
import sumtype;
import std.conv : to;
import vibe.core.core;
import vibe.core.log;
import vibe.http.router;
import vibe.http.server;
import vibe.http.websockets;
import vibe.data.json;
import std.algorithm;
import core.stdcpp.string;
import std.traits : hasMember;
import std.concurrency;
import std.string;

struct GroupNotification {
  ValueID valueId;
  ubyte groupIdx;
  this(const ref Notification n) {
    this.valueId = n.valueId;
    this.groupIdx = n.groupIdx;
  }
}
struct NodeEventNotification {
  ValueID valueId;
  ubyte event;
  this(const ref Notification n) {
    this.valueId = n.valueId;
    this.event = n.event;
  }
}
struct ControllerNotification {
  ValueID valueId;
  ubyte event;
  ubyte notification;
  ubyte command;
  this(const ref Notification n) {
    this.valueId = n.valueId;
    this.event = n.event;
    this.notification = n.notification;
    this.command = n.command;
  }
}
enum ButtonNotificationType {
                             CreateButton = cast(uint)NotificationType.CreateButton,
                             DeleteButton,
                             ButtonOn,
                             ButtonOff
}
struct ButtonNotification {
  ButtonNotificationType type;
  ValueID valueId;
  ubyte buttonId;
  this(const ref Notification n) {
    this.type = cast(ButtonNotificationType)n.type;
    this.valueId = n.valueId;
    this.buttonId = n.buttonId;
  }
}
struct ErrorNotification {
  ValueID valueId;
  ubyte notification;
  this(const ref Notification n) {
    this.valueId = n.valueId;
    this.notification = n.notification;
  }
}
enum BasicNotificationType {
                            ValueAdded = 0, /**< A new node value has been added to OpenZWave's list. These notifications occur after a node has been discovered, and details of its command classes have been received.  Each command class may generate one or more values depending on the complexity of the item being represented.  */
                            ValueRemoved, /**< A node value has been removed from OpenZWave's list.  This only occurs when a node is removed. */
                            ValueChanged, /**< A node value has been updated from the Z-Wave network and it is different from the previous value. */
                            ValueRefreshed, /**< A node value has been updated from the Z-Wave network. */
                            NodeNew = 5, /**< A new node has been found (not already stored in zwcfg*.xml file) */
                            NodeAdded, /**< A new node has been added to OpenZWave's list.  This may be due to a device being added to the Z-Wave network, or because the application is initializing itself. */
                            NodeRemoved, /**< A node has been removed from OpenZWave's list.  This may be due to a device being removed from the Z-Wave network, or because the application is closing. */
                            NodeProtocolInfo, /**< Basic node information has been received, such as whether the node is a listening device, a routing device and its baud rate and basic, generic and specific types. It is after this notification that you can call Manager::GetNodeType to obtain a label containing the device description. */
                            NodeNaming, /**< One of the node names has changed (name, manufacturer, product). */
                            PollingDisabled = 11, /**< Polling of a node has been successfully turned off by a call to Manager::DisablePoll */
                            PollingEnabled, /**< Polling of a node has been successfully turned on by a call to Manager::EnablePoll */
                            SceneEvent, /**< Scene Activation Set received (Depreciated in 1.8) */
                            DriverReady = 18, /**< A driver for a PC Z-Wave controller has been added and is ready to use.  The notification will contain the controller's Home ID, which is needed to call most of the Manager methods. */
                            DriverFailed, /**< Driver failed to load */
                            DriverReset, /**< All nodes and values for this driver have been removed.  This is sent instead of potentially hundreds of individual node and value notifications. */
                            EssentialNodeQueriesComplete, /**< The queries on a node that are essential to its operation have been completed. The node can now handle incoming messages. */
                            NodeQueriesComplete, /**< All the initialization queries on a node have been completed. */
                            AwakeNodesQueried, /**< All awake nodes have been queried, so client application can expected complete data for these nodes. */
                            AllNodesQueriedSomeDead, /**< All nodes have been queried but some dead nodes found. */
                            AllNodesQueried, /**< All nodes have been queried, so client application can expected complete data. */
                            DriverRemoved = 27, /**< The Driver is being removed. (either due to Error or by request) Do Not Call Any Driver Related Methods after receiving this call */
                            NodeReset = 29, /**< The Device has been reset and thus removed from the NodeList in OZW */
                            UserAlerts, /**< Warnings and Notifications Generated by the library that should be displayed to the user (eg, out of date config files) */
                            ManufacturerSpecificDBReady /**< The ManufacturerSpecific Database Is Ready */
}
struct BasicNotification {
  BasicNotificationType type;
  ValueID valueId;
  this(const ref Notification n) {
    this.type = cast(BasicNotificationType)n.type;
    this.valueId = n.valueId;
  }
}

auto getNodeType(Manager* manager, ref const ValueID value) {
  return cast(SpecificClass)((manager.GetNodeGeneric(value) << 8) | manager.GetNodeSpecific(value));
}

class Dispatcher {
  alias OnValueChanged = void delegate(ref const Node node, ref const Value value);
  alias OnValueRemoved = void delegate(ref const Node node, ref const Value value);
  alias OnNodeRemoved = void delegate(ref const Node node);
  alias OnNodeAdded = void delegate(ref const Node node);
  this() {
    this.manager = Manager.Create();
  }
  ~this() {
    Manager.Destroy();
  }
  auto listen(string port) {
    return runTask({
        add(new Logger());
        auto cInterface = ControllerInterface.Hid;
        auto stdport = stdstring(port);
        manager.AddDriver(stdport, cInterface);
        this.task = Task.getThis;
        logInfo("Start Listening");
        manager.AddWatcher(&onNotification, cast(void*)&task);
        import core.time;
        while(running) {
          receiveTimeout(msecs(10),&this.groupNotification,&this.basicNotification,&this.nodeEventNotification,&this.controllerNotification,&this.buttonNotification);
        }
        manager.RemoveWatcher(&onNotification, cast(void*)&task);
        logInfo("Stop listening");
      });
  }
  void stop() {
    running = false;
    this.task.join();
  }
  void add(T)(auto ref T t) @trusted {
    static if (hasMember!(T, "nodeAdded")) {
      nodeAdded ~= &t.nodeAdded;
      foreach(n; nodes.values)
        t.nodeAdded(n);
    }
    static if (hasMember!(T, "valueChanged")) {
      valueChanged ~= &t.valueChanged;
      foreach(v; values.values)
        t.valueChanged(nodes[v.getNodeIdentifier], v);
    }
    static if (hasMember!(T, "valueRemoved")) {
      valueRemoved ~= &t.valueRemoved;
    }
    static if (hasMember!(T, "nodeRemoved")) {
      nodeRemoved ~= &t.nodeRemoved;
    }
  }
  void remove(T)(auto ref T t) {
    import std.algorithm : remove, countUntil;
    static if (hasMember!(T, "valueChanged")) {
      valueChanged.remove(valueChanged.countUntil(&t.valueChanged));
    }
    static if (hasMember!(T, "valueRemoved")) {
      valueRemoved.remove(valueRemoved.countUntil(&t.valueRemoved));
    }
    static if (hasMember!(T, "nodeRemoved")) {
      nodeRemoved.remove(nodeRemoved.countUntil(&t.nodeRemoved));
    }
    static if (hasMember!(T, "nodeAdded")) {
      nodeAdded.remove(nodeAdded.countUntil(&t.nodeAdded));
    }
  }
private:
  bool running = true;
  Task task;
  extern(C++) static void onNotification(const Notification* notification, void* context) {
    auto task = (*cast(Task*)context);
    auto type = notification.type;
    auto val = notification.valueId;
    switch (type) {
    case NotificationType.Group:
      return task.tid.send(GroupNotification(*notification));
    case NotificationType.NodeEvent:
      return task.tid.send(NodeEventNotification(*notification));
    case NotificationType.ControllerCommand:
      return task.tid.send(ControllerNotification(*notification));
    case NotificationType.CreateButton:
    case NotificationType.DeleteButton:
    case NotificationType.ButtonOn:
    case NotificationType.ButtonOff:
      return task.tid.send(ButtonNotification(*notification));
    case NotificationType.Notification:
      return task.tid.send(ErrorNotification(*notification));
    default:
      return task.tid.send(BasicNotification(*notification));
    }
  }
  Manager* manager;
  Node[ulong] nodes;
  Value[ulong] values;
  OnValueChanged[] valueChanged;
  OnValueRemoved[] valueRemoved;
  OnNodeRemoved[] nodeRemoved;
  OnNodeAdded[] nodeAdded;
  void dispatch(alias list, Ts...)(Ts ts) {
    foreach(item; list)
      item(ts);
  }
  ulong getNodeIdentifier(ref BasicNotification event) {
    auto homeId = event.valueId.homeId;
    auto nodeId = event.valueId.nodeId;
    return (cast(ulong)homeId) << 32 | nodeId;
  }
  ulong getValueIdentifier(ref BasicNotification event) {
    auto nodeId = event.valueId.nodeId;
    auto clsId = event.valueId.commandClassId;
    auto instance = event.valueId.instance;
    auto index = event.valueId.index;
    return (cast(ulong)nodeId) << 32 | clsId << 24 | instance << 16 | index;
  }
  ValueContent getValueContent(ref BasicNotification event) {
    auto value = event.valueId;
    if (value.type == ValueType.Decimal) {
      float decimal;
      manager.GetValueAsFloat(value, &decimal);
      return ValueContent(decimal);
    } else if (value.type == ValueType.Byte) {
      ubyte b;
      manager.GetValueAsByte(value, &b);
      return ValueContent(b);
    } else if (value.type == ValueType.Bool) {
      bool b;
      manager.GetValueAsBool(value, &b);
      return ValueContent(b);
    } else if (value.type == ValueType.Int) {
      int i;
      manager.GetValueAsInt(value, &i);
      return ValueContent(i);
    } else if (value.type == ValueType.Short) {
      short s;
      manager.GetValueAsShort(value, &s);
      return ValueContent(s);
    } else
      return ValueContent(Unknown());
  }
  void groupNotification(GroupNotification event) {}
  void basicNotification(BasicNotification event) {
    with (BasicNotificationType) {
      switch (event.type) {
      case NodeAdded:
        auto manuId = manager.GetNodeManufacturerId(event.valueId.homeId, event.valueId.nodeId).c_str().fromStringz()[2..$].to!ushort(16);
        auto productId = manager.GetNodeProductId(event.valueId.homeId, event.valueId.nodeId).c_str().fromStringz()[2..$].to!ushort(16);
        auto product = manager.GetNodeProductName(event.valueId.homeId, event.valueId.nodeId).c_str().fromStringz().to!string;
        auto manufacturer = manager.GetNodeManufacturerName(event.valueId.homeId, event.valueId.nodeId).c_str().fromStringz().to!string;
        auto type = manager.getNodeType(event.valueId);
        ulong id = getNodeIdentifier(event);
        auto node = Node(manager.GetNodeBasic(event.valueId), type, type.getGenericClass, event.valueId.homeId, event.valueId.nodeId, manuId, productId, manufacturer, product, id);
        nodes[node.id] = node;
        dispatch!nodeAdded(node);
        return;
      case NodeRemoved:
        ulong id = getNodeIdentifier(event);
        auto node = nodes[id];
        dispatch!nodeRemoved(node);
        nodes.remove(id);
        return;
      case ValueAdded:
        auto valueId = event.valueId;
        auto label = manager.GetValueLabel(valueId).c_str().fromStringz.to!string;
        auto id = getValueIdentifier(event);
        auto value = Value(valueId.homeId, valueId.nodeId, label, cast(CommandClass)valueId.commandClassId, valueId.instance, valueId.instance, valueId.genre, valueId.type, getValueContent(event), id);
        values[value.id] = value;
        ulong nodeId = getNodeIdentifier(event);
        dispatch!valueChanged(nodes[nodeId], values[value.id]);
        return;
      case ValueChanged:
        ulong nodeId = getNodeIdentifier(event);
        auto valId = getValueIdentifier(event);
        values[valId].value = getValueContent(event);
        dispatch!valueChanged(nodes[nodeId], values[valId]);
        return;
      case ValueRemoved:
        ulong nodeId = getNodeIdentifier(event);
        auto valId = getValueIdentifier(event);
        dispatch!valueRemoved(nodes[nodeId], values[valId]);
        values.remove(valId);
        return;
      default:
        return;
      }
    }
  }
  void nodeEventNotification(NodeEventNotification event) {}
  void controllerNotification(ControllerNotification event) {}
  void buttonNotification(ButtonNotification event) {}
}

/* todo: get the dispatcher to emit nodes and values instead, add node/value cache and websockets */
struct Node {
  ubyte basic;
  SpecificClass specific;
  GenericClass generic;
  uint homeId;
  ubyte nodeId;
  ushort manufacturerId;
  ushort productId;
  string manufacturerName;
  string productName;
  ulong id;
}

struct Schedule {
  // empty for now
}

struct Button {
  // empty for now
}

struct BitSet {
  // empty for now
}

struct Unknown {
  // deliberatly empty
}

alias ValueContent = SumType!(bool, ubyte, float, int, string[], Schedule, short, string, Button, ubyte[], BitSet, Unknown);

struct Value {
  uint homeId;
  ubyte nodeId;
  string label;
  CommandClass commandClass;
  ubyte instance;
  ushort index;
  ValueGenre genre;
  ValueType type;
  ValueContent value;
  ulong id;
  static Value fromJson(Json value) @safe {
    return Value();
  }
  Json toJson() const @safe {
    auto ret = Json.emptyObject;
    ret["homeId"] = homeId;
    ret["nodeId"] = nodeId;
    ret["label"] = label;
    ret["commandClass"] = commandClass;
    ret["instance"] = instance;
    ret["index"] = index;
    ret["genre"] = genre;
    ret["type"] = type;
    value.match!((val){ret["value"] = val;},(_){});
    ret["id"] = id;
    return ret;
  }
}

ulong getNodeIdentifier(ref Value val) {
  return ((cast(ulong)val.homeId) << 32) | val.nodeId;
}

class Logger {
  void nodeAdded(ref const Node node) {
    logInfo("Node added %s", node);
  }
  void valueChanged(ref const Node node, ref const Value value) {
    logInfo("value [%s:%s]: %s (%s:%s) = %s", value.homeId, value.id, value.label, value.genre, value.type, value.value);
  }
}

struct ThermostatMap {
  struct Node {
    float temperature;
    float setpoint;
    ubyte valve;
    ubyte battery;
  }
  Node[ubyte] nodes;
  void removeNode(ubyte nodeId) {
    nodes.remove(nodeId);
  }
  void setTemperature(ubyte nodeId, ValueContent value) {
    value.match!((float value){
        nodes.update(nodeId, {return Node(value, float.init, 0, 0);}, (ref Node n){n.temperature = value; return n;});
      },(_){throw new Exception("Expected float");});
  }
  void setSetpoint(ubyte nodeId, ValueContent value) {
    value.match!((float value){
        nodes.update(nodeId, {return Node(float.init, value, 0, 0);}, (ref Node n){n.setpoint = value; return n;});
      },(_){throw new Exception("Expected float");});
  }
  void setValve(ubyte nodeId, ValueContent value) {
    value.match!((ubyte value){
        nodes.update(nodeId, {return Node(float.init, float.init, value, 0);}, (ref Node n){n.valve = value; return n;});
      },(_){throw new Exception("Expected ubyte");});
  }
  void setBattery(ubyte nodeId, ValueContent value) {
    value.match!((ubyte value){
        nodes.update(nodeId, {return Node(float.init, float.init, 0, value);}, (ref Node n){n.battery = value; return n;});
      },(_){throw new Exception("Expected ubyte");});
  }
}

class ThermostatController {
  ThermostatMap state;
  void valueChanged(ref Node node, ref Value value) {
    if (node.specific == SpecificClass.GeneralThermostatV2) {
      updateThermostatInput(value);
    } /* else if is on/off thermostat */
  }
  void updateThermostatInput(ref Value value) {
    if (value.commandClass == CommandClass.ThermostatSetpoint && value.index == 1) {
      state.setSetpoint(value.nodeId, value.value);
      writeln(state);
    } else if (value.commandClass == CommandClass.SensorMultilevelV2 && value.index == 1) {
      state.setTemperature(value.nodeId, value.value);
      writeln(state);
    } else if (value.commandClass == CommandClass.SwitchMultilevelV2 && value.index == 0 && value.type == ValueType.Byte) {
      state.setValve(value.nodeId, value.value);
    } else if (value.commandClass == CommandClass.Battery && value.index == 0 && value.type == ValueType.Byte) {
      state.setBattery(value.nodeId, value.value);
    }
  }
}

void main() {
  auto configDir = stdstring("../open-zwave/config/");
  auto userDir = stdstring("./");
  auto emptyString = stdstring(" ");
  auto options = Options.Create(configDir, userDir, emptyString);
  auto logLevelStr = stdstring("SaveLogLevel");

  options.AddOptionInt(logLevelStr, openzwave.types.LogLevel.Error );
  stdstring val = stdstring(DefaultConstruct.value);
  auto configPathName = stdstring("ConfigPath");
  options.Lock();

  auto dispatcher = new Dispatcher();
  dispatcher.listen("/dev/ttyACM0");
  auto router = new URLRouter();
  auto webSockets = WebSocketManager((scope WebSocket socket) @safe {
      auto sender = SocketDispatcher(socket);
      try {
        dispatcher.add(sender);
        writeln("Socket opened");
        while(socket.waitForData()) {
          logInfo("Socket received: %s", socket.receiveText());
        }
      } catch (InterruptException e) {
        sender.close();
      }
      dispatcher.remove(sender);
      writeln("Socket ended");
    });

  router.get("/events", handleWebSockets(&webSockets.handle));

  auto settings = new HTTPServerSettings();
  settings.port = 8080;
  settings.bindAddresses = ["0.0.0.0"];

  auto listener = listenHTTP(settings, router);

  runEventLoop();

  webSockets.terminate();
  dispatcher.stop();
  listener.stopListening();
}

@safe:

struct WebSocketManager {
  private Task[] tasks;
  private void delegate(scope WebSocket socket) @safe handler;
  this(void delegate(scope WebSocket socket) @safe handler) {
    this.handler = handler;
  }
  auto handle(scope WebSocket socket) {
    try {
      tasks ~= Task.getThis;
      handler(socket);
    } catch (InterruptException e) {}
    tasks.remove(tasks.countUntil(Task.getThis));
  }
  auto terminate() {
    tasks.dup.each!((t){t.interrupt();t.join();});
  }
}

struct NodeAddedMessage {
  Node node;
  string message = "node-added";
}

struct ValueChanged {
  Value value;
  string message = "value-changed";
}

struct Shutdown {
  string message = "shutdown";
}

struct SocketDispatcher {
  WebSocket socket;
  this(WebSocket socket) {
    this.socket = socket;
  }
  void nodeAdded(ref const Node node) {
    socket.send(NodeAddedMessage(node).serializeToJsonString()).tryIt;
  }
  void valueChanged(ref const Node node, ref const Value value) {
    socket.send(ValueChanged(value).serializeToJsonString()).tryIt;
  }
  void close() {
    socket.send(Shutdown().serializeToJsonString()).tryIt;
    socket.close();
  }
}

auto tryIt(Block)(lazy Block b) {
  try {
    b();
  } catch (Exception e) {}
}
