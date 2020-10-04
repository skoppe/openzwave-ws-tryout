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
import vibe.http.fileserver;
import vibe.data.json;
import std.algorithm;
import core.stdcpp.string;
import std.traits : hasMember;
import std.concurrency;
import std.string;
import types;
import connector;

class Logger {
  void nodeAdded(ref const Node node) {
    logInfo("Node added %s", node);
  }
  void nodeUpdated(ref const Node node) {
    logInfo("Node updated %s", node);
  }
  void valueAdded(ref const Node node, ref const Value value) {
    logInfo("value added [%s] [%s:%s:%s:%s:%s]: %s (%s:%s) = %s", value.id, value.homeId, value.nodeId, value.index, value.commandClass, value.instance, value.label, value.genre, value.type, value.value);
  }
  void valueChanged(ref const Node node, ref const Value value) {
    logInfo("value changed [%s] [%s:%s:%s:%s:%s]: %s (%s:%s) = %s", value.id, value.homeId, value.nodeId, value.index, value.commandClass, value.instance, value.label, value.genre, value.type, value.value);
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

  options.AddOptionInt(logLevelStr, openzwave.types.LogLevel.Alert );
  stdstring val = stdstring(DefaultConstruct.value);
  auto configPathName = stdstring("ConfigPath");
  options.Lock();

  auto connector = new Connector();
  connector.listen("/dev/ttyACM0");
  connector.add(new Logger());
  auto router = new URLRouter();
  auto webSockets = WebSocketManager((scope WebSocket socket) @trusted {
      auto sender = SocketDispatcher(socket);
      try {
        connector.add(sender);
        logInfo("Socket opened %s", socket);
        while(socket.waitForData()) {
          try {
            Json msg = socket.receiveText().parseJsonString();
            auto valId = msg["id"].get!string.to!ulong;
            logInfo(" received: %s", msg);
            logInfo(" valid : %s", valId);
            connector.updateValue(valId, msg["value"]);
          } catch (Exception e) {}
        }
      } catch (InterruptException e) {
        sender.close();
      }
      connector.remove(sender);
      logInfo("Socket ended %s", socket);
    });

  auto fileSettings = new HTTPFileServerSettings();
  fileSettings.preWriteCallback = (scope HTTPServerRequest req, scope HTTPServerResponse res, ref string path) {

                                                                                                            if (path.canFind(".wasm")) {
                                                                                                                                        res.headers["content-type"] = "application/wasm";
                                                                                                            }
  };
  router.get("/events", handleWebSockets(&webSockets.handle));
  router.get("*", serveStaticFiles("public/", fileSettings));

  auto settings = new HTTPServerSettings();
  settings.port = 8080;
  settings.bindAddresses = ["0.0.0.0"];

  auto listener = listenHTTP(settings, router);

  runEventLoop();

  webSockets.terminate();
  connector.stop();
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

struct ValueAdded {
  Value value;
  string message = "value-added";
}

struct ValueChanged {
  Value value;
  string message = "value-changed";
}

struct NodeUpdated {
  Node node;
  string message = "node-updated";
}

struct Shutdown {
  string message = "shutdown";
}

struct SocketDispatcher {
  WebSocket socket;
  this(WebSocket socket) {
    this.socket = socket;
  }
  void nodeAdded(ref const Node node) @trusted {
    socket.send(NodeAddedMessage(node).serializeToJsonString()).tryIt;
  }
  void nodeUpdated(ref const Node node) @trusted {
    socket.send(NodeUpdated(node).serializeToJsonString()).tryIt;
  }
  void valueAdded(ref const Node node, ref const Value value)@trusted  {
    socket.send(ValueAdded(value).serializeToJsonString()).tryIt;
  }
  void valueChanged(ref const Node node, ref const Value value) @trusted {
    socket.send(ValueChanged(value).serializeToJsonString()).tryIt;
  }
  void close() @trusted {
    logInfo("Closing %s", socket);
    socket.send(Shutdown().serializeToJsonString()).tryIt;
    socket.close();
    logInfo("Closed!");
  }
}

auto tryIt(Block)(lazy Block b) {
  try {
    b();
  } catch (Exception e) {}
}
