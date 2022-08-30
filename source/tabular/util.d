module tabular.util;

import std.string;

/** 
 * A two-dimensional component that's used to describe the total size taken up
 * by a mono-spaced text that's wrapped over multiple lines.
 */
public struct StringSize {
    uint width;
    uint height;
}

/** 
 * Wraps a string over multiple lines such that no line exceeds the specified
 * `columns` width.
 * Params:
 *   s = The string to wrap.
 *   columns = The number of characters on each line.
 * Returns: The wrapped string.
 */
public string wrapNoSpace(string s, in size_t columns) {
    import std.algorithm;
    import std.stdio;
    s = std.string.strip(s);
    char[] result;
    size_t currentColumn = 0;
    size_t idx = 0;
    while (idx < s.length) {
        char c = s[idx];
        result ~= c;
        if (idx + 1 == s.length) break;
        if (c == '\n') {
            currentColumn = 0;
        } else {
            currentColumn++;
            if (currentColumn == columns) {
                if (s[idx + 1] != '\n') result ~= '\n';
                currentColumn = 0;
            }
        }
        idx++;
    }
    return cast(string) result;
}

unittest {
    assert("a\nb\nc" == wrapNoSpace("abc", 1));
    assert("abc\nabc\nabc" == wrapNoSpace("abcabcabc", 3));
    assert("blacksmith\ntest" == wrapNoSpace("blacksmith\ntest", 10));
    assert("a b \nc d \ne f \ng h" == wrapNoSpace("a b c d e f g h", 4));
}

/** 
 * Computes size of the largest string of a list of strings.
 * Params:
 *   strings = The set of strings.
 * Returns: The size of the largest string.
 */
public uint maxStringSize(string[] strings) {
    uint size = 0;
    foreach (s; strings) {
        string s1 = strip(s);
        if (s1.length > size) size = cast(uint) s1.length;
    }
    return size;
}

unittest {
    assert(3 == maxStringSize(["a", "bc", "abc"]));
    assert(0 == maxStringSize([]));
    assert(6 == maxStringSize(["", "abcdef", "abc     "]));
}

/** 
 * Computes the 2D size of the string, if it were to be rendered while
 * respecting line breaks, and stripping any trailing whitespace.
 * Params:
 *   s = The string to get the size of.
 * Returns: The size of the string.
 */
public StringSize getSize(string s) {
    import std.algorithm;
    string[] lines = std.string.stripRight(s).split("\n");
    uint rowCount = cast(uint) lines.length;
    uint colCount = 0;
    foreach (line; lines) {
        colCount = cast(uint) max(colCount, std.string.stripRight(line).length);
    }
    return StringSize(colCount, rowCount);
}

unittest {
    assert(StringSize(0, 0) == getSize(""));
    assert(StringSize(1, 1) == getSize("a"));
    assert(StringSize(5, 1) == getSize("abcde"));
    assert(StringSize(5, 3) == getSize("abcde\n  a\nb"));
    assert(StringSize(5, 2) == getSize("    a\nabc"));
}

/** 
 * Computes the number of columns that exist in a 2D array of strings. That is,
 * the number of columns is equal to the length of the largest array of strings.
 * Params:
 *   strings = The 2D array of strings.
 * Returns: The number of columns in this array.
 */
public uint columnCount(string[][] strings) {
    uint count = 0;
    foreach (row; strings) {
        if (row.length > count) count = cast(uint) row.length;
    }
    return count;
}

/** 
 * Computes the sizes of all columns in a 2D array of strings.
 * Params:
 *   strings = The 2D array of strings.
 * Returns: The size of each column.
 */
public uint[] columnSizes(string[][] strings) {
    uint[] sizes = new uint[columnCount(strings)];
    foreach (row; strings) {
        foreach (i, s; row) {
            StringSize size = getSize(s);
            if (size.width > sizes[i]) sizes[i] = size.width;
        }
    }
    return sizes;
}

unittest {
    import std.stdio;
    assert([] == columnSizes([]));
    assert([3] == columnSizes([
        ["abc"],
        ["123"]
    ]));
    assert([3, 2] == columnSizes([
        ["abc", "a" ],
        ["123", "ab"]
    ]));
}

/** 
 * Computes the size of each row in a 2D array of strings.
 * Params:
 *   strings = The 2D array of strings.
 * Returns: The size of each row.
 */
public uint[] rowSizes(string[][] strings) {
    uint[] sizes = new uint[strings.length];
    foreach (i, row; strings) {
        foreach (s; row) {
            StringSize size = getSize(s);
            if (size.height > sizes[i]) sizes[i] = size.height;
        }
    }
    return sizes;
}