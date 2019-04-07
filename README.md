# dvardumper
Variable dumper for D

## Usage example

```d
import vardumper.d;

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
```

output:

```
Dumping var
---------------
app.MyStruct(33) {
  app.MyArray(4) {
    ubyte[4](4) ubyteArray: (unknown type var)
  }
  int(4) f2 = 4
  void*(8) voidPointer: (unknown type var)
  immutable(char)[](16) f1: (unknown type var)
  bool(1) b = true
}
===============
Dumping var [a]
---------------
int(4) a = 6
===============
```
