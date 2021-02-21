module dvardumper.base;

import std.stdio : write;
import dvardumper.typevar : toTypeVar, TypeVar, BasicTypeVar, PointerTypeVar,
    ArrayTypeVar, AggregateTypeVar, UnknownTypeVar;
import dvardumper.dumper.basic : BasicTypeDumper;
import dvardumper.dumper.pointer : PointerTypeDumper;
import dvardumper.dumper.array : ArrayTypeDumper;
import dvardumper.dumper.aggregate : AggregateTypeDumper;
import std.outbuffer : OutBuffer;

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
        PointerTypeDumper pointerTypeDumper;
        ArrayTypeDumper arrayTypeDumper;
        AggregateTypeDumper aggregateTypeDumper;

    public:
        this()
        {
            buffer = new OutBuffer();
            basicTypeDumper = new BasicTypeDumper(buffer);
            pointerTypeDumper = new PointerTypeDumper(buffer);
            arrayTypeDumper = new ArrayTypeDumper(buffer);
            aggregateTypeDumper = new AggregateTypeDumper(buffer, this);
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

    public void dumpInternal(TypeVar var, ushort level, DumpOptions dumpOptions)
        {
            if (auto v = cast(BasicTypeVar)var) {
                basicTypeDumper(v, dumpOptions, level);
            } else if (auto v = cast(PointerTypeVar)var) {
                pointerTypeDumper(v, dumpOptions, level);
            } else if (auto v = cast(ArrayTypeVar)var) {
                arrayTypeDumper(v, dumpOptions, level);
            } else if (auto v = cast(AggregateTypeVar)var) {
                aggregateTypeDumper(v, dumpOptions, level);
            } else if (auto v = cast(UnknownTypeVar)var) {
                dumpUnknownTypeVar(v, level);
            } else {
                assert(0, "Can't determine TypeVar instance");
            }
        }

    protected:
        void dumpUnknownTypeVar(UnknownTypeVar v, ushort level)
        {
            buffer.writeIndent(indentString, level);
            buffer.writefln("%s(%d) %s: (unknown type var)", v.typeName, v.size, v.name);
        }

        string formatVarName(string name)
        {
            if (name != "") {
                return `"` ~ name ~ `"`;
            }

            return "";
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
