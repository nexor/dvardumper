module dvardumper.typevar;

import std.meta : Alias;
import std.traits;

template V(alias a)
{
    enum string V = __traits(identifier, a);
}

TypeVar toTypeVar(T)(T var, string varname = "")
    if (is(T == class))
{
    TypeInfo typeInfo = (var is null) ? typeid(T) : typeid(var);

    auto typeVar = new AggregateTypeVar(typeInfo);

    if (var !is null) {
        static foreach(member; __traits(allMembers, T))
        {
            static if (isProperty!(T, member))
            {
                typeVar.addField(__traits(getMember, var, member).toTypeVar(member));
            }
        }
    } else {
        typeVar.isNull = true;
    }

    typeVar.name = varname;

    return typeVar;
}




@("Test non-null class object to TypeVar conversion")
unittest
{
    import unit_threaded;
    import std.stdio;

    class S1
    {
        int s1 = 4;
        bool s2 = true;
    }

    S1 s = new S1();
    TypeVar typeVar = s.toTypeVar("s_class");

    auto aggregateTypeVar = cast(AggregateTypeVar)typeVar;
    aggregateTypeVar.shouldNotBeNull;

    aggregateTypeVar.name.should == "s_class";
    aggregateTypeVar.isNull = false;
    aggregateTypeVar.typeName.shouldNotBeNull;
    aggregateTypeVar.size.should == S.sizeof;
    aggregateTypeVar.fields.length.should == 2;
}

@("Test null value class object to TypeVar conversion")
unittest
{
    import unit_threaded;

    class S
    {
        int s1;
        string s2;
    }

    S s = null;

    auto aggregateTypeVar = cast(AggregateTypeVar)s.toTypeVar("s_class");
    aggregateTypeVar.shouldNotBeNull;

    aggregateTypeVar.name.should == "s_class";
    aggregateTypeVar.isNull.should  == true;
    aggregateTypeVar.size.should == S.sizeof;
}

TypeVar toTypeVar(T)(T var, string varname = "")
    if (isAggregateType!T && (!is(T == class)))
{
    TypeInfo typeInfo = typeid(var);

    auto typeVar = new AggregateTypeVar(typeInfo);

    static foreach(member; __traits(allMembers, T))
    {
        static if (isProperty!(T, member))
        {
            typeVar.addField(__traits(getMember, var, member).toTypeVar(member));
        }
    }


    typeVar.name = varname;

    return typeVar;
}

// using namespace dvardumper.typevar
struct S
{
    int s1 = 4;
    bool s2 = true;
}

@("Test aggregate type that is not a class to TypeVar conversion")
unittest
{
    import unit_threaded;

    S s;
    TypeVar typeVar = s.toTypeVar("s_struct");

    auto aggregateTypeVar = cast(AggregateTypeVar)typeVar;
    aggregateTypeVar.shouldNotBeNull;

    aggregateTypeVar.name.should == "s_struct";
    aggregateTypeVar.typeName.should == "dvardumper.typevar.S";
    aggregateTypeVar.size.should == S.sizeof;
    aggregateTypeVar.fields.length.should == 2;
}

TypeVar toTypeVar(T)(T var, string varname = "")
    if (isArray!T)
{
    import std.conv : to;

    auto typeVar = new ArrayTypeVar(typeid(var))
                        .elementCount(var.length)
                        .elementSize(ArrayElementType!T.sizeof)
                        .isPrintable(isSomeString!T);
    static if (isNullable!T)
    {
        if (var !is null) {
            typeVar.array = cast(byte[])var;
        } else {
            typeVar.isNull = true;
        }
    } else {
        typeVar.array = cast(byte[])var;
    }

    typeVar.name = varname;

    return typeVar;
}

@("Test array type to TypeVar conversion")
unittest
{
    import unit_threaded;

    int[] arr = [1,2,3];
    TypeVar typeVar = arr.toTypeVar("arr_array");

    auto arrayTypeVar = cast(ArrayTypeVar)typeVar;
    arrayTypeVar.shouldNotBeNull;

    arrayTypeVar.name.should == "arr_array";
    arrayTypeVar.typeName.should == "int[]";
    arrayTypeVar.isNull = false;
    arrayTypeVar.size.should == size_t.sizeof + size_t.sizeof;
    arrayTypeVar.elementCount.should == 3;
    arrayTypeVar.elementSize.should == int.sizeof;
    arrayTypeVar.isPrintable.should == false;
}

@("Test static array type to TypeVar conversion")
unittest
{
    import unit_threaded;

    int[3] arr = [1,2,3];
    auto arrayTypeVar = cast(ArrayTypeVar)arr.toTypeVar("arr_array");

    arrayTypeVar.shouldNotBeNull;

    arrayTypeVar.name.should == "arr_array";
    arrayTypeVar.typeName.should == "int[3]";
    arrayTypeVar.isNull = false;
    arrayTypeVar.size.should == (int[3]).sizeof;
    arrayTypeVar.elementCount.should == 3;
    arrayTypeVar.elementSize.should == int.sizeof;
    arrayTypeVar.isPrintable.should == false;
}

