import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Arrays;

/**
 * Tile matching game.
 */
public final class TileMatchingGame implements ActionListener {
    private final int[] userInput;
    private final int[][] tileGrid;
    private final Color[] colors;
    private final JFrame[] windows;

    /**
     * Main.
     *
     * @param args - Args.
     */
    public static void main(String[] args) {
        // Starts a new game instance.
        new TileMatchingGame();
    }

    /**
     * Tile matching game.
     */
    public TileMatchingGame() {
        this.userInput = askInitialInput(); // "userInput[0]: Rows" —— "userInput[1]: Columns" —— "userInput[2]: Types".
        this.tileGrid = generateTileGrid();
        this.colors = generateColors();
        this.windows = initializeUI(); // "[0]: mainWindow" —— "[1]: nextTileWindow".
    }

    /**
     * Ask initial input.
     *
     * @return int[]
     */
    private int[] askInitialInput() {
        String[] parameters = new String[]{"Rows", "Columns", "Types"};
        int[] maxBounds = {20, 20, 40}; // Values will be used to validate input bounds.
        int[] userInput = new int[3]; // Values will be used in generating the game.

        // Length of "parameters", "maxDigits", and "userInput" should be the same.
        for (int index = 0; index < parameters.length; index += 1) {
            boolean isInputValid = false;

            // Instructions say I don't need to validate input, but UX is an important consideration in product design.
            while (!isInputValid) {
                Integer result = UserInterface.askForIntegerDialog(null, "How many " + parameters[index].toLowerCase() + " (between 1 and " + maxBounds[index] + ")?");

                // Check if user pressed the "Cancel" or "X" button.
                if (result != null) {
                    userInput[index] = result;
                    isInputValid = true;
                } else {
                    System.exit(0);
                }

                // Checks if the user input for "rows", "columns", and "types" is valid.
                if (userInput[index] < 1 || userInput[index] > maxBounds[index]) {
                    UserInterface.showErrorDialog(null, parameters[index] + " must be between 1 and " + maxBounds[index] + ". Try again.");
                    isInputValid = false;
                }
            }
        }

        // Returns [0]: rows - [1]: columns - [2]: types.
        return userInput;
    }

    /**
     * Generate tile grid.
     *
     * @return int[][]
     */
    private int[][] generateTileGrid() {
        int rows = this.userInput[0];
        int columns = this.userInput[1];
        int[][] tileGrid = new int[rows][columns];

        // Set the tile color to white.
        for (int i = 0; i < rows; i += 1) {
            for (int j = 0; j < columns; j += 1) {
                tileGrid[i][j] = Color.WHITE.getRGB();
            }
        }

        return tileGrid;
    }

    /**
     * Generate colors.
     *
     * @return Color[]
     */
    private Color[] generateColors() {
        int requestedTypes = this.userInput[2];
        int gridRows = (requestedTypes > 5) ? (int) Math.ceil((double) requestedTypes / 5) : 1;
        int gridColumns = Math.min(requestedTypes, 5);

        Color[] generatedColors;
        JFrame paletteWindow = UserInterface.createWindowGrid(gridRows, gridColumns, "Colors");

        do {
            // Reset generated colors and reset the palette window.
            generatedColors = new Color[requestedTypes];
            paletteWindow.getContentPane().removeAll();

            // Generate unique colors.
            for (int i = 0; i < requestedTypes; i += 1) {
                Color generatedColor = Utility.generateRandomColor();

                /*
                 * If the generated color isn't unique, is white, or is yellow, re-generate it.
                 *
                 * Remember: White and yellow colors are reserved. If the tile
                 *           is white, it is empty. If the tile is yellow, it is
                 *           a matching set.
                 */
                while (
                        Arrays.asList(generatedColors).contains(generatedColor)
                                || generatedColor.getRGB() == Color.WHITE.getRGB()
                                || generatedColor.getRGB() == Color.YELLOW.getRGB()
                ) {
                    generatedColor = Utility.generateRandomColor();
                }

                // Add generated color into array.
                generatedColors[i] = generatedColor;

                // Add generated color into palette window.
                paletteWindow.add(UserInterface.createColorTile(
                        "palette-tile",
                        String.valueOf(i + 1),
                        generatedColor,
                        false,
                        null
                ));
            }

            // Set the window size and positioning.
            paletteWindow.setLocation(0, 0);
            paletteWindow.setSize(gridColumns * 100, gridRows * 100);

            // Replaces the need to do "palette.validate();" since the window was not visible from the start.
            paletteWindow.setVisible(true);

            // Ask user if the colors are okay.
            Boolean result = UserInterface.askForBooleanDialog(null, "Are these colors okay?");

            // If user clicked the "X" button, close the app.
            if (result == null) {
                System.exit(0);
            }

            // If user clicked the "Yes" button.
            if (result) {
                break;
            }
        } while (true);

        // Close the color palette window.
        paletteWindow.dispose();

        // For debugging purposes.
        Utility.printColorPalette(generatedColors);

        return generatedColors;
    }

