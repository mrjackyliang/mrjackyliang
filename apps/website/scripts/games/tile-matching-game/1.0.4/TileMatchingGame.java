import java.util.Random;
import java.util.Scanner;

/**
 * Tile matching game.
 */
public class TileMatchingGame {
    /**
     * Main.
     *
     * @param argv - Argv.
     */
    public static void main(String[] argv) {
        Scanner scanner = new Scanner(System.in);
        int[] userInput = askInitialInput(scanner); // "userInput[0]: Rows" —— "userInput[1]: Columns" —— "userInput[2]: Types".
        char[][] tileGrid = new char[userInput[0]][userInput[1]];
        char[] tiles = generateTileRange(userInput[2]);

        processGame(scanner, tileGrid, tiles);

        // Closes "System.in". Any reads after this will cause the "IllegalStateException" error.
        scanner.close();
    }

    /**
     * Ask initial input.
     *
     * @param scanner - Scanner.
     * @return int[]
     */
    private static int[] askInitialInput(Scanner scanner) {
        int[] userInput = new int[3]; // These values will be used in the "processGame()" and "generateTileRange()" methods.
        String[] parameters = new String[]{"Rows", "Columns", "Types"};

        // "parameters" index equals "userInput" index.
        for (int index = 0; index < parameters.length; index += 1) {
            boolean isInputValid = false;

            // Instructions say I don't need to validate input, but UX is an important consideration in product design.
            while (!isInputValid) {
                System.out.print("Enter the number of " + parameters[index].toLowerCase() + ": ");

                if (scanner.hasNextInt()) {
                    // Doesn't consume the "newline" character. Use "scanner.nextLine()" to clear out the buffer first.
                    userInput[index] = scanner.nextInt();
                    isInputValid = true;
                } else {
                    scanner.next();
                }

                // Checks if the user input for "rows" and "columns" is valid.
                if ((index == 0 || index == 1) && (userInput[index] < 1 || userInput[index] > 9)) {
                    printErrorMessage(parameters[index] + " must be an integer and between 1 to 9");
                    isInputValid = false;
                }

                // Checks if the user input for "types" is valid.
                if ((index == 2 && (userInput[index] < 1 || userInput[index] > 26))) {
                    printErrorMessage(parameters[index] + " must be an integer and between 1 to 26");
                    isInputValid = false;
                }
            }
        }

        // Throw away newline character left over from before.
        scanner.nextLine();

        // Returns [0]: rows - [1]: columns - [2]: types.
        return userInput;
    }

    /**
     * Process game.
     *
     * @param scanner  - Scanner.
     * @param tileGrid - Tile grid.
     * @param tiles    - Tiles.
     */
    private static void processGame(Scanner scanner, char[][] tileGrid, char[] tiles) {
        boolean isEndOfGame = false;

        while (!isEndOfGame) {
            boolean isColumnValid = false;
            char currentTile = getRandomTile(tiles);
            int inputColumn = 0;

            // Check if there is a valid set of characters to remove.
            detectAndClearOutValidSet(scanner, tileGrid);

            System.out.println("\n" + colorText("94", "Next Tile") + ": " + currentTile);

            printTileGrid(tileGrid);

            // Instructions say I don't need to validate input, but UX is an important consideration in product design.
            while (!isColumnValid) {
                System.out.print(colorText("96", "Enter the column") + ": ");

                if (scanner.hasNextInt()) {
                    // Doesn't consume the "newline" character. Use "scanner.nextLine()" to clear out the buffer first.
                    inputColumn = scanner.nextInt();
                    isColumnValid = true;
                } else {
                    scanner.next();
                }

                // Checks if the user input for "columns" is valid.
                if (inputColumn < 1 || inputColumn > tileGrid[0].length) {
                    isColumnValid = false;

                    // If for some weird reason the player decides to put a single column.
                    if (tileGrid[0].length == 1) {
                        printErrorMessage("Column must be 1");
                    } else {
                        printErrorMessage("Column must be an integer and between 1 to " + tileGrid[0].length);
                    }
                }
            }

            // Throw away newline character left over from before.
            scanner.nextLine();

            // Method returns "true" if tile was set. The game only ends if "setTileToColumn" returns "false".
            isEndOfGame = !setTileToColumn(tileGrid, currentTile, inputColumn);
        }

        // Prints out a "GAME OVER" message highlighted in red with the resulting tile grid.
        System.out.println("\n" + colorText("91", "GAME OVER"));
    }

