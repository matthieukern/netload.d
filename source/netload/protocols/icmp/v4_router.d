module netload.protocols.icmp.v4.router;

import netload.core.protocol;
import netload.protocols.icmp.common;
import vibe.data.json;
import std.bitmanip;

class ICMPv4RouterAdvert : ICMP {
  public:
    this() {
      super(9, 0);
      _routerAddr = new ubyte[4][_numAddr];
      _prefAddr = new ubyte[4][_numAddr];
    }

    this(ubyte numAddr, ushort life = 0) {
      super(9, 0);
      _numAddr = numAddr;
      _life = life;
      _routerAddr = new ubyte[4][_numAddr];
      _prefAddr = new ubyte[4][_numAddr];
    }

    override Json toJson() const {
      Json packet = super.toJson();
      packet.numAddr = _numAddr;
      packet.addrEntrySize = _addrEntrySize;
      packet.life = _life;
      packet.routerAddr = serializeToJson(_routerAddr);
      packet.prefAddr = serializeToJson(_prefAddr);
      return packet;
    }

    unittest {
      ICMPv4RouterAdvert packet = new ICMPv4RouterAdvert(3, 2);
      assert(packet.toJson.packetType == 9);
      assert(packet.toJson.code == 0);
      assert(packet.toJson.checksum == 0);
      assert(packet.toJson.numAddr == 3);
      assert(packet.toJson.addrEntrySize == 2);
      assert(packet.toJson.life == 2);
      assert(deserializeJson!(ubyte[4][])(packet.toJson.routerAddr) == [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]);
      assert(deserializeJson!(ubyte[4][])(packet.toJson.prefAddr) == [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]);
    }

    override ubyte[] toBytes() const {
      ubyte[] packet = super.toBytes();
      ubyte[] append = new ubyte[4];
      append.write!ubyte(_numAddr, 0);
      append.write!ubyte(_addrEntrySize, 1);
      append.write!ushort(_life, 2);
      packet ~= append;
      for (ubyte i = 0; i < _numAddr; i++) {
        packet ~= _routerAddr[i] ~ _prefAddr[i];
      }
      return packet;
    }

    unittest {
      ICMPv4RouterAdvert packet = new ICMPv4RouterAdvert(3, 2);
      assert(packet.toBytes == [9, 0, 0, 0, 3, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    }

    @property {
      inout ubyte numAddr() { return _numAddr; }
      void numAddr(ubyte numAddr) { _numAddr = numAddr; }
      inout ubyte addrEntrySize() { return _addrEntrySize; }
      void addrEntrySize(ubyte addrEntrySize) { _addrEntrySize = addrEntrySize; }
      inout ushort life() { return _life; }
      void life(ushort life) { _life = life; }
      ubyte[4][] routerAddr() { return _routerAddr; }
      void routerAddr(ubyte[4][] routerAddr) { _routerAddr = routerAddr; }
      ubyte[4][] prefAddr() { return _prefAddr; }
      void prefAddr(ubyte[4][] prefAddr) { _prefAddr = prefAddr; }
    }

    @disable @property {
      override void type(ubyte type) { _type = type; }
      override void code(ubyte code) { _code = code; }
    }

  private:
    ubyte _numAddr = 0;
    ubyte _addrEntrySize = 2;
    ushort _life = 0;
    ubyte[4][] _routerAddr;
    ubyte[4][] _prefAddr;
}

Protocol toICMPv4RouterAdvert(Json json) {
  ICMPv4RouterAdvert packet = new ICMPv4RouterAdvert(json.numAddr.to!ubyte, json.addrEntrySize.to!ubyte);
  packet.checksum = json.checksum.to!ushort;
  packet.life = json.life.to!ushort;
  packet.routerAddr = deserializeJson!(ubyte[4][])(json.routerAddr);
  packet.prefAddr = deserializeJson!(ubyte[4][])(json.prefAddr);
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.checksum = 0;
  json.numAddr = 3;
  json.addrEntrySize = 2;
  json.life = 1;
  json.routerAddr = serializeToJson([[1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]);
  json.prefAddr = serializeToJson([[1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]);
  ICMPv4RouterAdvert packet = cast(ICMPv4RouterAdvert)toICMPv4RouterAdvert(json);
  assert(packet.checksum == 0);
  assert(packet.life == 1);
  assert(packet.numAddr == 3);
  assert(packet.addrEntrySize == 2);
  assert(packet.routerAddr == [[1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]);
  assert(packet.prefAddr == [[1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]);
}

Protocol toICMPv4RouterAdvert(ubyte[] encodedPacket) {
  encodedPacket.read!ushort();
  ushort checksum = encodedPacket.read!ushort();
  ubyte numAddr = encodedPacket.read!ubyte();
  ubyte addrEntrySize = encodedPacket.read!ubyte();
  ushort life = encodedPacket.read!ushort();
  ICMPv4RouterAdvert packet = new ICMPv4RouterAdvert(numAddr, addrEntrySize);
  packet.checksum = checksum;
  packet.life = life;
  for (ubyte i = 0; i < numAddr; i++) {
    packet.routerAddr[i] = encodedPacket[(0 + i * 8)..(4 + i * 8)];
    packet.prefAddr[i] = encodedPacket[(4 + i * 8)..(8 + i * 8)];
  }
  return packet;
}

unittest {
  ubyte[] encodedPacket = [9, 0, 0, 0, 3, 2, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3];
  ICMPv4RouterAdvert packet = cast(ICMPv4RouterAdvert)encodedPacket.toICMPv4RouterAdvert;
  assert(packet.checksum == 0);
  assert(packet.numAddr == 3);
  assert(packet.addrEntrySize == 2);
  assert(packet.life == 2);
  assert(packet.routerAddr == [[1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]);
  assert(packet.prefAddr == [[1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]);
}

class ICMPv4RouterSollicitation : ICMP {
  public:
    this() {
      super(10, 0);
    }

    override ubyte[] toBytes() const {
      ubyte[] packet = super.toBytes();
      packet ~= [0, 0, 0, 0];
      return packet;
    }

    unittest {
      ICMPv4RouterSollicitation packet = new ICMPv4RouterSollicitation();
      assert(packet.toBytes == [10, 0, 0, 0, 0, 0, 0, 0]);
    }

    @disable @property {
      override void type(ubyte type) { _type = type; }
      override void code(ubyte code) { _code = code; }
    }
}

Protocol toICMPv4RouterSollicitation(Json json) {
  ICMPv4RouterSollicitation packet = new ICMPv4RouterSollicitation();
  packet.checksum = json.checksum.to!ushort;
  return packet;
}

unittest {
  Json json = Json.emptyObject;
  json.checksum = 0;
  ICMPv4RouterSollicitation packet = cast(ICMPv4RouterSollicitation)toICMPv4RouterSollicitation(json);
  assert(packet.checksum == 0);
}

Protocol toICMPv4RouterSollicitation(ubyte[] encodedPacket) {
  ICMPv4RouterSollicitation packet = new ICMPv4RouterSollicitation();
  encodedPacket.read!ushort();
  packet.checksum = encodedPacket.read!ushort();
  return packet;
}

unittest {
  ubyte[] encodedPacket = [10, 0, 0, 0, 0, 0, 0, 0];
  ICMPv4RouterSollicitation packet = cast(ICMPv4RouterSollicitation)encodedPacket.toICMPv4RouterSollicitation;
  assert(packet.checksum == 0);
}
