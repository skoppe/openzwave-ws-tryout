module openzwave.types;

// alias stdstring = basic_string!char;
import core.stdcpp.string;

// Rep* dlang_empty_rep_storage;

pragma(mangle, "_ZNSs4_Rep12_S_empty_repEv")
extern void* empty_rep();

alias Rep = __traits(getMember, basic_string!(char), "_Rep");

shared static this() {
  // dlang_empty_rep_storage = cast(Rep*)(Rep._S_empty_rep_storage.ptr);
}
struct stdstring {
  basic_string!char _base;
  alias _base this;
  this(DefaultConstruct) {
    _base = basic_string!(char)(DefaultConstruct.value);
  }
  this(const(char)[] str) {
    _base = basic_string!char(str);
  }
  ~this() {
    import std.stdio;

    const rep = &(cast(Rep*)__traits(getMember, _base, "_M_data"))[-1];
    // import std.stdio;
    // writeln(cast(void*)rep, " == ", empty_rep(), " >= ", dlang_empty_rep_storage);
    if (rep == empty_rep()) {
      __traits(getMember, _base, "_M_data") = Rep._S_empty_rep()._M_refdata();//dlang_empty_rep_storage._M_refdata;
    }
  }
  static stdstring def() {
    return stdstring(DefaultConstruct.value);
  }
}

enum NotificationType {
  ValueAdded = 0, /**< A new node value has been added to OpenZWave's list. These notifications occur after a node has been discovered, and details of its command classes have been received.  Each command class may generate one or more values depending on the complexity of the item being represented.  */
  ValueRemoved, /**< A node value has been removed from OpenZWave's list.  This only occurs when a node is removed. */
  ValueChanged, /**< A node value has been updated from the Z-Wave network and it is different from the previous value. */
  ValueRefreshed, /**< A node value has been updated from the Z-Wave network. */
  Group, /**< The associations for the node have changed. The application should rebuild any group information it holds about the node. */
  NodeNew, /**< A new node has been found (not already stored in zwcfg*.xml file) */
  NodeAdded, /**< A new node has been added to OpenZWave's list.  This may be due to a device being added to the Z-Wave network, or because the application is initializing itself. */
  NodeRemoved, /**< A node has been removed from OpenZWave's list.  This may be due to a device being removed from the Z-Wave network, or because the application is closing. */
  NodeProtocolInfo, /**< Basic node information has been received, such as whether the node is a listening device, a routing device and its baud rate and basic, generic and specific types. It is after this notification that you can call Manager::GetNodeType to obtain a label containing the device description. */
  NodeNaming, /**< One of the node names has changed (name, manufacturer, product). */
  NodeEvent, /**< A node has triggered an event.  This is commonly caused when a node sends a Basic_Set command to the controller.  The event value is stored in the notification. */
  PollingDisabled, /**< Polling of a node has been successfully turned off by a call to Manager::DisablePoll */
  PollingEnabled, /**< Polling of a node has been successfully turned on by a call to Manager::EnablePoll */
  SceneEvent, /**< Scene Activation Set received (Depreciated in 1.8) */
  CreateButton, /**< Handheld controller button event created */
  DeleteButton, /**< Handheld controller button event deleted */
  ButtonOn, /**< Handheld controller button on pressed event */
  ButtonOff, /**< Handheld controller button off pressed event */
  DriverReady, /**< A driver for a PC Z-Wave controller has been added and is ready to use.  The notification will contain the controller's Home ID, which is needed to call most of the Manager methods. */
  DriverFailed, /**< Driver failed to load */
  DriverReset, /**< All nodes and values for this driver have been removed.  This is sent instead of potentially hundreds of individual node and value notifications. */
  EssentialNodeQueriesComplete, /**< The queries on a node that are essential to its operation have been completed. The node can now handle incoming messages. */
  NodeQueriesComplete, /**< All the initialization queries on a node have been completed. */
  AwakeNodesQueried, /**< All awake nodes have been queried, so client application can expected complete data for these nodes. */
  AllNodesQueriedSomeDead, /**< All nodes have been queried but some dead nodes found. */
  AllNodesQueried, /**< All nodes have been queried, so client application can expected complete data. */
  Notification, /**< An error has occurred that we need to report. */
  DriverRemoved, /**< The Driver is being removed. (either due to Error or by request) Do Not Call Any Driver Related Methods after receiving this call */
  ControllerCommand, /**< When Controller Commands are executed, Notifications of Success/Failure etc are communicated via this Notification
                           * Notification::GetEvent returns Driver::ControllerCommand and Notification::GetNotification returns Driver::ControllerState */
  NodeReset, /**< The Device has been reset and thus removed from the NodeList in OZW */
  UserAlerts, /**< Warnings and Notifications Generated by the library that should be displayed to the user (eg, out of date config files) */
  ManufacturerSpecificDBReady /**< The ManufacturerSpecific Database Is Ready */
}

