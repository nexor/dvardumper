module dvardumper.dumper.array;

import dvardumper.base : Dumper, DumpOptions, writeIndent;
import dvardumper.typevar : TypeVar, ArrayTypeVar;
import std.outbuffer : OutBuffer;

class ArrayTypeDumper
{
    private OutBuffer buffer;

    public this(OutBuffer buffer)
    {
        this.buffer = buffer;
    }

    public void opCall(ArrayTypeVar v, DumpOptions options, ushort indentLevel = 0)
    {
        buffer.writeIndent(options.indentString, indentLevel);

        string typeName = v.typeName;

        auto aliasMap = [
            typeid(string).toString() : string.stringof,
            typeid(dstring).toString() : dstring.stringof,
            typeid(wstring).toString() : wstring.stringof
        ];

        if (typeName in aliasMap) {
            typeName = aliasMap[typeName];
        }

        buffer.writef("%s", typeName);
        if (options.showSize) {
            buffer.writef("(%d)", v.size);
        }
        buffer.writef(" %s", v.name);
        if (!v.isNull) {
            buffer.writef("[%d*%d]", v.elementCount, v.elementSize);
            if (v.isPrintable) {
                if (v.elementCount > v.maxPrintCount) {
                    string value = cast(string)v.array[0..v.elementSize * v.maxPrintCount];
                    buffer.writefln(` = "%s ..."`, value);
                } else {
                    buffer.writefln(` = "%s"`, cast(string)v.array);
                }
            } else {
                buffer.writefln(": <%d bytes of data>", v.elementCount * v.elementSize);
            }
        } else {
            buffer.writefln(` = null`);
        }
    }
}
