import dvardumper;

struct MyArray
{
    ubyte[4] ubyteArray;
}

struct MyStruct
{
    align(1):

    string f1 = "rus:ЪЁ, chi:漢字";
    int f2 = 4;
    bool b = true;
    MyArray myArr;
    void* voidPointer;

    private string privateString = "private content";

    void myMethod()
    {
        // do nothing
    }
}

class MyClass
{
    MyStruct myStruct;
    int* intPointer;
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
    s.voidPointer = &s;

    d.dump(s);
}

void dumpClass(Dumper d)
{
    auto myClass = new MyClass();
    myClass.intPointer = &myClass.myStruct.f2;

    d.dump(myClass);
}