    /**
     * Generate tile range.
     *
     * @param amount - Types.
     * @return char[]
     */
    private static char[] generateTileRange(int amount) {
        char[] allowedChars = new char[amount];

        // Generate an array of uppercase letters based on "userInput[2]".
        for (int index = 0; index < amount; index += 1) {
            allowedChars[index] = (char) ('A' + index);
        }

        return allowedChars;
    }

    /**
     * Get random tile.
     *
     * @param tiles - Tiles.
     * @return char
     */
    private static char getRandomTile(char[] tiles) {
        Random random = new Random();

        // Picks a random uppercase letter generated earlier by the "generateTileRange()" method.
        return tiles[random.nextInt(tiles.length)];
    }

    /**
     * Set tile to column.
     *
     * @param tileGrid      - Tile grid.
     * @param currentTile   - Current tile.
     * @param displayColumn - Display column.
     * @return boolean
     */
    private static boolean setTileToColumn(char[][] tileGrid, char currentTile, int displayColumn) {
        int column = displayColumn - 1; // Replaces the "displayColumn" to an index-accessible column.

        // Check which row for the specified column is available.
        for (int row = tileGrid.length - 1; row >= 0; row -= 1) {
            // Checks if the tile is set with anything other than an uppercase letter (strict "null" check).
            if (!Character.isUpperCase(tileGrid[row][column])) {
                tileGrid[row][column] = currentTile;

                // No need to continue the loop.
                return true;
            }
        }

        return false;
    }

    /**
     * Detect and clear out valid set.
     *
     * @param scanner  - Scanner.
     * @param tileGrid - Tile grid.
     */
    private static void detectAndClearOutValidSet(Scanner scanner, char[][] tileGrid) {
        boolean detectedSet = false;

        // Check the tile grid horizontally for matching sets.
        for (int row = 0; row < tileGrid.length; row += 1) {
            for (int column = 0; column < tileGrid[0].length - 2; column += 1) {
                char currentChar = tileGrid[row][column];

                // Don't match "null" characters.
                if (currentChar != (char) (0)) {
                    int consecutiveCount = countConsecutiveCharacters(tileGrid, row, column, currentChar, true);

                    if (consecutiveCount >= 3) {
                        detectedSet = true;

                        // Marks all matching letters horizontally with an asterisk.
                        for (int index = column; index < column + consecutiveCount; index += 1) {
                            tileGrid[row][index] = '*';
                        }
                    }
                }
            }
        }

        // Check the tile grid vertically for matching sets.
        for (int column = 0; column < tileGrid[0].length; column += 1) {
            for (int row = 0; row < tileGrid.length - 2; row += 1) {
                char currentChar = tileGrid[row][column];

                // Don't match "null" characters.
                if (currentChar != (char) (0)) {
                    int consecutiveCount = countConsecutiveCharacters(tileGrid, row, column, currentChar, false);

                    if (consecutiveCount >= 3) {
                        detectedSet = true;

                        // Marks all matching letters vertically with an asterisk.
                        for (int index = row; index < row + consecutiveCount; index += 1) {
                            tileGrid[index][column] = '*';
                        }
                    }
                }
            }
        }

        // If the above checks detect matching sets, this will be triggered.
        if (detectedSet) {
            System.out.println(); // Pad the terminal output.

            printTileGrid(tileGrid);

            System.out.print("You made a set! Enter any word to continue. ");

            // Pause until user submits something (e.g. press enter).
            scanner.nextLine();

            for (int column = 0; column < tileGrid[0].length; column += 1) {
                int asteriskRow = tileGrid.length - 1;

                // If there are no asterisks, the "asteriskRow" will always be the same as "row".
                for (int row = asteriskRow; row >= 0; row -= 1) {
                    // Push the above character down if current tile isn't an asterisk.
                    if (tileGrid[row][column] != '*') {
                        // If the stars are in the middle of the column, this would essentially "re-assign" itself with the same character.
                        // You can check if it's not equal to each other, but why create additional time complexity? It is harmless as is.
                        tileGrid[asteriskRow][column] = tileGrid[row][column];

                        // After replacing the asterisk with the above character, move up.
                        asteriskRow -= 1;
                    }
                }

                // Empty out the upper column with "null" characters.
                for (int row = asteriskRow; row >= 0; row -= 1) {
                    tileGrid[row][column] = (char) (0);
                }
            }
        }
    }

