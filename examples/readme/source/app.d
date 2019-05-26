import dvardumper;

struct MyArray
{
    ubyte[4] ubyteArray;
}

struct MyStruct
{
    align(1):

    string f1 = "mystring";
    int f2 = 4;
    bool b = true;
    MyArray myArr;
    void* voidPointer;
}

int main(string[] args)
{
    auto varDumper = new VarDumper();

    auto s = MyStruct();
    varDumper.dump(s);

    int a = 6;
    varDumper.dump(a, V!a);

    return 0;
}
