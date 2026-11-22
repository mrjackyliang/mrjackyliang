import javax.swing.*;
import java.awt.*;
import java.util.Random;

/**
 * Utility.
 */
public class Utility {
    private static final String name = "Tile Matching Game";
    private static final ImageIcon icon = new ImageIcon("logo.png");

    /**
     * Color text.
     *
     * @param ansiColorCode - Ansi color code.
     * @param message       - Message.
     * @return String
     */
    public static String colorText(int ansiColorCode, String message) {
        return "\033[" + ansiColorCode + "m" + message + "\033[0m";
    }

    /**
     * Generate random color.
     *
     * @return Color
     */
    public static Color generateRandomColor() {
        return new Color((float)Math.random(), (float)Math.random(), (float)Math.random());
    }

    /**
     * Generate random integer.
     *
     * @param max - Max.
     * @return int
     */
    public static int generateRandomInteger(Integer max) {
        Random random = new Random();

        return (max != null) ? random.nextInt(max) : random.nextInt();
    }

    /**
     * Get application name.
     *
     * @return String
     */
    public static String getApplicationName() {
        return name;
    }

    /**
     * Get logo icon.
     *
     * @return ImageIcon
     */
    public static ImageIcon getLogoIcon() {
        return new ImageIcon(Utility.icon.getImage().getScaledInstance(50, 50, Image.SCALE_SMOOTH));
    }

    /**
     * Get os name.
     *
     * @return String
     */
    public static String getOSName() {
        return System.getProperty("os.name");
    }

    /**
     * Print color palette.
     *
     * @param colors - Colors.
     */
    public static void printColorPalette(Color[] colors) {
        Utility.printDebugMessage("\"printColorPalette\" - Printing color palette");

        for (int i = 0; i < colors.length; i += 1) {
            System.out.println(colorText(90, "Color #" + (i + 1) + ": " + colors[i].getRGB()));
        }
    }

    /**
     * Print debug message.
     *
     * @param message - Message.
     */
    public static void printDebugMessage(String message) {
        System.out.println(colorText(90, "DEBUG: " + message + " ..."));
    }

    /**
     * Print error message.
     *
     * @param message - Message.
     */
    public static void printErrorMessage(String message) {
        System.out.println(colorText(91, "ERROR: " + message + "."));
    }

    /**
     * Print tile grid.
     *
     * @param tileGrid - Tile grid.
     */
    public static void printTileGrid(int[][] tileGrid) {
        int rows = tileGrid.length;
        int columns = tileGrid[0].length;
        int[] columnWidth = new int[columns];

        // Find the largest width available in each column.
        for (int j = 0; j < columns; j += 1) {
            int maxWidth = 0;

            for (int i = 0; i < rows; i += 1) {
                int width = String.valueOf(tileGrid[i][j]).length();

                if (width > maxWidth) {
                    maxWidth = width;
                }
            }

            // Assign the maximum display width for that column.
            columnWidth[j] = maxWidth;
        }

        Utility.printDebugMessage("\"printTileGrid\" - Printing tile grid");

        // Print the tile grid.
        for (int i = 0; i < rows; i += 1) {
            for (int j = 0; j < columns; j += 1) {
                // Format specifier (e.g. %-3s) included to pad the text from left side.
                // The format will save at least 3 character spacings ("[" and "] " characters).
                String formattedTile = String.format("%-" + (columnWidth[j] + 3) + "s", "[" + tileGrid[i][j] + "] ");

                System.out.print(colorText(90, formattedTile));
            }

            System.out.println();
        }
    }
}
