module tabular.config;

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

    /** 
     * Gets the configuration properties for a given column of a table to be
     * rendered using this configuration. If no configuration has been
     * explicitly specified for the column, a default will be returned.
     * Params:
     *   col = The column to get the configuration properties for.
     * Returns: The column config.
     */
    public ColumnConfig getColumnConfig(uint col) {
        if (col in columnConfigs) return columnConfigs[col];
        return ColumnConfig.defaultValues();
    }
}

/** 
 * A struct containing preferences for a component's top, bottom, left, and
 * right sides, for things like padding or margins.
 */
public struct Insets {
    uint top;
    uint bottom;
    uint left;
    uint right;
}

/** 
 * Column-specific configuration that's used to determine how to format each
 * column of a table.
 */
public static struct ColumnConfig {
    TextAlign textAlign;
    uint maxWidth;
    uint minWidth;

    public static ColumnConfig defaultValues() {
        ColumnConfig cfg;
        cfg.textAlign = TextAlign.LEFT;
        cfg.minWidth = 5;
        cfg.maxWidth = 40;
        return cfg;
    }
}

/** 
 * Text alignment for a piece of text in a table cell.
 */
public enum TextAlign {LEFT, RIGHT, CENTER}