module netload.protocols.imap.imap;

import netload.core.protocol;
import netload.core.conversion.array_conversion;
import stdx.data.json;
import std.conv;

class IMAP : Protocol {
  public:
    static IMAP opCall(inout JSONValue val) {
  		return new IMAP(val);
  	}

    this() {

    }

    this(string b) {
      _body = b;
    }

    this(JSONValue json) {
      _body = json["body_"].get!string;
    }

    this(ubyte[] encoded) {
      this(cast(string)(encoded));
    }

    override @property inout string name() { return "IMAP"; };
    override @property Protocol data() { return null; }
    override @property void data(Protocol p) { }
    override @property int osiLayer() const { return 7; }

    override JSONValue toJson() const {
      JSONValue json = [
        "body_": JSONValue(_body),
        "name": JSONValue(name)
      ];
      return json;
    }

    unittest {
      IMAP packet = new IMAP("test");
      JSONValue json = [
        "body_": JSONValue("test"),
        "name": JSONValue("IMAP")
      ];
      assert(packet.toJson == json);
    }

    override ubyte[] toBytes() const {
      return cast(ubyte[])(_body.dup);
    }

    unittest {
      IMAP packet = new IMAP("test");
      assert(packet.toBytes == cast(ubyte[])("test"));
    }

    override string toString() const { return toJson.toJSON; }

    @property string str() const { return _body; }
    @property void str(string b) { _body = b; }

  private:
    string _body;
}

unittest {
  JSONValue json = [
    "body_": JSONValue("test")
  ];
  IMAP packet = cast(IMAP)to!IMAP(json);
  assert(packet.str == "test");
}

unittest {
  ubyte[] encoded = [116, 101, 115, 116];
  IMAP packet = cast(IMAP)encoded.to!IMAP();
  assert(packet.str == "test");
}
