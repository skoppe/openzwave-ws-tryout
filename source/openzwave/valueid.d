module openzwave.valueid;

enum ValueGenre {
                 Basic = 0, /**< The 'level' as controlled by basic commands.  Usually duplicated by another command class. */
                 User, /**< Basic values an ordinary user would be interested in. */
                 Config, /**< Device-specific configuration parameters.  These cannot be automatically discovered via Z-Wave, and are usually described in the user manual instead. */
                 System, /**< Values of significance only to users who understand the Z-Wave protocol */
                 Count /**< A count of the number of genres defined.  Not to be used as a genre itself. */
};

/** 
 * Value Types
 * The type of data represented by the value object.
 * \see GetType
 */
enum ValueType {
                Bool = 0, /**< Boolean, true or false */
                Byte, /**< 8-bit unsigned value */
                Decimal, /**< Represents a non-integer value as a string, to avoid floating point accuracy issues. */
                Int, /**< 32-bit signed value */
                List, /**< List from which one item can be selected */
                Schedule, /**< Complex type used with the Climate Control Schedule command class */
                Short, /**< 16-bit signed value */
                String, /**< Text string */
                Button, /**< A write-only value that is the equivalent of pressing a button to send a command to a device */
                Raw, /**< A collection of bytes */
                BitSet, /**< A collection of Bits */
                Max = BitSet /**< The highest-number type defined.  Not to be used as a type itself. */
};

extern extern (C++, "OpenZWave") {
  extern(C++, class) struct ValueID {
    uint homeId() const
    {
      return m_homeId;
    }
    ubyte nodeId() const
    {
      return (cast(ubyte) ((m_id & 0xff000000) >> 24));
    }
    ValueGenre genre() const
    {
      return (cast(ValueGenre) ((m_id & 0x00c00000) >> 22));
    }
    ubyte commandClassId() const
    {
      return (cast(ubyte) ((m_id & 0x003fc000) >> 14));
    }
    ubyte instance() const
    {
      return (cast(ubyte) (((m_id & 0xff0)) >> 4));
    }
    ushort index() const
    {
      return (cast(ushort) ((m_id1 & 0xFFFF0000) >> 16));
    }
    ValueType type() const
    {
      return (cast(ValueType) (m_id & 0x0000000f));
    }
  private:
    uint m_id;
    uint m_id1;
    uint m_homeId;
  }
}