    /**
     * Initialize ui.
     *
     * @return JFrame[]
     */
    private JFrame[] initializeUI() {
        int rowsLength = this.tileGrid.length;
        int columnsLength = this.tileGrid[0].length;
        JFrame mainWindow = UserInterface.createWindowGrid(rowsLength, columnsLength, null);
        JFrame nextTileWindow = UserInterface.createWindowGrid(1, 1, "Next Tile");

        // Fill in the main window with color tiles.
        for (int i = 1; i <= rowsLength; i += 1) {
            for (int j = 1; j <= columnsLength; j += 1) {
                mainWindow.add(UserInterface.createColorTile(
                        "main-tile",
                        i + "x" + j,
                        null,
                        true,
                        this
                ));
            }
        }

        // Pick a random color tile and assign it to the next tile window.
        nextTileWindow.add(UserInterface.createColorTile(
                "next-tile",
                "1",
                this.colors[Utility.generateRandomInteger(this.colors.length)],
                false,
                null
        ));

        // Resize the windows.
        mainWindow.setSize(columnsLength * 100, rowsLength * 100);
        nextTileWindow.setSize(175, 175);

        // Set window screen location.
        mainWindow.setLocationRelativeTo(null); // Move window to middle of screen.
        nextTileWindow.setLocation(mainWindow.getX() + mainWindow.getWidth() + 10, mainWindow.getY()); // Move window beside main window.

        // Ensure the main window is on top of everything else.
        nextTileWindow.setVisible(true);
        mainWindow.setVisible(true);

        // Returns [0]: mainWindow - [1]: nextTileWindow.
        return new JFrame[]{mainWindow, nextTileWindow};
    }

    /**
     * Process game.
     *
     * @param tile - Tile.
     */
    private void processGame(JButton tile) {
        String name = tile.getName();
        String action = tile.getActionCommand();

        try {
            int displayRow = Integer.parseInt(action.replaceAll("^(\\d+)x(\\d+)\\|\\|(.+)$", "$1"));
            int displayColumn = Integer.parseInt(action.replaceAll("^(\\d+)x(\\d+)\\|\\|(.+)$", "$2"));
            int displayColor = Integer.parseInt(action.replaceAll("^(\\d+)x(\\d+)\\|\\|(.+)$", "$3"));
            boolean isSetDetected = true; // Always start out if there was a set detected.

            // For debugging purposes.
            Utility.printDebugMessage("\"processGame\" - Tile clicked (name: " + name + ", row: " + displayRow + ", column: " + displayColumn + ", color: " + displayColor + ")");

            // Method returns "true" if tile was set. The game only ends if "setTileToColumn" returns "false".
            boolean isEndOfGame = !setTileToColumn(displayColumn);

            // For debugging purposes.
            Utility.printTileGrid(this.tileGrid);

            // If end of game, show "Game Over!" message. Otherwise, generate color for next tile.
            if (isEndOfGame) {
                UserInterface.showInformationDialog(null, "Game Over!");

                System.exit(0);
            }

            // Check if there is a valid set of characters to remove.
            while (isSetDetected) {
                isSetDetected = detectAndClearOutValidSet();
            }

            // Prepare a new color for the next round.
            generateNextTile();
        } catch (NumberFormatException error) {
            Utility.printErrorMessage("\"processGame\" - Failed to retrieve tile action information");
        }
    }

