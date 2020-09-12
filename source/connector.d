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
    with (BasicNotificationType) {
      switch (event.type) {
      case NodeAdded:
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
        dispatcher.onNodeAdded(node);
        return;
      case NodeRemoved:
        ulong id = getNodeIdentifier(event.valueId);
        auto node = dispatcher.nodes[id];
        dispatcher.onNodeRemoved(node);
        return;
      case ValueAdded:
        auto valueId = event.valueId;
        auto label = manager.GetValueLabel(valueId).c_str().fromStringz.to!string;
        auto id = getValueIdentifier(event);
        // store time with Value, update time with when updateValue is called, then when ValueChanged is received in less than 5 sec. and value != value in list, updateValue again
        auto value = Value(valueId.homeId, valueId.nodeId, label, cast(CommandClass)valueId.commandClassId, valueId.instance, valueId.index, valueId.genre, valueId.type, getValueContent(event), manager.IsValueReadOnly(valueId), id);
        dispatcher.onValueAdded(value);
        return;
      case ValueChanged:
        auto valId = getValueIdentifier(event);
        auto content = getValueContent(event);
        auto value = dispatcher.values[valId];
        value.value = content;
        dispatcher.onValueChanged(value);
        return;
      case ValueRemoved:
        auto valId = getValueIdentifier(event);
        dispatcher.onValueRemoved(dispatcher.values[valId]);
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

auto toDString(ref const stdstring str) {
  auto ptr = str.c_str();
  if (ptr is null) {
    logInfo("String is null");
    return "";
  }
  return ptr.fromStringz().to!string;
}
