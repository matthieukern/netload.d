module netload.protocols.icmp.v4.error;

import netload.core.protocol;
import netload.protocols.icmp.common;
import netload.protocols.ip;
import vibe.data.json;
import std.bitmanip;

class ICMPv4Error : ICMP {
  public:
    this() {}

    this(ubyte type, ubyte code = 0, IP data = null) {
      super(type, code);
      _data = data;
    }

    override ubyte[] toBytes() const {
      ubyte[] packet = super.toBytes();
      packet ~= [0, 0, 0, 0];
      // append previous IP header + 8 first bytes of previous payload
      return packet;
    }

    unittest {
      ICMPv4Error packet = new ICMPv4Error(3, 1, new IP());
      assert(packet.toBytes == [3, 1, 0, 0, 0, 0, 0, 0]);
    }
}

Protocol toICMPv4Error(Json json) {
  ICMPv4Error packet = new ICMPv4Error();
  packet.type = json.packetType.to!ubyte;
  packet.code = json.code.to!ubyte;
  packet.checksum = json.checksum.to!ushort;
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.packetType = 3;
  json.code = 2;
  json.checksum = 0;
  ICMPv4Error packet = cast(ICMPv4Error)toICMPv4Error(json);
  assert(packet.type == 3);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

Protocol toICMPv4Error(ubyte[] encodedPacket) {
  ICMPv4Error packet = new ICMPv4Error();
  packet.type = encodedPacket.read!ubyte();
  packet.code = encodedPacket.read!ubyte();
  packet.checksum = encodedPacket.read!ushort();
  encodedPacket.read!uint();
  return packet;
}

unittest {
  ubyte[] encodedPacket = [3, 2, 0, 0, 0, 0, 0, 0];
  ICMPv4Error packet = cast(ICMPv4Error)encodedPacket.toICMPv4Error;
  assert(packet.type == 3);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

class ICMPv4DestUnreach : ICMPv4Error {
  public:
    this() {
      super(3);
    }

    this(ubyte code, IP data) {
      super(3, code, data);
    }

    @disable @property {
      override void type(ubyte type) { _type = type; }
    }
}

Protocol toICMPv4DestUnreach(Json json) {
  ICMPv4DestUnreach packet = new ICMPv4DestUnreach();
  packet.code = json.code.to!ubyte;
  packet.checksum = json.checksum.to!ushort;
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.code = 2;
  json.checksum = 0;
  ICMPv4DestUnreach packet = cast(ICMPv4DestUnreach)toICMPv4DestUnreach(json);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

Protocol toICMPv4DestUnreach(ubyte[] encodedPacket) {
  ICMPv4DestUnreach packet = new ICMPv4DestUnreach();
  encodedPacket.read!ubyte();
  packet.code = encodedPacket.read!ubyte();
  packet.checksum = encodedPacket.read!ushort();
  encodedPacket.read!uint();
  return packet;
}

unittest {
  ubyte[] encodedPacket = [3, 2, 0, 0, 0, 0, 0, 0];
  ICMPv4DestUnreach packet = cast(ICMPv4DestUnreach)encodedPacket.toICMPv4DestUnreach;
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

class ICMPv4TimeExceed : ICMPv4Error {
  public:
    this() {
      super(11);
    }

    this(ubyte code, IP data) {
      super(11, code, data);
    }

    @disable @property {
      override void type(ubyte type) { _type = type; }
    }
}

Protocol toICMPv4TimeExceed(Json json) {
  ICMPv4TimeExceed packet = new ICMPv4TimeExceed();
  packet.code = json.code.to!ubyte;
  packet.checksum = json.checksum.to!ushort;
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.code = 2;
  json.checksum = 0;
  ICMPv4TimeExceed packet = cast(ICMPv4TimeExceed)toICMPv4TimeExceed(json);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

Protocol toICMPv4TimeExceed(ubyte[] encodedPacket) {
  ICMPv4TimeExceed packet = new ICMPv4TimeExceed();
  encodedPacket.read!ubyte();
  packet.code = encodedPacket.read!ubyte();
  packet.checksum = encodedPacket.read!ushort();
  encodedPacket.read!uint();
  return packet;
}

unittest {
  ubyte[] encodedPacket = [3, 2, 0, 0, 0, 0, 0, 0];
  ICMPv4TimeExceed packet = cast(ICMPv4TimeExceed)encodedPacket.toICMPv4TimeExceed;
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

class ICMPv4ParamProblem : ICMPv4Error {
  public:
    this() {
      super(12);
    }

    this(ubyte code, ubyte ptr, IP data) {
      super(12, code, data);
      _ptr = ptr;
    }

    override Json toJson() const {
      Json packet = super.toJson();
      packet.ptr = _ptr;
      return packet;
    }

    unittest {
      ICMPv4ParamProblem packet = new ICMPv4ParamProblem(2, 1, null);
      assert(packet.toJson.packetType == 12);
      assert(packet.toJson.code == 2);
      assert(packet.toJson.checksum == 0);
      assert(packet.toJson.ptr == 1);
    }

    override ubyte[] toBytes() const {
      ubyte[] packet = super.toBytes();
      packet.write!ubyte(_ptr, 4);
      return packet;
    }

    unittest {
      ICMPv4ParamProblem packet = new ICMPv4ParamProblem(2, 1, null);
      assert(packet.toBytes == [12, 2, 0, 0, 1, 0, 0, 0]);
    }

    @disable @property {
      override void type(ubyte type) { _type = type; }
    }

    @property {
      inout ubyte ptr() { return _ptr; }
      void ptr(ubyte ptr) { _ptr = ptr; }
    }

  private:
    ubyte _ptr = 0;
}

Protocol toICMPv4ParamProblem(Json json) {
  ICMPv4ParamProblem packet = new ICMPv4ParamProblem();
  packet.code = json.code.to!ubyte;
  packet.checksum = json.checksum.to!ushort;
  packet.ptr = json.ptr.to!ubyte;
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.code = 2;
  json.checksum = 0;
  json.ptr = 1;
  ICMPv4ParamProblem packet = cast(ICMPv4ParamProblem)toICMPv4ParamProblem(json);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
  assert(packet.ptr == 1);
}

Protocol toICMPv4ParamProblem(ubyte[] encodedPacket) {
  ICMPv4ParamProblem packet = new ICMPv4ParamProblem();
  encodedPacket.read!ubyte();
  packet.code = encodedPacket.read!ubyte();
  packet.checksum = encodedPacket.read!ushort();
  packet.ptr = encodedPacket.read!ubyte();
  encodedPacket.read!ubyte();
  encodedPacket.read!ushort();
  return packet;
}

unittest {
  ubyte[] encodedPacket = [3, 2, 0, 0, 1, 0, 0, 0];
  ICMPv4ParamProblem packet = cast(ICMPv4ParamProblem)encodedPacket.toICMPv4ParamProblem;
  assert(packet.code == 2);
  assert(packet.checksum == 0);
  assert(packet.ptr == 1);
}

class ICMPv4SourceQuench : ICMPv4Error {
  public:
    this() {
      super(4);
    }

    this(ubyte code, IP data) {
      super(4, code, data);
    }

    @disable @property {
      override void type(ubyte type) { _type = type; }
    }
}

Protocol toICMPv4SourceQuench(Json json) {
  ICMPv4SourceQuench packet = new ICMPv4SourceQuench();
  packet.code = json.code.to!ubyte;
  packet.checksum = json.checksum.to!ushort;
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.code = 2;
  json.checksum = 0;
  ICMPv4SourceQuench packet = cast(ICMPv4SourceQuench)toICMPv4SourceQuench(json);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

Protocol toICMPv4SourceQuench(ubyte[] encodedPacket) {
  ICMPv4SourceQuench packet = new ICMPv4SourceQuench();
  encodedPacket.read!ubyte();
  packet.code = encodedPacket.read!ubyte();
  packet.checksum = encodedPacket.read!ushort();
  encodedPacket.read!uint();
  return packet;
}

unittest {
  ubyte[] encodedPacket = [3, 2, 0, 0, 0, 0, 0, 0];
  ICMPv4SourceQuench packet = cast(ICMPv4SourceQuench)encodedPacket.toICMPv4SourceQuench;
  assert(packet.code == 2);
  assert(packet.checksum == 0);
}

class ICMPv4Redirect : ICMPv4Error {
  public:
    this() {
      super(5);
    }

    this(ubyte code, uint gateway, IP data) {
      super(5, code, data);
      _gateway = gateway;
    }

    override Json toJson() const {
      Json packet = super.toJson();
      packet.gateway = _gateway;
      return packet;
    }

    unittest {
      ICMPv4Redirect packet = new ICMPv4Redirect(2, 42, null);
      assert(packet.toJson.packetType == 5);
      assert(packet.toJson.code == 2);
      assert(packet.toJson.checksum == 0);
      assert(packet.toJson.gateway == 42);
    }

    override ubyte[] toBytes() const {
      ubyte[] packet = super.toBytes();
      packet.write!uint(_gateway, 4);
      return packet;
    }

    unittest {
      ICMPv4Redirect packet = new ICMPv4Redirect(2, 42, null);
      assert(packet.toBytes == [5, 2, 0, 0, 0, 0, 0, 42]);
    }

    @disable @property {
      override void type(ubyte type) { _type = type; }
    }

    @property {
      inout uint gateway() { return _gateway; }
      void gateway(uint gateway) { _gateway = gateway; }
    }

  private:
    uint _gateway = 0;
}

Protocol toICMPv4Redirect(Json json) {
  ICMPv4Redirect packet = new ICMPv4Redirect();
  packet.code = json.code.to!ubyte;
  packet.checksum = json.checksum.to!ushort;
  packet.gateway = json.gateway.to!uint;
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.code = 2;
  json.checksum = 0;
  json.gateway = 42;
  ICMPv4Redirect packet = cast(ICMPv4Redirect)toICMPv4Redirect(json);
  assert(packet.code == 2);
  assert(packet.checksum == 0);
  assert(packet.gateway == 42);
}

Protocol toICMPv4Redirect(ubyte[] encodedPacket) {
  ICMPv4Redirect packet = new ICMPv4Redirect();
  encodedPacket.read!ubyte();
  packet.code = encodedPacket.read!ubyte();
  packet.checksum = encodedPacket.read!ushort();
  packet.gateway = encodedPacket.read!uint();
  return packet;
}

unittest {
  ubyte[] encodedPacket = [3, 2, 0, 0, 0, 0, 0, 42];
  ICMPv4Redirect packet = cast(ICMPv4Redirect)encodedPacket.toICMPv4Redirect;
  assert(packet.code == 2);
  assert(packet.checksum == 0);
  assert(packet.gateway == 42);
}