    /**
     * Set tile to column.
     *
     * @param displayColumn - Display column.
     * @return boolean
     */
    private boolean setTileToColumn(int displayColumn) {
        JFrame mainWindow = this.windows[0];
        JFrame nextTileWindow = this.windows[1];
        int rowsLength = this.tileGrid.length;
        int columnsLength = this.tileGrid[0].length;
        int currentColumn = displayColumn - 1; // Replaces the "currentColumn" to an index-accessible column.
        int currentColor = nextTileWindow.getContentPane().getComponent(0).getBackground().getRGB();

        // Check which row for the specified column is available.
        for (int currentRow = rowsLength - 1; currentRow >= 0; currentRow -= 1) {
            // Check if the tile color is white. This means tile is currently unoccupied.
            if (tileGrid[currentRow][currentColumn] == Color.WHITE.getRGB()) {
                int tilePosition = (currentRow * columnsLength) + currentColumn; // Converts the "row x column" position to a 1D array position.

                // Mark the tile as occupied both in memory and in the main window.
                this.tileGrid[currentRow][currentColumn] = currentColor;
                mainWindow.getContentPane().getComponent(tilePosition).setBackground(new Color(currentColor));

                // No need to continue the loop once tile is set.
                return true;
            }
        }

        // Tells the caller, tile failed to set, thus ending the game.
        return false;
    }

    /**
     * Generate next tile.
     */
    private void generateNextTile() {
        JFrame nextTileWindow = this.windows[1];

        // Remove the existing color tile.
        nextTileWindow.getContentPane().removeAll();

        // Add a new color tile.
        nextTileWindow.add(UserInterface.createColorTile(
                "next-tile",
                "1",
                this.colors[Utility.generateRandomInteger(this.colors.length)],
                false,
                null
        ));

        // Refresh the next tile window.
        nextTileWindow.validate();
    }

