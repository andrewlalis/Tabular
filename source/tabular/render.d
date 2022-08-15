module tabular.render;

import tabular.util;

/** 
 * Configuration properties that affect how a table is rendered.
 */
public struct TableConfig {
    /** 
     * Whether to render borders around table cells.
     */
    bool borders;

    /** 
     * Whether to apply a thicker border to underline the first (header) row.
     */
    bool indicateHeader;

    /** 
     * Padding to apply to each table cell's contents.
     */
    Insets padding;

    /** 
     * A set of column-specific configuration properties to apply to all cells
     * in that column.
     */
    ColumnConfig[uint] columnConfigs;

    public static TableConfig defaultValues() {
        TableConfig cfg;
        cfg.borders = true;
        cfg.indicateHeader = false;
        cfg.padding = Insets(0, 0, 1, 1);
        return cfg;
    }

    public static struct Insets {
        uint top;
        uint bottom;
        uint left;
        uint right;
    }

    public static struct ColumnConfig {
        public static enum TextAlign {LEFT, RIGHT, CENTER}

        TextAlign textAlign;

        public static ColumnConfig defaultValues() {
            ColumnConfig cfg;
            cfg.textAlign = TextAlign.LEFT;
            return cfg;
        }
    }
}

/** 
 * Builder class for preparing and rendering text-based tables. Contains some
 * fluent-style methods for configuration.
 */
public class TableBuilder {
    import std.array;

    private Appender!string app;
    private string[][] data;
    private TableConfig config;

    public this(Appender!string app, string[][] data, TableConfig config) {
        this.app = app;
        this.data = data;
        this.config = config;
    }

    public this() {
        this(appender!string, null, TableConfig.defaultValues());
    }

    public TableBuilder withData(string[][] data) {
        this.data = data;
        return this;
    }

    public TableBuilder withConfig(TableConfig config) {
        this.config = config;
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
                    TableConfig.ColumnConfig columnConfig = cast(uint) col in config.columnConfigs
                        ? config.columnConfigs[cast(uint) col]
                        : TableConfig.ColumnConfig.defaultValues();
                    alias ALGN = TableConfig.ColumnConfig.TextAlign;
                    if (columnConfig.textAlign == ALGN.LEFT) {
                        content = c ~ replicate(" ", emptySpace);
                    } else if (columnConfig.textAlign == ALGN.RIGHT) {
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
