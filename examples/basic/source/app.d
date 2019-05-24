import dvardumper.d;

struct MyArray
{
    ubyte[4] ubyteArray;
}

struct MyStruct
{
    align(1):

    string f1;
    int f2 = 4;
    bool b = true;
    MyArray myArr;
    void* voidPointer;

    private string privateString;

    void myMethod()
    {
        // do nothing
    }
}

class MyClass
{
    MyStruct myStruct;
}

int main(string[] args)
{
    auto varDumper = new VarDumper();

    dumpBasicType(varDumper);
    dumpStruct(varDumper);
    dumpClass(varDumper);

    return 0;
}

void dumpBasicType(Dumper d)
{
    int a = 6;
    d.dump(a, V!a);
}

void dumpStruct(Dumper d)
{
    auto s = MyStruct();
    d.dump(s);
}

void dumpClass(Dumper d)
{
    auto myClass = new MyClass();
    d.dump(myClass);
}