enum NotificationCode {
  Code_MsgComplete = 0, /**< Completed messages */
  Code_Timeout, /**< Messages that timeout will send a Notification with this code. */
  Code_NoOperation, /**< Report on NoOperation message sent completion  */
  Code_Awake, /**< Report when a sleeping node wakes up */
  Code_Sleep, /**< Report when a node goes to sleep */
  Code_Dead, /**< Report when a node is presumed dead */
  Code_Alive /**< Report when a node is revived */
}

enum UserAlertNotification {
  Alert_None, /**< No Alert Currently Present */
  Alert_ConfigOutOfDate, /**< One of the Config Files is out of date. Use GetNodeId to determine which node is effected. */
  Alert_MFSOutOfDate, /**< the manufacturer_specific.xml file is out of date. */
  Alert_ConfigFileDownloadFailed, /**< A Config File failed to download */
  Alert_DNSError, /**< A error occurred performing a DNS Lookup */
  Alert_NodeReloadRequired, /**< A new Config file has been discovered for this node, and its pending a Reload to Take affect */
  Alert_UnsupportedController, /**< The Controller is not running a Firmware Library we support */
  Alert_ApplicationStatus_Retry, /**< Application Status CC returned a Retry Later Message */
  Alert_ApplicationStatus_Queued, /**< Command Has been Queued for later execution */
  Alert_ApplicationStatus_Rejected, /**< Command has been rejected */
}

enum ControllerInterface {
  Unknown = 0,
  Serial,
  Hid
}

enum LogLevel {
               Invalid, /**< Invalid Log Status */
               None, /**< Disable all logging */
               Always, /**< These messages should always be shown */
               Fatal, /**< A likely fatal issue in the library */
               Error, /**< A serious issue with the library or the network */
               Warning, /**< A minor issue from which the library should be able to recover */
               Alert, /**< Something unexpected by the library about which the controlling application should be aware */
               Info, /**< Everything is working fine...these messages provide streamlined feedback on each message */
               Detail, /**< Detailed information on the progress of each message */
               Debug, /**< Very detailed information on progress that will create a huge log file quickly
                         But this level (as others) can be queued and sent to the log only on an error or warning */
               StreamDetail, /**< Will include low-level byte transfers from controller to buffer to application and back */
               Internal /**< Used only within the log class (uses existing timestamp, etc.) */
};

enum GenericClass : ubyte {
                   RemoteController = 0x01,
                   StaticController = 0x02,
                   AVControlPoint = 0x03,
                   Display,
                   NetworkExtender,
                   Appliance,
                   NotificationSensor,
                   Thermostat,
                   WindowCovering,
                   RepeaterSlave = 0x0f,
                   BinarySwitch,
                   MultilevelSwitch,
                   RemoteSwitch,
                   ToggleSwitch,
                   ZIPGateway,
                   ZIPNode,
                   Ventilation,
                   SecurityPanel,
                   WallController,
                   BinarySensor = 0x20,
                   MultilevelSensor,
                   PulseMeter = 0x30,
                   Meter,
                   EntryControl = 0x40,
                   SemiInteroperable = 0x50,
                   AlarmSensor = 0xa1,
                   NonInteroperable = 0xff
}
auto getGenericClass(SpecificClass cls) {
  return cast(GenericClass)(cls >> 8);
}

enum CommandClass {
                   ThermostatSetpoint = 0x43,
                   SensorMultilevelV2 = 0x31,
                   SwitchMultilevelV2 = 0x26,
                   Battery  = 0x80
}

