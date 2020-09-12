module openzwave.options;

import openzwave.types;

extern extern (C++, "OpenZWave") {
  extern(C++, class) struct Options {
    pragma(mangle, "_ZN9OpenZWave7Options6CreateERKSsS2_S2_")
    static Options* Create(ref const stdstring _configPath, ref const stdstring _userPath, ref const stdstring _commandLine);
    static Options* Get();
    bool Lock();
    pragma(mangle, "_ZN9OpenZWave7Options12AddOptionIntERKSsi")
    bool AddOptionInt(const ref stdstring _name, int _default);
    bool AddOptionBool(const ref stdstring _name, bool _default);
    pragma(mangle, "_ZN9OpenZWave7Options15AddOptionStringERKSsS2_b")
    bool AddOptionString(const ref stdstring _name, const ref stdstring _default, bool _append);
    pragma(mangle, "_ZN9OpenZWave7Options17GetOptionAsStringERKSsPSs")
    bool GetOptionAsString(const ref stdstring _name, stdstring* o_value);
  }
}
