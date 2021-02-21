module dvardumper.base;

import std.stdio : write;
import dvardumper.typevar : toTypeVar, TypeVar, BasicTypeVar, PointerTypeVar,
    ArrayTypeVar, AggregateTypeVar, UnknownTypeVar;
import dvardumper.dumper.basic : BasicTypeDumper;
import std.outbuffer : OutBuffer;
import std.array : empty;

void dump(T)(Dumper d, T var, string varname = "")
{
    d(var.toTypeVar(varname), DumpOptions())
     .write();
}

interface Dumper
{
    string opCall(TypeVar, DumpOptions, ushort = 0);
}

struct DumpOptions
{
    bool showSize = false;
    string indentString = "  ";
}

void writeIndent(OutBuffer buffer, string indentString, ushort level = 0)
{
    import std.array : replicate;

    buffer.write(indentString.replicate(level));
}

class VarDumper : Dumper
{
    private:
        OutBuffer buffer;
        string indentString;
        BasicTypeDumper basicTypeDumper;

    public:
        this()
        {
            buffer = new OutBuffer();
            basicTypeDumper = new BasicTypeDumper(buffer);
        }

        string opCall(TypeVar var, DumpOptions dumpOptions = DumpOptions(), ushort indentLevel = 0)
        {
            indentString = dumpOptions.indentString;
            buffer.clear();
            buffer.writefln("%s", "---------------");

            dumpInternal(var, 0, dumpOptions);

            buffer.writefln("%s", "===============");

            return buffer.toString();
        }

    protected:
        string formatVarName(string name)
        {
            if (name != "") {
                return `"` ~ name ~ `"`;
            }

            return "";
        }

        void dumpInternal(TypeVar var, ushort level, DumpOptions dumpOptions)
        {
            if (auto v = cast(BasicTypeVar)var) {
                basicTypeDumper(v, dumpOptions, level);
            } else if (auto v = cast(PointerTypeVar)var) {
                dumpPointerTypeVar(v, level, dumpOptions);
            } else if (auto v = cast(ArrayTypeVar)var) {
                dumpArrayTypeVar(v, level, dumpOptions);
            } else if (auto v = cast(AggregateTypeVar)var) {
                dumpAggregateTypeVar(v, level, dumpOptions);
            } else if (auto v = cast(UnknownTypeVar)var) {
                dumpUnknownTypeVar(v, level);
            } else {
                assert(0, "Can't determine TypeVar instance");
            }
        }

        void dumpPointerTypeVar(PointerTypeVar v, ushort level, DumpOptions dumpOptions)
        {
            writeIndent(level);
            buffer.writef("%s", v.typeName);
            if (dumpOptions.showSize) {
                buffer.writef("(%d)", v.size);
            }
            buffer.writefln(" %s = %#x", v.name, v.pointer);
        }

        void dumpArrayTypeVar(ArrayTypeVar v, ushort level, DumpOptions dumpOptions)
        {
            writeIndent(level);
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
            if (dumpOptions.showSize) {
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

        void dumpAggregateTypeVar(AggregateTypeVar v, ushort level, DumpOptions dumpOptions)
        {
            writeIndent(level);
            buffer.writef("%s", v.typeName);
            if (dumpOptions.showSize) {
                buffer.writef("(%d)", v.size);
            }

            if (!v.name.empty) {
                buffer.writef(" %s", v.name);
            }

            if (!v.isNull) {
                buffer.writefln(" = {");
                foreach (TypeVar field; v.fields) {
                    dumpInternal(field, cast(ushort)(level+1), dumpOptions);
                }
                writeIndent(level);
                buffer.writefln("}");

            } else {
                buffer.writefln(" = null");
            }
        }

        void dumpUnknownTypeVar(UnknownTypeVar v, ushort level)
        {
            writeIndent(level);
            buffer.writefln("%s(%d) %s: (unknown type var)", v.typeName, v.size, v.name);
        }

        void writeIndent(ushort level = 0)
        {
            import std.array : replicate;

            buffer.write(indentString.replicate(level));
        }
}

struct A
{
    int a = 1;
}

@("Test opCall dumpArrayTypeVar array of struct dump")
unittest
{
    import unit_threaded;

    auto dumper = new VarDumper;

    A[3] astructs;

    auto dumpOptions = DumpOptions();

    auto typeVar = astructs.toTypeVar(astructs.stringof);

    dumper(typeVar, dumpOptions).should ==
        "---------------\n" ~
        "dvardumper.base.A[3] astructs[3*4]: <12 bytes of data>\n" ~
        "===============\n";
}

@("Test opCall dumpArrayTypeVar null value")
unittest
{
    import unit_threaded;

    auto dumper = new VarDumper;

    string nullString = null;
    auto dumpOptions = DumpOptions();

    auto typeVar = nullString.toTypeVar(nullString.stringof);

    dumper(typeVar, dumpOptions).should ==
        "---------------\n" ~
        "string nullString = null\n" ~
        "===============\n";
}
