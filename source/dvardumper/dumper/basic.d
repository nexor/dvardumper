module dvardumper.dumper.basic;

import dvardumper.base : Dumper, DumpOptions, writeIndent;
import dvardumper.typevar : TypeVar, BasicTypeVar;
import std.outbuffer : OutBuffer;


class BasicTypeDumper
{
    private OutBuffer buffer;

    public this(OutBuffer buffer)
    {
        this.buffer = buffer;
    }

    public void opCall(BasicTypeVar v, DumpOptions options, ushort indentLevel = 0)
    {
        buffer.writeIndent(options.indentString, indentLevel);
        buffer.writef("%s", v.typeName);
        if (options.showSize) {
            buffer.writef("(%d)", v.size);
        }

        buffer.writefln(" %s = %s", v.name, v.value);
    }
}