    /**
     * Detect and clear out valid set.
     *
     * @return boolean
     */
    private boolean detectAndClearOutValidSet() {
        int rowsLength = this.tileGrid.length;
        int columnsLength = this.tileGrid[0].length;
        JFrame mainWindow = this.windows[0];
        boolean detectedSet = false;

        // Check the tile grid horizontally for matching sets.
        for (int row = 0; row < tileGrid.length; row += 1) {
            for (int column = 0; column < tileGrid[0].length - 2; column += 1) {
                int currentColor = tileGrid[row][column];

                // Don't match tiles with white colors.
                if (currentColor != Color.WHITE.getRGB()) {
                    int consecutiveCount = countConsecutiveColors(row, column, currentColor, true);

                    if (consecutiveCount >= 3) {
                        detectedSet = true;

                        // Marks all matching letters horizontally with an asterisk.
                        for (int index = column; index < column + consecutiveCount; index += 1) {
                            int tilePosition = (row * columnsLength) + index;

                            tileGrid[row][index] = Color.YELLOW.getRGB();
                            mainWindow.getContentPane().getComponent(tilePosition).setBackground(Color.YELLOW);
                        }
                    }
                }
            }
        }

        // Check the tile grid vertically for matching sets.
        for (int column = 0; column < tileGrid[0].length; column += 1) {
            for (int row = 0; row < tileGrid.length - 2; row += 1) {
                int currentColor = tileGrid[row][column];

                // Don't match tiles with white colors.
                if (currentColor != Color.WHITE.getRGB()) {
                    int consecutiveCount = countConsecutiveColors(row, column, currentColor, false);

                    if (consecutiveCount >= 3) {
                        detectedSet = true;

                        // Marks all matching letters vertically with an asterisk.
                        for (int index = row; index < row + consecutiveCount; index += 1) {
                            int tilePosition = (index * columnsLength) + column;

                            tileGrid[index][column] = Color.YELLOW.getRGB();
                            mainWindow.getContentPane().getComponent(tilePosition).setBackground(Color.YELLOW);
                        }
                    }
                }
            }
        }

        // For debugging purposes.
        Utility.printTileGrid(this.tileGrid);

        // Refresh the main window to show highlighted sets.
        mainWindow.validate();

        // If the above checks detect matching sets, this will be triggered.
        if (detectedSet) {
            UserInterface.showInformationDialog(null, "You made a matching set!");

            for (int column = 0; column < columnsLength; column += 1) {
                int yellowTilesRow = rowsLength - 1;

                // If there are no yellow tiles, the "yellowTilesRow" will always be the same as "row".
                for (int row = yellowTilesRow; row >= 0; row -= 1) {
                    // Push the above tile down if current tile isn't a yellow tile.
                    if (this.tileGrid[row][column] != Color.YELLOW.getRGB()) {
                        int tilePosition = (yellowTilesRow * columnsLength) + column;

                        /*
                         * If the stars are in the middle of the column, this would essentially "re-assign"
                         * itself with the same character. You can check if it's not equal to each other, but
                         * why create additional time complexity? It is harmless as it is.
                         */
                        this.tileGrid[yellowTilesRow][column] = this.tileGrid[row][column];
                        mainWindow.getContentPane().getComponent(tilePosition).setBackground(new Color(this.tileGrid[row][column]));

                        // After replacing the asterisk with the above character, move up.
                        yellowTilesRow -= 1;
                    }
                }

                // Empty out the upper column with the white color.
                for (int row = yellowTilesRow; row >= 0; row -= 1) {
                    int tilePosition =  (row * columnsLength) + column;

                    this.tileGrid[row][column] = Color.WHITE.getRGB();
                    mainWindow.getContentPane().getComponent(tilePosition).setBackground(Color.WHITE);
                }
            }
        }

        // Refresh the main window to show removed sets.
        mainWindow.validate();

        return detectedSet;
    }

    /**
     * Count consecutive colors.
     *
     * @param row         - Row.
     * @param column      - Column.
     * @param targetColor - Target color.
     * @param horizontal  - Horizontal.
     * @return int
     */
    private int countConsecutiveColors(int row, int column, int targetColor, boolean horizontal) {
        int[][] tileGrid = this.tileGrid;
        int count = 0;

        // I can do if/else, but I'd like to keep things in smaller chunks.
        if (horizontal) {
            while (
                    column < tileGrid[0].length
                            && tileGrid[row][column] == targetColor // Makes sure the character matches what we're looking for (targetColor).
            ) {
                count += 1;
                column += 1; // Traverse until the end of the column.
            }
        }

        // I can do if/else, but I'd like to keep things in smaller chunks.
        if (!horizontal) {
            while (
                    row < tileGrid.length
                            && tileGrid[row][column] == targetColor // Makes sure the character matches what we're looking for (targetColor).
            ) {
                count += 1;
                row += 1; // Traverse until the end of the row.
            }
        }

        return count;
    }

    /**
     * Action performed.
     *
     * @param event - Event.
     */
    @Override
    public void actionPerformed(ActionEvent event) {
        // Assign to "source" variable and run "processGame()" if "event.getSource()" is a "JButton".
        if (event.getSource() instanceof JButton source) {
            processGame(source);
        }
    }
}
