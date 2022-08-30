module tabular.render;

import tabular.util;
import tabular.config;

/** 
 * Builder class for preparing and rendering text-based tables. Contains some
 * fluent-style methods for configuration.
 */
public class TableBuilder {
    import std.array;

    private Appender!string app;
    private string[][] data;
    private RefAppender!(string[][]) rowAppender;
    private TableConfig config;

    public this(Appender!string app, string[][] data, TableConfig config) {
        this.app = app;
        this.data = data;
        this.config = config;
        this.rowAppender = appender(&this.data);
    }

    public this() {
        this(appender!string, null, TableConfig.defaultValues());
    }

    public TableBuilder withData(string[][] data) {
        this.data = data;
        return this;
    }

    public TableBuilder withRow(string[] row) {
        this.rowAppender ~= row;
        return this;
    }

    public TableBuilder withConfig(TableConfig config) {
        this.config = config;
        return this;
    }

    public TableBuilder bordered(bool bordered = true) {
        this.config.borders = true;
        return this;
    }

    public TableBuilder indicateHeader(bool indicateHeader = true) {
        this.config.indicateHeader = indicateHeader;
        return this;
    }

    public string build() {
        auto renderer = new TableRenderer(this.app, this.data, this.config);
        renderer.render();
        return this.app[];
    }
}

public string renderTable(string[][] data, TableConfig config = TableConfig.defaultValues()) {
    return new TableBuilder().withData(data).withConfig(config).build();
}

/** 
 * Internal state-based renderer for actual rendering of table texts. Uses an
 * existing output component, data, and configuration to render a table to the
 * output.
 */
package class TableRenderer {
    import std.array : Appender, replicate, split;

    private Appender!string output;
    private string[][] data;
    private TableConfig config;

    private uint rows;
    private uint cols;
    private uint[] rowSizes;
    private uint[] colSizes;

    package this(Appender!string output, string[][] data, TableConfig config) {
        this.output = output;
        this.data = data;
        this.config = config;
    }

    package void render() {
        this.rowSizes = tabular.util.rowSizes(this.data);
        this.colSizes = columnSizes(this.data);
        this.rows = cast(uint) this.rowSizes.length;
        this.cols = cast(uint) this.colSizes.length;

        foreach (row; 0 .. this.rows) {
            renderRow(row);
        }
    }

    private void renderRow(uint row) {
        if (config.borders) {
            if (config.indicateHeader && row == 1 && rows > 1) {
                addRowBorder("=");
            } else {
                addRowBorder("-");
            }
            output ~= '\n';
        }
        addVerticalPaddingLines(config.padding.top);

        string[][] linedValues;
        foreach (col, s; data[row]) {
            string wrapped = wrapNoSpace(s, colSizes[col]);
            string[] lines = wrapped.split("\n");
            linedValues ~= lines;
        }
        uint rowSize = rowSizes[row];
        foreach (line; 0 .. rowSize) {
            foreach (col, colSize; colSizes) {
                if (config.borders) output ~= '|';
                output ~= replicate(" ", config.padding.left);
                string content;
                if (col < linedValues.length && line < linedValues[col].length) {
                    string c = linedValues[col][line];
                    size_t emptySpace = colSize - c.length;
                    ColumnConfig columnConfig = config.getColumnConfig(cast(uint) col);
                    if (columnConfig.textAlign == TextAlign.LEFT) {
                        content = c ~ replicate(" ", emptySpace);
                    } else if (columnConfig.textAlign == TextAlign.RIGHT) {
                        content = replicate(" ", emptySpace) ~ c;
                    } else {
                        size_t left = emptySpace / 2;
                        size_t right = emptySpace - left;
                        content = replicate(" ", left) ~ c ~ replicate(" ", right);
                    }
                } else {
                    content = replicate(" ", colSize);
                }
                output ~= content;
                output ~= replicate(" ", config.padding.right);
                if (config.borders && col + 1 == cols) output ~= '|';
            }
            // Add a new line if we need to render any other content after this.
            if (row + 1 < rows || line + 1 < rowSize || config.borders) output ~= '\n';
        }

        addVerticalPaddingLines(config.padding.bottom);
        if (config.borders && row + 1 == rows) {
            addRowBorder("-");
        }
    }

    private void addRowBorder(string barChar) {
        output ~= '+';
        foreach (col; 0 .. cols) {
            output ~= replicate(barChar, colSizes[col] + config.padding.left + config.padding.right);
            output ~= '+';
        }
    }

    private void addVerticalPaddingLines(uint amount) {
        foreach (i; 0 .. amount) {
            foreach (col; 0 .. cols) {
                if (config.borders) output ~= '|';
                output ~= replicate(" ", colSizes[col] + config.padding.left + config.padding.right);
                if (config.borders && col + 1 == cols) output ~= '|';
            }
            output ~= '\n';
        }
    }
}

unittest {
    import std.stdio;

    TableConfig cfgBordered = TableConfig.defaultValues();
    TableConfig cfgUnbordered = TableConfig.defaultValues();
    cfgUnbordered.borders = false;

    string tbl1 = new TableBuilder()
        .withConfig(cfgBordered)
        .withRow(["a", "b", "c"])
        .build();
    assert(
        "+---+---+---+\n" ~
        "| a | b | c |\n" ~
        "+---+---+---+" == tbl1
    );
    string tbl2 = new TableBuilder()
        .withConfig(cfgUnbordered)
        .withRow(["a", "b", "c"])
        .withRow(["d", "e", "f"])
        .build();
    assert(
        " a  b  c \n" ~
        " d  e  f " == tbl2
    );
    string tbl3 = new TableBuilder()
        .withConfig(cfgBordered)
        .withRow(["a", "bc", "def"])
        .withRow(["ghi", "jk", "l"])
        .build();
    assert(
        "+-----+----+-----+\n" ~
        "| a   | bc | def |\n" ~
        "+-----+----+-----+\n" ~
        "| ghi | jk | l   |\n" ~
        "+-----+----+-----+" == tbl3
    );
    TableConfig cfg3 = TableConfig.defaultValues();
    cfg3.columnConfigs[0] = ColumnConfig(TextAlign.RIGHT);
    string tbl4 = new TableBuilder()
        .withConfig(cfg3)
        .withRow(["a", "bc", "def"])
        .withRow(["ghi", "jk", "l"])
        .build();
    assert(
        "+-----+----+-----+\n" ~
        "|   a | bc | def |\n" ~
        "+-----+----+-----+\n" ~
        "| ghi | jk | l   |\n" ~
        "+-----+----+-----+" == tbl4
    );
}