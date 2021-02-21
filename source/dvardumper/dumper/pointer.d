module dvardumper.dumper.pointer;

import dvardumper.base : Dumper, DumpOptions, writeIndent;
import dvardumper.typevar : TypeVar, PointerTypeVar;
import std.outbuffer : OutBuffer;

class PointerTypeDumper
{
    private OutBuffer buffer;

    public this(OutBuffer buffer)
    {
        this.buffer = buffer;
    }

    public void opCall(PointerTypeVar v, DumpOptions options, ushort indentLevel = 0)
    {
        buffer.writeIndent(options.indentString, indentLevel);
        buffer.writef("%s", v.typeName);
        if (options.showSize) {
            buffer.writef("(%d)", v.size);
        }
        buffer.writefln(" %s = %#x", v.name, v.pointer);
    }
}
