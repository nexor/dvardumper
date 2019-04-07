module dvardumper.dumper;

import std.stdio;
import dvardumper.d;

void dump(T)(Dumper d, T var, string varname = "")
{
    d.doDump(var.toTypeVar(varname));
}

interface Dumper
{
    void doDump(TypeVar);
}

class VarDumper : Dumper
{
    import std.range : repeat;

    public:
        void doDump(TypeVar var)
        {
            writefln("Dumping var %s", formatVarName(var.name));
            writeln("---------------");

            dumpInternal(var);

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

        void dumpInternal(TypeVar var, ushort level = 0)
        {
            if (auto v = cast(BasicTypeVar)var) {
                dumpBasicTypeVar(v, level);
            } else if (auto v = cast(AggregateTypeVar)var) {
                dumpAggregateTypeVar(v, level);
            } else if (auto v = cast(UnknownTypeVar)var) {
                dumpUnknownTypeVar(v, level);
            } else {
                assert(0, "Can't determine TypeVar instance");
            }
        }

        void dumpBasicTypeVar(BasicTypeVar v, ushort level = 0)
        {
            writeIndent(level);
            if (v.name != "") {
                writefln("%s(%d) %s = %s", v.typeName, v.size, v.name, v.value);
            } else {
                writefln("%s(%d) = %s", v.typeName, v.size, v.value);
            }
        }

        void dumpAggregateTypeVar(AggregateTypeVar v, ushort level = 0)
        {
            writeIndent(level);
            writefln("%s(%d) {", v.typeName, v.size);

            foreach (TypeVar field; v.fields) {
                dumpInternal(field, cast(ushort)(level+1));
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
            write(' '.repeat(level*2));
        }
}
