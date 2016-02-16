module netload.protocols.icmp.common;

import netload.core.protocol;
import netload.core.conversion.json_array;
import stdx.data.json;
import std.bitmanip;
import std.conv;
import std.outbuffer;
import std.range;
import std.array;

enum ICMPType {
  ANY,
  NONE,
  ECHO_REQUEST,
  ECHO_REPLY,
  INFORMATION_REQUEST,
  INFORMATION_REPLY,
  TIMESTAMP_REQUEST,
  TIMESTAMP_REPLY,
  DEST_UNREACH,
  TIME_EXCEED,
  SOURCE_QUENCH,
  REDIRECT,
  PARAM_PROBLEM,
  ADVERT,
  SOLLICITATION
};

alias ICMP = ICMPBase!(ICMPType.ANY);

/++
 + The Internet Control Message Protocol (ICMP) is one of the main protocols
 + of the Internet Protocol Suite. It is used by network devices, like routers,
 + to send error messages indicating, for example, that a requested service is
 + not available or that a host or router could not be reached.
 + ICMP can also be used to relay query messages.
 + It is assigned protocol number 1. ICMP differs from transport protocols
 + such as TCP and UDP in that it is not typically used to exchange data
 + between systems, nor is it regularly employed by end-user network
 + applications (with the exception of some diagnostic tools like ping
 + and traceroute).
 +/
class ICMPBase(ICMPType __type__) : Protocol {
  public:
    static ICMPBase!(__type__) opCall(inout JSONValue val) {
  		return new ICMPBase!(__type__)(val);
  	}

    this() {}

    this(ubyte type, ubyte code) {
      _type = type;
      _code = code;
    }

    this(JSONValue json) {
      _type = 0;
      if ("packetType" in json)
        _type = json["packetType"].to!ubyte;
      _code = 0;
      if ("code" in json)
        _code = json["code"].to!ubyte;
      _checksum = 0;
      if ("checksum" in json)
        _checksum = json["checksum"].to!ushort;
      if ("data" in json && json["data"] != null)
  			data = netload.protocols.conversion.protocolConversion[json["data"]["name"].get!string](json["data"]);
    }

    this(ref ubyte[] encodedPacket) {
      _type = encodedPacket.read!ubyte();
      _code = encodedPacket.read!ubyte();
      _checksum = encodedPacket.read!ushort();
    }

    override @property inout string name() { return "ICMP"; };
    override @property Protocol data() { return _data; }
    override @property void data(Protocol p) { _data = p; }
    override @property int osiLayer() const { return 3; }

    override JSONValue toJson() const {
      JSONValue json = [
        "packetType": JSONValue(_type),
        "code": JSONValue(_code),
        "checksum": JSONValue(_checksum),
        "name": JSONValue(name)
      ];
      if (_data is null)
  			json["data"] = JSONValue(null);
  		else
  			json["data"] = _data.toJson;
  		return json;
    }

    ///
    unittest {
      ICMP packet = new ICMP(3, 2);
      assert(packet.toJson["packetType"] == 3);
      assert(packet.toJson["code"] == 2);
      assert(packet.toJson["checksum"] == 0);
    }

    ///
    unittest {
      import netload.protocols.raw;

      ICMP packet = new ICMP(3, 2);

      packet.data = new Raw([42, 21, 84]);

      JSONValue json = packet.toJson;
      assert(json["name"] == "ICMP");
      assert(json["packetType"] == 3);
      assert(json["code"] == 2);
      assert(json["checksum"] == 0);

      json = json["data"];
  		assert(json["bytes"].toArrayOf!ubyte == [42, 21, 84]);
    }

    override ubyte[] toBytes() const {
      ubyte[] packet = new ubyte[4];
      packet.write!ubyte(_type, 0);
      packet.write!ubyte(_code, 1);
      packet.write!ushort(_checksum, 2);
      if (_data !is null)
        packet ~= _data.toBytes;
      return packet;
    }

    ///
    unittest {
      ICMP packet = new ICMP(3, 2);
      assert(packet.toBytes == [3, 2, 0, 0]);
    }

    ///
    unittest {
      import netload.protocols.raw;

      ICMP packet = new ICMP(3, 2);

      packet.data = new Raw([42, 21, 84]);

      assert(packet.toBytes == [3, 2, 0, 0] ~ [42, 21, 84]);
    }

    override string toIndentedString(uint idt = 0) const {
  		OutBuffer buf = new OutBuffer();
  		string indent = join(repeat("\t", idt));
  		buf.writef("%s%s%s%s\n", indent, PROTOCOL_NAME, name, RESET_SEQ);
      buf.writef("%s%s%s%s : %s%s%s\n", indent, FIELD_NAME, "packetType", RESET_SEQ, FIELD_VALUE, _type, RESET_SEQ);
      buf.writef("%s%s%s%s : %s%s%s\n", indent, FIELD_NAME, "code", RESET_SEQ, FIELD_VALUE, _code, RESET_SEQ);
      buf.writef("%s%s%s%s : %s%s%s\n", indent, FIELD_NAME, "checksum", RESET_SEQ, FIELD_VALUE, _checksum, RESET_SEQ);
      if (_data is null)
  			buf.writef("%s%s%s%s : %s%s%s\n", indent, FIELD_NAME, "data", RESET_SEQ, FIELD_VALUE, _data, RESET_SEQ);
  		else
  			buf.writef("%s", _data.toIndentedString(idt + 1));
      return buf.toString;
    }

    override string toString() const {
      return toIndentedString;
    }

    @property {
      /++
       + Indicates the type of the packet.
       +/
      inout ushort checksum() { return _checksum; }
      ///ditto
      void checksum(ushort checksum) { _checksum = checksum; }
      static if (__type__ == ICMPType.ANY) {
        /++
         + Indicates the type of the packet.
         +/
        inout ubyte type() { return _type; }
        ///ditto
        void type(ubyte type) { _type = type; }
        /++
         + In case of an error, it indicates what problem happened.
         +/
        inout ubyte code() { return _code; }
        ///ditto
        void code(ubyte code) { _code = code; }
      }
    }

  protected:
    Protocol _data = null;
    ubyte _type = 0;
    ubyte _code = 0;
    ushort _checksum = 0;
}

///
unittest {
  JSONValue json = [
    "packetType": JSONValue(3),
    "code": JSONValue(2),
    "checksum": JSONValue(0)
  ];
  ICMP packet = cast(ICMP)to!ICMP(json);
  assert(packet.type == 3);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

///
unittest  {
  import netload.protocols.raw;

  JSONValue json = [
    "name": JSONValue("ICMP"),
    "packetType": JSONValue(3),
    "code": JSONValue(2),
    "checksum": JSONValue(0)
  ];

  json["data"] = JSONValue([
		"name": JSONValue("Raw"),
		"bytes": ((cast(ubyte[])([42,21,84])).toJsonArray)
	]);

  ICMP packet = cast(ICMP)to!ICMP(json);
  assert(packet.type == 3);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
  assert((cast(Raw)packet.data).bytes == [42,21,84]);
}

///
unittest {
  ubyte[] encodedPacket = [3, 2, 0, 0];
  ICMP packet = cast(ICMP)encodedPacket.to!ICMP;
  assert(packet.type == 3);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}
