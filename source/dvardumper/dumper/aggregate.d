module dvardumper.dumper.aggregate;

import dvardumper.base : VarDumper, DumpOptions, writeIndent;
import dvardumper.typevar : TypeVar, AggregateTypeVar;
import std.outbuffer : OutBuffer;
import std.array : empty;

class AggregateTypeDumper
{
    private OutBuffer buffer;
    private VarDumper parentDumper;

    public this(OutBuffer buffer, VarDumper parentDumper)
    {
        this.buffer = buffer;
        this.parentDumper = parentDumper;
    }

    public void opCall(AggregateTypeVar v, DumpOptions options, ushort indentLevel = 0)
    {
        buffer.writeIndent(options.indentString, indentLevel);

        buffer.writef("%s", v.typeName);
        if (options.showSize) {
            buffer.writef("(%d)", v.size);
        }

        if (!v.name.empty) {
            buffer.writef(" %s", v.name);
        }

        if (!v.isNull) {
            buffer.writefln(" = {");
            foreach (TypeVar field; v.fields) {
                parentDumper.dumpInternal(field, cast(ushort)(indentLevel+1), options);
            }
            buffer.writeIndent(options.indentString, indentLevel);
            buffer.writefln("}");

        } else {
            buffer.writefln(" = null");
        }
    }
}
