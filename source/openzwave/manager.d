module openzwave.manager;

import openzwave.valueid;
import openzwave.types;

alias pfnOnNotification_t = extern(C++) void function(const Notification*, void*);

extern extern (C++, "OpenZWave") {
  extern(C++, class) struct Notification {
    NotificationType type() const {
      return m_type;
    }
    inout ValueID valueId() {
      return m_valueId;
    }
    ubyte groupIdx() const {
      assert(m_type == NotificationType.Group);
      return m_byte;
    }
    ubyte event() const {
      assert(m_type == NotificationType.NodeEvent || m_type == NotificationType.ControllerCommand);
      return m_event;
    }
    ubyte buttonId() const {
      assert(NotificationType.CreateButton == m_type || NotificationType.DeleteButton == m_type || NotificationType.ButtonOn == m_type || NotificationType.ButtonOff == m_type);
      return m_byte;
    }
    ubyte notification() const {
      assert((NotificationType.Notification == m_type) || (NotificationType.ControllerCommand == m_type));
      return m_byte;
    }
    ubyte command() const {
      assert(NotificationType.ControllerCommand == m_type);
      return m_command;
    }
  private:
    NotificationType m_type;
    ValueID m_valueId;
    ubyte m_byte;
    ubyte m_event;
    ubyte m_command;
    UserAlertNotification m_useralerttype;
    stdstring m_comport;
  }
  extern(C++, class) struct Manager {
    static Manager* Create();
    static void Destroy();
    bool AddWatcher(pfnOnNotification_t _watcher, void* _context);
    bool RemoveWatcher(pfnOnNotification_t _watcher, void* _context);
    pragma(mangle, "_ZN9OpenZWave7Manager9AddDriverERKSsRKNS_6Driver19ControllerInterfaceE")
    bool AddDriver(ref const stdstring _controllerPath, const ref ControllerInterface _interface);
    /**
     * \brief Refresh a Node and Reload it into OZW
     * Causes the node's Supported CommandClasses and Capabilities to be obtained from the Z-Wave network
     * This method would normally be called automatically by OpenZWave, but if you know that a node's capabilities or command classes
     * has been changed, calling this method will force a refresh of that information.
     * This call shouldn't be needed except in special circumstances.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if the request was sent successfully.
     */
    bool refreshNodeInfo(uint _homeId, ubyte _nodeId);

    /**
     * \brief Trigger the fetching of dynamic value data for a node.
     * Causes the node's values to be requested from the Z-Wave network. This is the
     * same as the query state starting from the associations state.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if the request was sent successfully.
     */
    bool requestNodeState(uint _homeId, ubyte _nodeId);

    /**
     * \brief Trigger the fetching of just the dynamic value data for a node.
     * Causes the node's values to be requested from the Z-Wave network. This is the
     * same as the query state starting from the dynamic state.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if the request was sent successfully.
     */
    bool requestNodeDynamic(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get whether the node is a listening device that does not go to sleep
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if it is a listening node.
     */
    bool isNodeListeningDevice(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get whether the node is a frequent listening device that goes to sleep but
     * can be woken up by a beam. Useful to determine node and controller consistency.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if it is a frequent listening node.
     */
    bool isNodeFrequentListeningDevice(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get whether the node is a beam capable device.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if it is a beam capable node.
     */
    bool isNodeBeamingDevice(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get whether the node is a routing device that passes messages to other nodes
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if the node is a routing device
     */
    bool isNodeRoutingDevice(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the security attribute for a node. True if node supports security features.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return true if security features implemented.
     */
    bool isNodeSecurityDevice(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the maximum baud rate of a node's communications
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the baud rate in bits per second.
     */
    uint getNodeMaxBaudRate(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the version number of a node
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's version number
     */
    ubyte getNodeVersion(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the security byte of a node
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's security byte
     */
    ubyte getNodeSecurity(uint _homeId, ubyte _nodeId);

    /**
     * \brief Is this a ZWave+ Supported Node?
     * \param _homeId the HomeID of the Z-Wave controller that managed the node.
     * \param _nodeId the ID of the node to query.
     * \return If this node is a Z-Wave Plus Node
     */

    bool isNodeZWavePlus(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the basic type of a node.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's basic type.
     */
    ubyte GetNodeBasic(uint _homeId, ubyte _nodeId);
    ubyte GetNodeBasic(ref const ValueID val) {
      return GetNodeBasic(val.homeId, val.nodeId);
    }
    /**
     * \brief Get the generic type of a node.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's generic type.
     */
    ubyte GetNodeGeneric(uint _homeId, ubyte _nodeId);
    ubyte GetNodeGeneric(ref const ValueID val) {
      return GetNodeGeneric(val.homeId, val.nodeId);
    }

    /**
     * \brief Get the specific type of a node.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's specific type.
     */
    ubyte GetNodeSpecific(uint _homeId, ubyte _nodeId);
    ubyte GetNodeSpecific(ref const ValueID val) {
      return GetNodeSpecific(val.homeId, val.nodeId);
    }

    /**
     * \brief Get a human-readable label describing the node
     * The label is taken from the Z-Wave specific, generic or basic type, depending on which of those values are specified by the node.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the label text.
     */
    pragma(mangle, "_ZN9OpenZWave7Manager11GetNodeTypeEjh")
    stdstring GetNodeType(uint _homeId, ubyte _nodeId);
    stdstring GetNodeType(const ref ValueID val) {
      return GetNodeType(val.homeId, val.nodeId);
    }

    /**
     * \brief Get the bitmap of this node's neighbors
     *
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \param _nodeNeighbors An array of 29 ubytes to hold the neighbor bitmap
     * \sa SyncronizeNodeNeighbors
     */
    uint getNodeNeighbors(uint _homeId, ubyte _nodeId, ubyte** _nodeNeighbors);

    /**
     * \brief Update the List of Neighbors on a particular node
     *
     * This retrieves the latest copy of the Neighbor lists for a particular node and should be called
     * before calling GetNodeNeighbors to ensure OZW returns the most recent list of Neighbors
     *
     * \param _homeId The HomeID of the Z-Wave controller than manages the node.
     * \param _nodeId The ID of the node to get a updated list of Neighbors from
     * \sa GetNodeNeighbors
     */

    void syncronizeNodeNeighbors(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the manufacturer name of a device
     * The manufacturer name would normally be handled by the Manufacturer Specific command class,
     * taking the manufacturer ID reported by the device and using it to look up the name from the
     * manufacturer_specific.xml file in the OpenZWave config folder.
     * However, there are some devices that do not support the command class, so to enable the user
     * to manually set the name, it is stored with the node data and accessed via this method rather
     * than being reported via a command class Value object.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the node's manufacturer name.
     * \see SetNodeManufacturerName, GetNodeProductName, SetNodeProductName
     */
    stdstring GetNodeManufacturerName(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the product name of a device
     * The product name would normally be handled by the Manufacturer Specific command class,
     * taking the product Type and ID reported by the device and using it to look up the name from the
     * manufacturer_specific.xml file in the OpenZWave config folder.
     * However, there are some devices that do not support the command class, so to enable the user
     * to manually set the name, it is stored with the node data and accessed via this method rather
     * than being reported via a command class Value object.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the node's product name.
     * \see SetNodeProductName, GetNodeManufacturerName, SetNodeManufacturerName
     */
    stdstring GetNodeProductName(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the name of a node
     * The node name is a user-editable label for the node that would normally be handled by the
     * Node Naming command class, but many devices do not support it.  So that a node can always
     * be named, OpenZWave stores it with the node data, and provides access through this method
     * and SetNodeName, rather than reporting it via a command class Value object.
     * The maximum length of a node name is 16 characters.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the node's name.
     * \see SetNodeName, GetNodeLocation, SetNodeLocation
     */
    stdstring GetNodeName(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the location of a node
     * The node location is a user-editable stdstring that would normally be handled by the Node Naming
     * command class, but many devices do not support it.  So that a node can always report its
     * location, OpenZWave stores it with the node data, and provides access through this method
     * and SetNodeLocation, rather than reporting it via a command class Value object.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the node's location.
     * \see SetNodeLocation, GetNodeName, SetNodeName
     */
    stdstring GetNodeLocation(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the manufacturer ID of a device
     * The manufacturer ID is a four digit hex code and would normally be handled by the Manufacturer
     * Specific command class, but not all devices support it.  Although the value reported by this
     * method will be an empty stdstring if the command class is not supported and cannot be set by the
     * user, the manufacturer ID is still stored with the node data (rather than being reported via a
     * command class Value object) to retain a consistent approach with the other manufacturer specific data.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the node's manufacturer ID, or an empty stdstring if the manufacturer
     * specific command class is not supported by the device.
     * \see GetNodeProductType, GetNodeProductId, GetNodeManufacturerName, GetNodeProductName
     * \todo Change the return to ushort in 2.0 time frame
     */
    stdstring GetNodeManufacturerId(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the product type of a device
     * The product type is a four digit hex code and would normally be handled by the Manufacturer Specific
     * command class, but not all devices support it.  Although the value reported by this method will
     * be an empty stdstring if the command class is not supported and cannot be set by the user, the product
     * type is still stored with the node data (rather than being reported via a command class Value object)
     * to retain a consistent approach with the other manufacturer specific data.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the node's product type, or an empty stdstring if the manufacturer
     * specific command class is not supported by the device.
     * \see GetNodeManufacturerId, GetNodeProductId, GetNodeManufacturerName, GetNodeProductName
     * \todo Change the return to ushort in 2.0 time frame
     */
    stdstring getNodeProductType(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the product ID of a device
     * The product ID is a four digit hex code and would normally be handled by the Manufacturer Specific
     * command class, but not all devices support it.  Although the value reported by this method will
     * be an empty stdstring if the command class is not supported and cannot be set by the user, the product
     * ID is still stored with the node data (rather than being reported via a command class Value object)
     * to retain a consistent approach with the other manufacturer specific data.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return A stdstring containing the node's product ID, or an empty stdstring if the manufacturer
     * specific command class is not supported by the device.
     * \see GetNodeManufacturerId, GetNodeProductType, GetNodeManufacturerName, GetNodeProductName
     * \todo Change the return to ushort in 2.0 time frame
     */
    stdstring GetNodeProductId(uint _homeId, ubyte _nodeId);

    /**
     * \brief Set the manufacturer name of a device
     * The manufacturer name would normally be handled by the Manufacturer Specific command class,
     * taking the manufacturer ID reported by the device and using it to look up the name from the
     * manufacturer_specific.xml file in the OpenZWave config folder.
     * However, there are some devices that do not support the command class, so to enable the user
     * to manually set the name, it is stored with the node data and accessed via this method rather
     * than being reported via a command class Value object.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \param _manufacturerName	A stdstring containing the node's manufacturer name.
     * \see GetNodeManufacturerName, GetNodeProductName, SetNodeProductName
     */
    void setNodeManufacturerName(uint _homeId, ubyte _nodeId, ref const stdstring _manufacturerName);

    /**
     * \brief Set the product name of a device
     * The product name would normally be handled by the Manufacturer Specific command class,
     * taking the product Type and ID reported by the device and using it to look up the name from the
     * manufacturer_specific.xml file in the OpenZWave config folder.
     * However, there are some devices that do not support the command class, so to enable the user
     * to manually set the name, it is stored with the node data and accessed via this method rather
     * than being reported via a command class Value object.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \param _productName A stdstring containing the node's product name.
     * \see GetNodeProductName, GetNodeManufacturerName, SetNodeManufacturerName
     */
    void setNodeProductName(uint _homeId, ubyte _nodeId, ref const stdstring _productName);

    /**
     * \brief Set the name of a node
     * The node name is a user-editable label for the node that would normally be handled by the
     * Node Naming command class, but many devices do not support it.  So that a node can always
     * be named, OpenZWave stores it with the node data, and provides access through this method
     * and GetNodeName, rather than reporting it via a command class Value object.
     * If the device does support the Node Naming command class, the new name will be sent to the node.
     * The maximum length of a node name is 16 characters.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \param _nodeName A stdstring containing the node's name.
     * \see GetNodeName, GetNodeLocation, SetNodeLocation
     */
    void setNodeName(uint _homeId, ubyte _nodeId, ref const stdstring _nodeName);

    /**
     * \brief Set the location of a node
     * The node location is a user-editable stdstring that would normally be handled by the Node Naming
     * command class, but many devices do not support it.  So that a node can always report its
     * location, OpenZWave stores it with the node data, and provides access through this method
     * and GetNodeLocation, rather than reporting it via a command class Value object.
     * If the device does support the Node Naming command class, the new location will be sent to the node.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \param _location A stdstring containing the node's location.
     * \see GetNodeLocation, GetNodeName, SetNodeName
     */
    void setNodeLocation(uint _homeId, ubyte _nodeId, ref const stdstring _location);

    /**
     * \brief Turns a node on
     * This is a helper method to simplify basic control of a node.  It is the equivalent of
     * changing the level reported by the node's Basic command class to 255, and will generate a
     * ValueChanged notification from that class.  This command will turn on the device at its
     * last known level, if supported by the device, otherwise it will turn	it on at 100%.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to be changed.
     * \deprecated This method has been depreciated in setting the ValueID's directly (Remove in 1.8)
     *
     * \see SetNodeOff, SetNodeLevel
     */
    deprecated void setNodeOn(uint _homeId, ubyte _nodeId);

    /**
     * \brief Turns a node off
     * This is a helper method to simplify basic control of a node.  It is the equivalent of
     * changing the level reported by the node's Basic command class to zero, and will generate
     * a ValueChanged notification from that class.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to be changed.
     * \deprecated This method has been depreciated in setting the ValueID's directly (Remove in 1.8)
     * \see SetNodeOn, SetNodeLevel
     */
    deprecated void setNodeOff(uint _homeId, ubyte _nodeId);

    /**
     * \brief Sets the basic level of a node
     * This is a helper method to simplify basic control of a node.  It is the equivalent of
     * changing the value reported by the node's Basic command class and will generate a
     * ValueChanged notification from that class.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to be changed.
     * \param _level The level to set the node.  Valid values are 0-99 and 255.  Zero is off and
     * 99 is fully on.  255 will turn on the device at its last known level (if supported).
     * \deprecated This method has been depreciated in setting the ValueID's directly (Remove in 1.8)
     * \see SetNodeOn, SetNodeOff
     */
    deprecated void setNodeLevel(uint _homeId, ubyte _nodeId, ubyte _level);

    /**
     * \brief Get whether the node information has been received
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if the node information has been received yet
     */
    bool isNodeInfoReceived(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get whether the node has the defined class available or not
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \param _commandClassId Id of the class to test for
     * \return True if the node does have the class instantiated, will return name & version
     */
    bool getNodeClassInformation(uint _homeId, ubyte _nodeId, ubyte _commandClassId, stdstring *_className = null, ubyte *_classVersion = null);
    /**
     * \brief Get whether the node is awake or asleep
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if the node is awake
     */
    bool isNodeAwake(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get whether the node is working or has failed
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return True if the node has failed and is no longer part of the network
     */
    bool isNodeFailed(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get whether the node's query stage as a stdstring
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return name of current query stage as a stdstring.
     */
    stdstring getNodeQueryStage(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the node device type as reported in the Z-Wave+ Info report.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's DeviceType
     */
    ushort getNodeDeviceType(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the node device type as reported in the Z-Wave+ Info report.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's Device Type as a stdstring.
     */
    stdstring getNodeDeviceTypeString(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the node role as reported in the Z-Wave+ Info report.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's user icon.
     */
    ubyte getNodeRole(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the node role as reported in the Z-Wave+ Info report.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's role type as a stdstring
     */
    stdstring getNodeRoleString(uint _homeId, ubyte _nodeId);

    /**
     * \brief Get the node PlusType as reported in the Z-Wave+ Info report.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's PlusType
     */
    ubyte getNodePlusType(uint _homeId, ubyte _nodeId);
    /**
     * \brief Get the node PlusType as reported in the Z-Wave+ Info report.
     * \param _homeId The Home ID of the Z-Wave controller that manages the node.
     * \param _nodeId The ID of the node to query.
     * \return the node's PlusType as a stdstring
     */
    stdstring getNodePlusTypeString(uint _homeId, ubyte _nodeId);

    /**
     * \brief Gets the user-friendly label for the value.
     * \param _id The unique identifier of the value.
     * \param _pos the Bit To Get the Label for if its a BitSet ValueID
     * \return The value label.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    stdstring GetValueLabel(const ref ValueID _id, int _pos = -1);

    /**
     * \brief Sets the user-friendly label for the value.
     * \param _id The unique identifier of the value.
     * \param _pos the Bit To set the Label for if its a BitSet ValueID
     * \param _value The new value of the label.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    void SetValueLabel(const ref ValueID _id, ref const stdstring _value, int _pos = -1);

    /**
     * \brief Gets the units that the value is measured in.
     * \param _id The unique identifier of the value.
     * \return The value units.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    stdstring GetValueUnits(const ref ValueID _id);

    /**
     * \brief Sets the units that the value is measured in.
     * \param _id The unique identifier of the value.
     * \param _value The new value of the units.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    void SetValueUnits(const ref ValueID _id, ref const stdstring _value);

    /**
     * \brief Gets a help stdstring describing the value's purpose and usage.
     * \param _id The unique identifier of the value.
     * \param _pos Get the Help for associated Bits (Valid with ValueBitSet only)
     * \return The value help text.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    stdstring GetValueHelp(const ref ValueID _id, int _pos = -1);

    /**
     * \brief Sets a help stdstring describing the value's purpose and usage.
     * \param _id The unique identifier of the value.
     * \param _value The new value of the help text.
     * \param __pos Set the Help for a associated Bit (Valid with ValueBitSet Only)
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    void SetValueHelp(const ref ValueID _id, ref const stdstring _value, int _pos = -1);

    /**
     * \brief Gets the minimum that this value may contain.
     * \param _id The unique identifier of the value.
     * \return The value minimum.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    int GetValueMin(const ref ValueID _id);

    /**
     * \brief Gets the maximum that this value may contain.
     * \param _id The unique identifier of the value.
     * \return The value maximum.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    int GetValueMax(const ref ValueID _id);

    /**
     * \brief Test whether the value is read-only.
     * \param _id The unique identifier of the value.
     * \return true if the value cannot be changed by the user.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    bool IsValueReadOnly(const ref ValueID _id);

    /**
     * \brief Test whether the value is write-only.
     * \param _id The unique identifier of the value.
     * \return true if the value can only be written to and not read.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID
     */
    bool IsValueWriteOnly(const ref ValueID _id);

    /**
     * \brief Gets a the value of a Bit from a BitSet ValueID
     * \param _id The unique identifier of the value.
     * \param _pos the Bit you want to test for
     * \param o_value Pointer to a bool that will be filled with the value.
     * \return true if the value was obtained.  Returns false if the value is not a ValueID::ValueType_BitSet. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsBitSet(const ref ValueID _id, ubyte _pos, bool* o_value);

    /**
     * \brief Gets a value as a bool.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a bool that will be filled with the value.
     * \return true if the value was obtained.  Returns false if the value is not a ValueID::ValueType_Bool. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsBool(const ref ValueID _id, bool* o_value);

    /**
     * \brief Gets a value as an 8-bit unsigned integer.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a ubyte that will be filled with the value.
     * \return true if the value was obtained.  Returns false if the value is not a ValueID::ValueType_Byte. The type can be tested with a call to ValueID::GetType
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsByte(const ref ValueID _id, ubyte* o_value);

    /**
     * \brief Gets a value as a float.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a float that will be filled with the value.
     * \return true if the value was obtained.  Returns false if the value is not a ValueID::ValueType_Decimal. The type can be tested with a call to ValueID::GetType
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsFloat(const ref ValueID _id, float* o_value);

    /**
     * \brief Gets a value as a 32-bit signed integer.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to an int32 that will be filled with the value.
     * \return true if the value was obtained.  Returns false if the value is not a ValueID::ValueType_Int. The type can be tested with a call to ValueID::GetType
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsInt(const ref ValueID _id, int* o_value);

    /**
     * \brief Gets a value as a 16-bit signed integer.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to an int16 that will be filled with the value.
     * \return true if the value was obtained.  Returns false if the value is not a ValueID::ValueType_Short. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsString, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsShort(const ref ValueID _id, short* o_value);

    /**
     * \brief Gets a value as a string.
     * Creates a string representation of a value, regardless of type.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a string that will be filled with the value.
     * \return true if the value was obtained.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsString(const ref ValueID _id, stdstring* o_value);

    /**
     * \brief Gets a value as a collection of bytes.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a ubyte* that will be filled with the value. This return value will need to be freed as it was dynamically allocated.
     * \param o_length Pointer to a ubyte that will be fill with the data length.
     * \return true if the value was obtained. Returns false if the value is not a ValueID::ValueType_Raw. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueListSelection, GetValueListItems, GetValueAsRaw
     */
    bool GetValueAsRaw(const ref ValueID _id, ubyte** o_value, ubyte* o_length);

    /**
     * \brief Gets the selected item from a list (as a string).
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a string that will be filled with the selected item.
     * \return True if the value was obtained.  Returns false if the value is not a ValueID::ValueType_List. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListItems, GetValueAsRaw
     */
    bool GetValueListSelection(const ref ValueID _id, stdstring* o_value);

    /**
     * \brief Gets the selected item from a list (as an integer).
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to an integer that will be filled with the selected item.
     * \return True if the value was obtained.  Returns false if the value is not a ValueID::ValueType_List. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListItems, GetValueAsRaw
     */
    bool GetValueListSelection(const ref ValueID _id, int* o_value);

    /**
     * \brief Gets the list of items from a list value.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a vector of strings that will be filled with list items. The vector will be cleared before the items are added.
     * \return true if the list items were obtained.  Returns false if the value is not a ValueID::ValueType_List. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueAsRaw
     */
    // bool GetValueListItems(const ref ValueID _id, stdvector<stdstring>* o_value);

    /**
     * \brief Gets the list of values from a list value.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a vector of integers that will be filled with list items. The vector will be cleared before the items are added.
     * \return true if the list values were obtained.  Returns false if the value is not a ValueID::ValueType_List. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsFloat, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueAsRaw
     */
    // bool GetValueListValues(const ref ValueID _id, stdvector<int>* o_value);

    /**
     * \brief Gets a float value's precision.
     * \param _id The unique identifier of the value.
     * \param o_value Pointer to a ubyte that will be filled with the precision value.
     * \return true if the value was obtained.  Returns false if the value is not a ValueID::ValueType_Decimal. The type can be tested with a call to ValueID::GetType
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \see ValueID::GetType, GetValueAsBitSet, GetValueAsBool, GetValueAsByte, GetValueAsInt, GetValueAsShort, GetValueAsString, GetValueListSelection, GetValueListItems
     */
    bool GetValueFloatPrecision(const ref ValueID _id, ubyte* o_value);

    /**
     * \brief Sets the state of a bit in a BitSet ValueID.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the BitSet value.
     * \param _pos the Position of the Bit you want to Set
     * \param _value The new value of the Bitset at the _pos position.
     * \return true if the value was set.  Returns false if the value is not a ValueID::ValueType_Bool. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     *
     */
    bool SetValue(const ref ValueID _id, ubyte _pos, bool _value);

    /**
     * \brief Sets the state of a bool.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the bool value.
     * \param _value The new value of the bool.
     * \return true if the value was set.  Returns false if the value is not a ValueID::ValueType_Bool. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     *
     */
    bool SetValue(const ref ValueID _id, bool _value);

    /**
     * \brief Sets the value of a byte.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the byte value.
     * \param _value The new value of the byte.
     * \return true if the value was set.  Returns false if the value is not a ValueID::ValueType_Byte. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetValue(const ref ValueID _id, ubyte _value);

    /**
     * \brief Sets the value of a decimal.
     * It is usually better to handle decimal values using strings rather than floats, to avoid floating point accuracy issues.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the decimal value.
     * \param _value The new value of the decimal.
     * \return true if the value was set.  Returns false if the value is not a ValueID::ValueType_Decimal. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetValue(const ref ValueID _id, float _value);

    /**
     * \brief Sets the value of a 32-bit signed integer.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the integer value.
     * \param _value The new value of the integer.
     * \return true if the value was set.  Returns false if the value is not a ValueID::ValueType_Int. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetValue(const ref ValueID _id, int _value);

    /**
     * \brief Sets the value of a 16-bit signed integer.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the integer value.
     * \param _value The new value of the integer.
     * \return true if the value was set.  Returns false if the value is not a ValueID::ValueType_Short. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetValue(const ref ValueID _id, short _value);

    /**
     * \brief Sets the value of a collection of bytes.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the raw value.
     * \param _value The new collection of bytes.
     * \return true if the value was set.  Returns false if the value is not a ValueID::ValueType_Raw. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetValue(const ref ValueID _id, const(ubyte*) _value, ubyte _length);

    /**
     * \brief Sets the value from a string, regardless of type.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the integer value.
     * \param _value The new value of the string.
     * \return true if the value was set.  Returns false if the value could not be parsed into the correct type for the value.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetValue(const ref ValueID _id, const ref stdstring _value);

    /**
     * \brief Sets the selected item in a list.
     * Due to the possibility of a device being asleep, the command is assumed to succeed, and the value
     * held by the node is updated directly.  This will be reverted by a future status message from the device
     * if the Z-Wave message actually failed to get through.  Notification callbacks will be sent in both cases.
     * \param _id The unique identifier of the list value.
     * \param _selectedItem A string matching the new selected item in the list.
     * \return true if the value was set.  Returns false if the selection is not in the list, or if the value is not a ValueID::ValueType_List.
     * The type can be tested with a call to ValueID::GetType
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetValueListSelection(const ref ValueID _id, const ref stdstring _selectedItem);

    /**
     * \brief Refreshes the specified value from the Z-Wave network.
     * A call to this function causes the library to send a message to the network to retrieve the current value
     * of the specified ValueID (just like a poll, except only one-time, not recurring).
     * \param _id The unique identifier of the value to be refreshed.
     * \return true if the driver and node were found; false otherwise
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool RefreshValue(const ref ValueID _id);

    /**
     * \brief Sets a flag indicating whether value changes noted upon a refresh should be verified.  If so, the
     * library will immediately refresh the value a second time whenever a change is observed.  This helps to filter
     * out spurious data reported occasionally by some devices.
     * \param _id The unique identifier of the value whose changes should or should not be verified.
     * \param _verify if true, verify changes; if false, don't verify changes.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \sa Manager::GetChangeVerified
     */
    void SetChangeVerified(const ref ValueID _id, bool _verify);

    /**
     * \brief determine if value changes upon a refresh should be verified.  If so, the
     * library will immediately refresh the value a second time whenever a change is observed.  This helps to filter
     * out spurious data reported occasionally by some devices.
     * \param _id The unique identifier of the value whose changes should or should not be verified.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     * \sa Manager::SetChangeVerified
     */
    bool GetChangeVerified(const ref ValueID _id);

    /**
     * \brief Starts an activity in a device.
     * Since buttons are write-only values that do not report a state, no notification callbacks are sent.
     * \param _id The unique identifier of the integer value.
     * \return true if the activity was started.  Returns false if the value is not a ValueID::ValueType_Button. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool PressButton(const ref ValueID _id);

    /**
     * \brief Stops an activity in a device.
     * Since buttons are write-only values that do not report a state, no notification callbacks are sent.
     * \param _id The unique identifier of the integer value.
     * \return true if the activity was stopped.  Returns false if the value is not a ValueID::ValueType_Button. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool ReleaseButton(const ref ValueID _id);

    /**
     * \brief Sets the Valid BitMask for a BitSet ValueID
     * Sets a BitMask of Valid Bits for a BitSet ValueID
     * \param _id The unique identifier of the integer value.
     * \param _mask The Mask to set
     * \return true if the mask was applied.  Returns false if the value is not a ValueID::ValueType_BitSet or the Mask was invalid. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool SetBitMask(const ref ValueID _id, uint _mask);

    /**
     * \brief Gets the Valid BitMask for a BitSet ValueID
     * Gets a BitMask of Valid Bits for a BitSet ValueID
     * \param _id The unique identifier of the integer value.
     * \param o_mask The Mask to for the BitSet
     * \return true if the mask was retrieved.  Returns false if the value is not a ValueID::ValueType_BitSet or the Mask was invalid. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool GetBitMask(const ref ValueID _id, int* o_mask);

    /**
     * \brief Gets the size of a BitMask ValueID 
     * Gets the size of a BitMask ValueID - Either 1, 2 or 4
     * \param _id The unique identifier of the integer value.
     * \param o_size The Size of the BitSet
     * \return true if the size was retrieved.  Returns false if the value is not a ValueID::ValueType_BitSet or the Mask was invalid. The type can be tested with a call to ValueID::GetType.
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_VALUEID if the ValueID is invalid
     * \throws OZWException with Type OZWException::OZWEXCEPTION_CANNOT_CONVERT_VALUEID if the Actual Value is off a different type
     * \throws OZWException with Type OZWException::OZWEXCEPTION_INVALID_HOMEID if the Driver cannot be found
     */
    bool GetBitSetSize(const ref ValueID _id, ubyte* o_size);

    /**
     * \brief Test whether the ValueID is valid.
     * \param _id The unique identifier of the value.
     * \return true if the valueID is valid, otherwise false.
     * \see ValueID
     */
    bool IsValueValid(const ref ValueID _id);

  }
}
