import openzwave.types;
import openzwave.valueid;
import openzwave.manager;
import sumtype;
import vibe.data.json;
import vibe.core.log;

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

struct List {
  string value;
  string[] options;
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

alias ValueContent = SumType!(bool, ubyte, float, int, List, Schedule, short, string, Button, ubyte[], BitSet, Unknown);

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
  bool readonly;
  ulong id;
  auto toValueID() {
    logInfo("Value = %s", this);
    return ValueID(homeId, nodeId, genre, cast(ubyte)commandClass, instance, index, type);
  }
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
    ret["readonly"] = readonly;
    value.match!((val){ret["value"] = val;},(_){});
    ret["id"] = id;
    return ret;
  }
}

ulong getNodeIdentifier(const ref Value val) {
  return ((cast(ulong)val.homeId) << 32) | val.nodeId;
}

ulong getNodeIdentifier(const ref ValueID val) {
  return ((cast(ulong)val.homeId) << 32) | val.nodeId;
}

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