@("Test NULL array value to TypeVar conversion")
unittest
{
    import unit_threaded;

    int[] arr = null;
    TypeVar typeVar = arr.toTypeVar("arr_array");

    auto arrayTypeVar = cast(ArrayTypeVar)typeVar;
    arrayTypeVar.shouldNotBeNull;

    arrayTypeVar.name.should == "arr_array";
    arrayTypeVar.typeName.should == "int[]";
    arrayTypeVar.isNull = true;
    arrayTypeVar.size.should == size_t.sizeof + size_t.sizeof;
    arrayTypeVar.elementCount.should == 0;
    arrayTypeVar.elementSize.should == int.sizeof;
    arrayTypeVar.isPrintable.should == false;
}

TypeVar toTypeVar(T)(T var, string varname = "")
    if (!isAggregateType!T && !isArray!T)
{
    import std.conv : to;

    TypeVar typeVar;

    static if (isBasicType!T) {
        typeVar = new BasicTypeVar(typeid(var))
                        .value = var.to!string;
    } else static if (isPointer!T) {
        typeVar = new PointerTypeVar(typeid(var))
                        .pointer(cast(void*)var);
    } else {
        typeVar = new UnknownTypeVar(typeid(var));
    }

    typeVar.name(varname);

    return typeVar;
}

@("Test basic type to TypeVar conversion")
unittest
{
    import unit_threaded;

    int i = 42;
    TypeVar typeVar = i.toTypeVar("ivar");

    auto basicTypeVar = cast(BasicTypeVar)typeVar;
    basicTypeVar.shouldNotBeNull;

    basicTypeVar.name.should == "ivar";
    basicTypeVar.typeName.should == "int";
    basicTypeVar.size.should == int.sizeof;
    basicTypeVar.value.should == "42";
}

@("Test pointer type to TypeVar conversion")
unittest
{
    import unit_threaded;

    int* i = new int(5);

    (*i).should == 5;

    TypeVar typeVar = i.toTypeVar("pointer");

    auto pointerTypeVar = cast(PointerTypeVar)typeVar;
    pointerTypeVar.shouldNotBeNull;

    pointerTypeVar.name.should == "pointer";
    pointerTypeVar.typeName.should == "int*";
    pointerTypeVar.size.should == (int*).sizeof;

    int* pointer = cast(int*)pointerTypeVar.pointer;

    (cast(size_t)pointer).shouldBeGreaterThan(0);
    (*pointer).should == 5;
}

@("Test unknown type to TypeVar conversion")
unittest
{
    import unit_threaded;

    TypeVar typeVar = null.toTypeVar("unknown_type");

    auto unknownTypeVar = cast(UnknownTypeVar)typeVar;
    unknownTypeVar.shouldNotBeNull;

    unknownTypeVar.name.should == "unknown_type";
    unknownTypeVar.typeName.should == "typeof(null)";
    unknownTypeVar.size.should == typeof(null).sizeof;
}

template isAccessible(T, string member)
{
    enum isAccessible = __traits(getProtection, __traits(getMember, T, member)) == "public";
}

template isProperty(T, string member)
{
    static if (__traits(hasMember, T, member))
    {
        alias fieldValue = Alias!(__traits(getMember, T, member));
        enum isProperty = !isType!fieldValue && !isFunction!fieldValue && !__traits(isTemplate, fieldValue);
    } else {
        enum isProperty = false;
    }
}

enum isNullable(T) = is(typeof(null) : T);

template ArrayElementType(T : T[])
{
  alias T ArrayElementType;
}

abstract class TypeVar
{
    protected:
        TypeInfo _typeInfo;
        bool _isNull = false;
        string _name; // var name or field name
        string _typeName;
        size_t _size;

    public:
        this(TypeInfo typeInfo)
        {
            import std.conv : to;

            this.typeName = typeInfo.to!string;
            this.size = typeInfo.tsize;
        }

        @property pure
        bool isNull()
        {
            return _isNull;
        }

        @property pure
        typeof(this) isNull(bool value)
        {
            _isNull = value;

            return this;
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
        this(TypeInfo typeInfo)
        {
            super(typeInfo);
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
        this(TypeInfo typeInfo)
        {
            super(typeInfo);
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
        this(TypeInfo typeInfo)
        in
        {
            assert(cast(TypeInfo_Array)typeInfo !is null
                || cast(TypeInfo_StaticArray)typeInfo !is null);
        }
        body
        {
            super(typeInfo);
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
    this(TypeInfo typeInfo)
    {
        super(typeInfo);
    }
}

class AggregateTypeVar : TypeVar
{
    protected:
        TypeVar[string] _fields;

    public:
        this(TypeInfo typeInfo)
        {
            super(typeInfo);
        }

        pure
        void addField(TypeVar typeVar)
        in
        {
            assert(typeVar.name != "");
            assert(!isNull);
        }
        body
        {
            _fields[typeVar.name] = typeVar;
        }

        @property pure
        auto fields()
        in
        {
            assert(!isNull, "Cannot get fields of a null object");
        }
        body
        {
            return _fields;
        }
}
