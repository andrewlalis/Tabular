# Tabular
A simple text-based table generator.

```d
import tabular;
import std.stdio;

void main() {
    string[][] data = [
        ["name", "age", "profession"],
        ["Andrew", "15", "blacksmith"],
        ["John", "25", "carpenter"]
    ];
    // Use the TableBuilder
    string myTable = new TableBuilder().withData(data).build();
    writeln(myTable);
    // Or use a simplified function call
    writeln(renderTable(myTable));
    /* Output:
    +--------+-----+------------+
    | name   | age | profession |
    +--------+-----+------------+
    | Andrew | 15  | blacksmith |
    +--------+-----+------------+
    | John   | 25  | carpenter  |
    +--------+-----+------------+
    */
}
```

## Features
- Dynamic table sizes based on content.
- Text-alignment.
- Optional borders (on by default).
