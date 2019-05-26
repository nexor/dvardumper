module dvardumper.typevar;

public import dvardumper.dumper;
import std.meta : Alias;
import std.traits;

template V(alias a)
{
    enum string V = __traits(identifier, a);
}

TypeVar toTypeVar(T)(T var, string varname = "")
{
    import std.conv : to;

    TypeVar typeVar;

    static if (isAggregateType!T) {
        typeVar = new AggregateTypeVar(typeid(var).to!string, var.sizeof)
                       .name(varname);
        static foreach(member; __traits(allMembers, T))
        {
            static if (!isAccessible!(T, member)) {
                pragma(msg, "Skipping non-accessible member " ~ T.stringof ~ "." ~ member);
            } else static if (isProperty!(T, member)) {
                pragma(msg, "Dumping " ~ T.stringof ~ "." ~ member);
                (cast(AggregateTypeVar)typeVar)
                    .addField(__traits(getMember, var, member).toTypeVar(member));
            }
        }

    } else static if (isBasicType!T) {
        typeVar = new BasicTypeVar(typeid(var).to!string, var.sizeof)
                       .value(var.to!string)
                       .name(varname);
    } else static if (isPointer!T) {
        typeVar = new PointerTypeVar(typeid(var).to!string, var.sizeof)
                        .pointer(cast(void*)var)
                        .name(varname);
    } else static if (isArray!T) {
        typeVar = new ArrayTypeVar(typeid(var), var.sizeof)
                        .elementCount(var.length)
                        .elementSize(ArrayElementType!T.sizeof)
                        .isPrintable(isSomeString!T)
                        .array(cast(byte[])var)
                        .name(varname);
    } else {
        typeVar = new UnknownTypeVar(typeid(var).to!string, var.sizeof)
                        .name(varname);
    }

    return typeVar;
}

template isAccessible(T, string member)
{
    enum isAccessible = __traits(getProtection, __traits(getMember, T, member)) == "public";
}

template isProperty(T, string member)
{
    alias fieldValue = Alias!(__traits(getMember, T, member));
    enum isProperty = !isType!fieldValue && !isFunction!fieldValue && !__traits(isTemplate, fieldValue);
}

template ArrayElementType(T : T[])
{
  alias T ArrayElementType;
}

abstract class TypeVar
{
    protected:
        TypeInfo _typeInfo;
        string _name; // var name or field name
        string _typeName;
        size_t _size;

    public:
        this(string typeName, size_t size)
        {
            this.typeName(typeName);
            this.size(size);
        }

        @property pure
        string name()
        {
            return _name;
        }

        @property pure
        typeof(this) name(string name)
        {
            _name = name;

            return this;
        }

        @property pure
        string typeName()
        {
            return _typeName;
        }

        @property pure
        typeof(this) typeName(string typeName)
        {
            _typeName = typeName;

            return this;
        }

        @property pure
        size_t size()
        {
            return _size;
        }

        @property pure
        typeof(this) size(size_t size)
        {
            _size = size;

            return this;
        }
}

class BasicTypeVar : TypeVar
{
    protected:
        string _value;

    public:
        this(string typeName, size_t size)
        {
            super(typeName, size);
        }

        @property pure
        string value()
        {
            return _value;
        }

        @property pure
        typeof(this) value(string value)
        {
            _value = value;

            return this;
        }
}

class PointerTypeVar : TypeVar
{
    protected:
        void* _pointer;

    public:
        this(string typeName, size_t size)
        {
            super(typeName, size);
        }

        @property pure
        void* pointer()
        {
            return _pointer;
        }

        @property pure
        typeof(this) pointer(void* ptr)
        {
            _pointer = ptr;

            return this;
        }
}

class ArrayTypeVar : TypeVar
{
    protected:
        byte[] _array;
        size_t _elementCount;
        size_t _elementSize;
        bool   _isPrintable;
        size_t _maxPrintCount = 512;

    public:
        this(TypeInfo typeInfo, size_t size)
        {
            import std.conv : to;

            super(typeInfo.to!string, size);
            _typeInfo = typeInfo;
        }

        @property pure
        byte[] array()
        {
            return _array;
        }

        @property pure
        typeof(this) array(byte[] array)
        {
            _array = array;

            return this;
        }

        size_t elementCount()
        {
            return _elementCount;
        }

        typeof(this) elementCount(size_t count)
        {
            _elementCount = count;

            return this;
        }

        size_t elementSize()
        {
            return _elementSize;
        }

        typeof(this) elementSize(size_t size)
        {
            _elementSize = size;

            return this;
        }

        bool isPrintable()
        {
            return _isPrintable;
        }

        typeof(this) isPrintable(bool isPrintable)
        {
            _isPrintable = isPrintable;

            return this;
        }

        size_t maxPrintCount()
        {
            return _maxPrintCount;
        }
}

class UnknownTypeVar : TypeVar
{
    this(string typeName, size_t size)
    {
        super(typeName, size);
    }
}

class AggregateTypeVar : TypeVar
{
    protected:
        TypeVar[string] _fields;

    public:
        this(string typeName, size_t size)
        {
            super(typeName, size);
        }

        pure
        void addField(TypeVar typeVar)
        in
        {
            assert(typeVar.name != "");
        }
        body
        {
            _fields[typeVar.name] = typeVar;
        }

        @property pure
        auto fields()
        {
            return _fields;
        }
}