enum SpecificClass : ushort {
  PortableRemoteController = ( GenericClass.RemoteController << 8 ) + 1,
    PortableSceneController,
    PortableInstallerTool,
    RemoveControlAV,
    RemoveControlSimple,
    StaticPCController = ( GenericClass.StaticController << 8 ) + 1,
    StaticSceneController,
    StaticInstallerTool,
    SetTopBox,
    SubSystemControler,
    TV,
    Gateway,
    SoundSwitch = ( GenericClass.AVControlPoint << 8 ) + 1,
    SatelliteReceiver,
    SatelliteReceiverV2,
    Doorbell,
    SimpleDisplay = ( GenericClass.Display << 8 ) + 1,
    SecureExtender = ( GenericClass.NetworkExtender << 8 ) + 1,
    GeneralAppliance = ( GenericClass.Appliance << 8 ) + 1,
    KitchenAppliance,
    LaundryAppliance,
    NotificationSensor = ( GenericClass.NotificationSensor << 8 ) + 1,
    HeatingThermostat = ( GenericClass.Thermostat << 8 ) + 1,
    GeneralThermostat,
    SetbackScheduleThermostate,
    SetpointThermostat,
    SetbackThermostat,
    GeneralThermostatV2,
    SimpleWindowCovering = (GenericClass.WindowCovering << 8) + 1,
    BasicRepeaterSlave = (GenericClass.RepeaterSlave << 8) + 1,
    VirtualNode,
    BinaryPowerSwitch = (GenericClass.BinarySwitch << 8) + 1,
    BinaryTunableColorLight,
    BinarySceneSwitch,
    PowerStrip,
    Siren,
    ValveOpenClose,
    IrrigrationControl,
    MultilevelPowerSwitch = (GenericClass.MultilevelSwitch << 8) + 1,
    MultilevelTunableColorLight,
    MultipositionMotor,
    MultilevelSceneSwitch,
    MotorControlClassA,
    MotorControlClassB,
    MotorControlClassC,
    FanSwitch,
    BinaryRemoteSwitch = (GenericClass.RemoteSwitch << 8) + 1,
    MultilevelRemoteSwitch,
    BinaryToggleRemoteSwitch,
    MultilevelToggleRemoteSwitch,
    BinaryToggleSwitch = (GenericClass.ToggleSwitch << 8) + 1,
    MultilevelToggleSwitch,
    ZIPTunnelingGateway = (GenericClass.ZIPGateway << 8) + 1,
    ZIPAdvancedGateway,
    ZIPTunnelingNode = (GenericClass.ZIPNode << 8) + 1,
    ZIPAdvancedNode,
    ResidentialHeatRecoveryVentilation = (GenericClass.Ventilation << 8) + 1,
    ZonedSecurityPanel = (GenericClass.SecurityPanel << 8) + 1,
    BasicWallController = (GenericClass.WallController << 8) + 1,
    RoutingBinarySensor = (GenericClass.BinarySensor << 8) + 1,
    RoutingMultilevelSensor = (GenericClass.MultilevelSensor << 8) + 1,
    ChimneyFan,
    SimpleMeter = (GenericClass.Meter << 8) + 1,
    AdvancedEnergyControl,
    WholeHomeMeterSimple,
    DoorLock = (GenericClass.EntryControl << 8) + 1,
    AdvancedDoorLock,
    SecureKeypadDoorLock,
    SecureKeypadDoorLockDeadBolt,
    SecureDoor,
    SecureGate,
    SecureBarrierAddOn,
    SecureBarrierOpenOnly,
    SecureBarrierCloseOnly,
    SecureLockBox,
    SecureKeypad,
    EnergyProduction = ( GenericClass.SemiInteroperable << 8 ) + 1,
    BasicRoutingAlarmSensor = ( GenericClass.AlarmSensor << 8 ) + 1,
    RoutingAlarmSensor,
    BasicZensorAlarmSensor,
    ZensorAlarmSensor,
    AdvancedZensorAlarmSensor,
    BasicRoutingSmokeSensor,
    RoutingSmokeSensor,
    BasicZensorSmokeSensor,
    ZensorSmokeSensor,
    AdvancedZensorSmokeSensor,
    AlarmSensor
    }
