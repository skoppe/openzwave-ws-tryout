import dispatcher;
import types;
import openzwave.types;
import openzwave.manager;
import openzwave.valueid;
import vibe.core.core;
import vibe.data.json;
import vibe.core.log;
import std.concurrency;
import std.string;
import std.conv : to;
import core.stdcpp.string;

auto getNodeType(Manager* manager, ref const ValueID value) {
  return cast(SpecificClass)((manager.GetNodeGeneric(value) << 8) | manager.GetNodeSpecific(value));
}

class Connector {
  private Dispatcher dispatcher;
  this() {
    this.manager = Manager.Create();
    this.dispatcher = new Dispatcher();
  }
  ~this() {
    Manager.Destroy();
  }
  auto listen(string port) {
    return runTask({
        auto cInterface = ControllerInterface.Hid;
        auto stdport = stdstring(port);
        manager.AddDriver(stdport, cInterface);
        this.task = Task.getThis;
        logInfo("Start Listening");
        manager.AddWatcher(&onNotification, cast(void*)this);
        import core.time;
        while(running) {
          receiveTimeout(msecs(100),&this.groupNotification,&this.nodeEventNotification,&this.controllerNotification,&this.buttonNotification,&this.dispatcher.onNodeAdded,&this.dispatcher.onNodeUpdated,&this.dispatcher.onNodeRemoved,&this.dispatcher.onValueAdded,&this.dispatcher.onValueChanged,&this.dispatcher.onValueRemoved);
        }
        manager.RemoveWatcher(&onNotification, cast(void*)this);
        logInfo("Stop listening");
      });
  }
  void stop() {
    running = false;
    this.task.join();
  }
  void updateValue(ulong id, Json value) @trusted {
    if (auto p = id in dispatcher.values) {
      switch (p.type) {
      case ValueType.Bool:
        auto valueId = (*p).toValueID();
        logInfo("%s",valueId);
        manager.SetValue(valueId,value.get!bool);
      default:
      }
    }
  }
  void add(T)(auto ref T t) @trusted {
    dispatcher.add(t);
  }
  void remove(T)(auto ref T t) {
    dispatcher.remove(t);
  }
private:
  bool running = true;
  Task task;
  extern(C++) static void onNotification(const Notification* notification, void* context) {
    Connector self = cast(Connector)context;
    auto receiver = self.task.tid;
    auto type = notification.type;
    auto val = notification.valueId;
    switch (type) {
    case NotificationType.Group:
      return receiver.send(GroupNotification(*notification));
    case NotificationType.NodeEvent:
      return receiver.send(NodeEventNotification(*notification));
    case NotificationType.ControllerCommand:
      return receiver.send(ControllerNotification(*notification));
    case NotificationType.CreateButton:
    case NotificationType.DeleteButton:
    case NotificationType.ButtonOn:
    case NotificationType.ButtonOff:
      return receiver.send(ButtonNotification(*notification));
    case NotificationType.Notification:
      return receiver.send(ErrorNotification(*notification));
    default:
      return self.basicNotification(BasicNotification(*notification));
    }
  }
  Manager* manager;
  ulong getValueIdentifier(ref BasicNotification event) {
    auto nodeId = event.valueId.nodeId;
    auto clsId = event.valueId.commandClassId;
    auto instance = event.valueId.instance;
    auto index = event.valueId.index;
    return (cast(ulong)nodeId) << 32 | (cast(ulong)clsId) << 24 | (cast(ulong)instance) << 16 | index;
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
    } /*else if (value.type == ValueType.List) {
      stdstring str = Manager.getVersionAsString();
      logInfo(str.toDString());
      manager.GetValueListSelection(value, &str);
      string d = str.toDString();
      logInfo(d);
      return ValueContent(List(d,[]));
    } else if (value.type == ValueType.String) {
      // stdstring str = Manager.getVersionAsString();
      Manager.FakeString str;
      logInfo(manager.GetValueAsFakeString(value, &str));
      logInfo("%s", str);
      // string d = str.toDString();
      // logInfo(d);
      // return ValueContent(d);
      return ValueContent(Unknown());
      } */else
      return ValueContent(Unknown());
  }
  void groupNotification(GroupNotification event) {}
  void basicNotification(BasicNotification event) {
      switch (event.type) {
      case BasicNotificationType.NodeAdded:
        auto valueId = event.valueId;
        auto homeId = valueId.homeId;
        auto nodeId = valueId.nodeId;
        ushort manuId = manager.GetNodeManufacturerId(homeId, nodeId).c_str().fromStringz()[2..$].to!ushort(16);
        ushort productId = manager.GetNodeProductId(homeId, nodeId).c_str().fromStringz()[2..$].to!ushort(16);
        auto product = manager.GetNodeProductName(homeId, nodeId).c_str().fromStringz().to!string;
        auto manufacturer = manager.GetNodeManufacturerName(homeId, nodeId).c_str().fromStringz().to!string;
        auto type = manager.getNodeType(valueId);
        ulong id = getNodeIdentifier(valueId);
        auto node = Node(manager.GetNodeBasic(valueId), type, type.getGenericClass, homeId, nodeId, manuId, productId, manufacturer, product, id);
        task.tid.send(NodeAdded(node));
        return;
      // case NodeProtocolInfo:
      case BasicNotificationType.NodeQueriesComplete:
      case BasicNotificationType.NodeNaming:
        auto valueId = event.valueId;
        auto homeId = valueId.homeId;
        auto nodeId = valueId.nodeId;
        ushort manuId = manager.GetNodeManufacturerId(homeId, nodeId).c_str().fromStringz()[2..$].to!ushort(16);
        ushort productId = manager.GetNodeProductId(homeId, nodeId).c_str().fromStringz()[2..$].to!ushort(16);
        auto product = manager.GetNodeProductName(homeId, nodeId).c_str().fromStringz().to!string;
        auto manufacturer = manager.GetNodeManufacturerName(homeId, nodeId).c_str().fromStringz().to!string;
        auto type = manager.getNodeType(valueId);
        ulong id = getNodeIdentifier(valueId);
        auto node = Node(manager.GetNodeBasic(valueId), type, type.getGenericClass, homeId, nodeId, manuId, productId, manufacturer, product, id);
        task.tid.send(NodeUpdated(node));
        return;
      case BasicNotificationType.NodeRemoved:
        ulong id = getNodeIdentifier(event.valueId);
        task.tid.send(NodeRemoved(id));
        return;
      case BasicNotificationType.ValueAdded:
        auto valueId = event.valueId;
        auto label = manager.GetValueLabel(valueId).c_str().fromStringz.to!string;
        auto id = getValueIdentifier(event);
        auto value = Value(valueId.homeId, valueId.nodeId, label, cast(CommandClass)valueId.commandClassId, valueId.instance, valueId.index, valueId.genre, valueId.type, getValueContent(event), manager.IsValueReadOnly(valueId), id);
        task.tid.send(cast(immutable)ValueAdded(value));
        return;
      case BasicNotificationType.ValueChanged:
        auto valId = getValueIdentifier(event);
        auto content = getValueContent(event);
        task.tid.send(cast(immutable)ValueChanged(valId, content));
        return;
      case BasicNotificationType.ValueRemoved:
        auto valId = getValueIdentifier(event);
        task.tid.send(ValueRemoved(valId));
        return;
      default:
        return;
      }
  }
  void nodeEventNotification(NodeEventNotification event) {}
  void controllerNotification(ControllerNotification event) {}
  void buttonNotification(ButtonNotification event) {}
}

auto toDString(ref const stdstring str) {
  auto ptr = str.c_str();
  if (ptr is null) {
    logInfo("String is null");
    return "";
  }
  return ptr.fromStringz().to!string;
}
