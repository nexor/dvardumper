module dvardumper.dumper;

import std.stdio;
import dvardumper.typevar;

void dump(T)(Dumper d, T var, string varname = "")
{
    d.doDump(var.toTypeVar(varname), DumpOptions());
}

interface Dumper
{
    void doDump(TypeVar, DumpOptions);
}

struct DumpOptions
{
    bool showSize = false;
}

class VarDumper : Dumper
{
    private:
        string indentString = "  ";

    public:
        void doDump(TypeVar var, DumpOptions dumpOptions)
        {
            writefln("Dumping var %s", formatVarName(var.name));
            writeln("---------------");

            dumpInternal(var, 0, dumpOptions);

            writefln("===============");
        }

    protected:
        string formatVarName(string name)
        {
            if (name != "") {
                return "[" ~ name ~ "]";
            }

            return "";
        }

        void dumpInternal(TypeVar var, ushort level, DumpOptions dumpOptions)
        {
            if (auto v = cast(BasicTypeVar)var) {
                dumpBasicTypeVar(v, level, dumpOptions);
            } else if (auto v = cast(PointerTypeVar)var) {
                dumpPointerTypeVar(v, level);
            } else if (auto v = cast(ArrayTypeVar)var) {
                dumpArrayTypeVar(v, level);
            } else if (auto v = cast(AggregateTypeVar)var) {
                dumpAggregateTypeVar(v, level, dumpOptions);
            } else if (auto v = cast(UnknownTypeVar)var) {
                dumpUnknownTypeVar(v, level);
            } else {
                assert(0, "Can't determine TypeVar instance");
            }
        }

        void dumpBasicTypeVar(BasicTypeVar v, ushort level, DumpOptions dumpOptions)
        {
            writeIndent(level);
            writefln("%s(%d) %s = %s", v.typeName, v.size, v.name, v.value);
        }

        void dumpPointerTypeVar(PointerTypeVar v, ushort level = 0)
        {
            writeIndent(level);
            writefln("%s(%d) %s = %#x", v.typeName, v.size, v.name, v.pointer);
        }

        void dumpArrayTypeVar(ArrayTypeVar v, ushort level = 0)
        {
            writeIndent(level);
            string typeName = v.typeName;
            if (typeName == "immutable(char)[]") {
                typeName = "string";
            }
            writef("%s(%d) %s[%d*%d]", typeName, v.size, v.name, v.elementCount, v.elementSize);

            if (v.isPrintable) {
                if (v.elementCount > v.maxPrintCount) {
                    string value = cast(string)v.array[0..v.elementSize * v.maxPrintCount];
                    writefln(` = "%s ..."`, value);
                } else {
                    writefln(` = "%s"`, cast(string)v.array);
                }
            } else {
                writefln(": <%d bytes of data>", v.elementCount * v.elementSize);
            }
        }

        void dumpAggregateTypeVar(AggregateTypeVar v, ushort level, DumpOptions dumpOptions)
        {
            writeIndent(level);
            if (v.name !is null) {
                writefln("%s(%d) %s {", v.typeName, v.size, v.name);
            } else {
                writefln("%s(%d) {", v.typeName, v.size);
            }

            foreach (TypeVar field; v.fields) {
                dumpInternal(field, cast(ushort)(level+1), dumpOptions);
            }

            writeIndent(level);
            writefln("}");
        }

        void dumpUnknownTypeVar(UnknownTypeVar v, ushort level = 0)
        {
            writeIndent(level);
            writefln("%s(%d) %s: (unknown type var)", v.typeName, v.size, v.name);
        }

        void writeIndent(ushort level = 0)
        {
            import std.array : replicate;

            write(indentString.replicate(level));
        }
}