    /**
     * Count consecutive characters.
     *
     * @param tileGrid        - Tile grid.
     * @param row             - Row.
     * @param column          - Column.
     * @param targetCharacter - Target character.
     * @param horizontal      - Horizontal.
     * @return int
     */
    private static int countConsecutiveCharacters(char[][] tileGrid, int row, int column, char targetCharacter, boolean horizontal) {
        int count = 0;

        // I can do if/else, but I'd like to keep things in smaller chunks.
        if (horizontal) {
            while (
                    column < tileGrid[0].length
                            && tileGrid[row][column] == targetCharacter // Makes sure the character matches what we're looking for (targetChar).
            ) {
                count += 1;
                column += 1; // Traverse until the end of the column.
            }
        }

        // I can do if/else, but I'd like to keep things in smaller chunks.
        if (!horizontal) {
            while (
                    row < tileGrid.length
                            && tileGrid[row][column] == targetCharacter // Makes sure the character matches what we're looking for (targetChar).
            ) {
                count += 1;
                row += 1; // Traverse until the end of the row.
            }
        }

        return count;
    }

    /**
     * Print tile grid.
     *
     * @param tileGrid - Tile grid.
     */
    private static void printTileGrid(char[][] tileGrid) {
        // Prints out the header.
        for (int displayColumn = 1; displayColumn <= tileGrid[0].length; displayColumn += 1) {
            System.out.print(" " + colorText("93", String.valueOf(displayColumn)));
        }

        // After printing out the header, insert a new line.
        System.out.println();

        // Now loop through the tile grid, and make it look amazing.
        for (int row = 0; row < tileGrid.length; row += 1) {
            for (int column = 0; column <= tileGrid[row].length; column += 1) {
                if (column == tileGrid[row].length) { // Prevents "ArrayIndexOutOfBoundsException" error.
                    System.out.print("|");
                } else if (Character.isUpperCase(tileGrid[row][column])) { // If the character is an uppercase letter (validity check).
                    System.out.print("|" + tileGrid[row][column]);
                } else if (tileGrid[row][column] == '*') { // If the character is an asterisk (during a valid set print).
                    System.out.print("|" + colorText("95", "*"));
                } else {
                    System.out.print("| ");
                }
            }

            // After printing out the tile grid, insert a new line.
            System.out.println();
        }
    }

    /**
     * Print error message.
     *
     * @param message - Message.
     */
    private static void printErrorMessage(String message) {
        String prefix = colorText("91", "ERROR") + ": ";

        System.out.println(prefix + message + ".");
    }

    /**
     * Color text.
     *
     * @param ansiColorCode - Ansi color code.
     * @param message       - Message.
     * @return String
     */
    private static String colorText(String ansiColorCode, String message) {
        return "\033[" + ansiColorCode + "m" + message + "\033[0m";
    }
}
