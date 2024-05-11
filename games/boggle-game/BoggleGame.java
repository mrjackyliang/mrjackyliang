import java.io.File;
import java.io.FileNotFoundException;
import java.util.*;

/**
 * Boggle game.
 */
public class BoggleGame {
    private final static int BOARD_SIZE = 4;
    private final static int MAX_CUBES = 16;
    private final static int MAX_SCORE = 100;

    private final List<BoggleCube> cubes;
    private final List<BogglePlayer> players;
    private final List<String> words;

    private int currentRound = 0;
    private Character[] currentBoard = new Character[BoggleGame.MAX_CUBES];

    /**
     * Main.
     *
     * @param args - Args.
     */
    public static void main(String[] args) {
        new BoggleGame();
    }

    /**
     * Boggle game.
     */
    private BoggleGame() {
        Scanner systemIn = new Scanner(System.in);

        // Print the game welcome message.
        this.printMessage(1);

        // Create the game properties.
        this.words = this.generateWords();
        this.cubes = this.generateCubes(systemIn);
        this.players = this.generatePlayers(systemIn);

        // Run the game.
        this.processGame(systemIn);

        // Close the scanner at the end of the game.
        systemIn.close();
    }

    /**
     * Process game.
     */
    private void processGame(Scanner scanner) {
        // Print the game begins message.
        this.printMessage(2);

        while (!this.isGameOver()) {
            // Increment the current round.
            this.currentRound += 1;

            // Print the current round message.
            this.printMessage(4);

            // Generate a new board.
            this.currentBoard = this.generateBoard();

            // Print the board.
            this.printBoard();

            // Have each player input their own words.
            for (BogglePlayer player : this.players) {
                this.inputWord(scanner, player);
            }

            // Calculate the score for all players.
            this.calculateUserScores();

            // Print the score for each player.
            for (BogglePlayer player : this.players) {
                System.out.println(player.getName() + ": " + player.getScore());
            }

            // Clear out the words for each player.
            for (BogglePlayer player : this.players) {
                player.clearWords();
            }
        }

        // Print the game over message.
        this.printMessage(3);
    }

    /**
     * Input word.
     *
     * @param scanner - Scanner.
     * @param player  - Player.
     */
    private void inputWord(Scanner scanner, BogglePlayer player) {
        System.out.println(this.colorText(";1", player.getName() + "'s turn! Please enter your words (\"done\" when finished):"));

        while (true) {
            String userInput = scanner.nextLine();

            if (userInput.equals("done")) {
                break;
            }

            // Check if the word is less than 3 letters.
            if (userInput.length() < 3) {
                System.out.println(this.colorText("91", "ERROR") + ": Word must contain at least 3 letters!");

                continue;
            }

            // Check if the word is not all capital letters.
            if (!userInput.matches("[A-Z]+")) {
                System.out.println(this.colorText("91", "ERROR") + ": Words must be in capital letters only!");

                continue;
            }

            // Checks if the letters used in "userInput" does not exist in the cube.
            if (!userInput.chars().allMatch((letter) -> Arrays.asList(this.currentBoard).contains((char) letter))) {
                System.out.println(this.colorText("91", "ERROR") + ": One or more letters chosen is not in the cube!");

                continue;
            }

            // Check if the word has already been used in this round.
            if (player.getWords().contains(userInput)) {
                System.out.println(this.colorText("91", "ERROR") + ": You already used that word this round!");

                continue;
            }

            // Check if the word is not in the dictionary.
            if (!this.words.contains(userInput)) {
                System.out.println(this.colorText("91", "ERROR") + ": Not a word in the dictionary!");

                continue;
            }

            player.addWord(userInput);
        }
    }

    /**
     * Is game over.
     *
     * @return boolean
     */
    private boolean isGameOver() {
        for (BogglePlayer player : this.players) {
            if (player.getScore() >= BoggleGame.MAX_SCORE) {
                return true;
            }
        }

        return false;
    }

    /**
     * Calculate user scores.
     */
    private void calculateUserScores() {
        List<String> theWords = new ArrayList<>();
        List<String> uniqueWords = new ArrayList<>();
        Map<String, Integer> wordCount = new HashMap<>();

        // Collect all the words the players have used.
        for (BogglePlayer player : this.players) {
            theWords.addAll(player.getWords());
        }

        // Count the amount of words used.
        for (String theWord : theWords) {
            // "wordCount.getOrDefault()" gets the value using the key. If the key does not exist, it will use "0" as the value.
            wordCount.put(theWord, wordCount.getOrDefault(theWord, 0) + 1);
        }

        // Check if each word has been used only once.
        for (Map.Entry<String, Integer> entry : wordCount.entrySet()) {
            if (entry.getValue() == 1) { // Value is the amount of times a word has been used.
                uniqueWords.add(entry.getKey()); // Key is the word itself.
            }
        }

        // Loop through all the players and check if their word exists in "uniqueWords".
        for (BogglePlayer player : this.players) {
            List<String> playerWords = player.getWords();

            // Check if the word exists in "uniqueWords", then score the word length based on the Fibonacci sequence.
            for (String playerWord : playerWords) {
                if (!uniqueWords.contains(playerWord)) {
                    continue;
                }

                player.addPoints(calculateFibonacci(playerWord.length()));
            }
        }
    }

    /**
     * Calculate fibonacci.
     *
     * @param wordLength - Word length.
     *
     * @return int
     */
    private int calculateFibonacci(int wordLength) {
        // The sequence starts counting at the 3rd letter instead.
        wordLength = wordLength - 2;

        double sqrt = Math.sqrt(wordLength);
        double a = 1 / sqrt;
        double b = (1 + sqrt) / 2;
        double c = (1 - sqrt) / 2;

        return (int) Math.round(a * (Math.pow(b, wordLength) - Math.pow(c, wordLength)));
    }

    /**
     * Generate board.
     *
     * @return Character[]
     */
    private Character[] generateBoard() {
        Character[] newBoard = new Character[BoggleGame.MAX_CUBES];

        // Shuffle the cubes.
        Collections.shuffle(this.cubes);

        // Get a random letter from each cube, and assign it to the new board.
        for (int cube = 0; cube < BoggleGame.MAX_CUBES; cube += 1) {
            newBoard[cube] = this.cubes.get(cube).getRandomLetter();
        }

        return newBoard;
    }

    /**
     * Generate cubes.
     *
     * @param scanner - Scanner.
     *
     * @return List<BoggleCube>
     */
    private List<BoggleCube> generateCubes(Scanner scanner) {
        int currentCube = 0;
        char[][] acceptedInputs = new char[BoggleGame.MAX_CUBES][6];

        // Create only "BoggleGame.MAX_CUBES" cubes with the allowed characters.
        while (currentCube < BoggleGame.MAX_CUBES) {
            String userInput;

            System.out.print(this.colorText("95", "Cube #" + (currentCube + 1)) + " (enter ONLY 6 uppercase letters): ");
            userInput = scanner.nextLine();

            // Check if the user input is not valid.
            if (!userInput.matches("^[A-Z]{6}$")) {
                System.out.println(this.colorText("91", "ERROR") + ": Invalid cube input.");

                continue;
            }

            // Convert the validated string to a character array.
            acceptedInputs[currentCube] = userInput.toCharArray();

            // Increment the cube (index) so the while loop doesn't go on forever.
            currentCube += 1;
        }

        return BoggleCube.makeCubes(acceptedInputs);
    }

    /**
     * Generate words.
     *
     * @return List<String>
     */
    private List<String> generateWords() {
        List<String> words = new ArrayList<>();

        try {
            File wordsFile = new File("words.txt");
            Scanner wordsFileInput = new Scanner(wordsFile);

            while (wordsFileInput.hasNextLine()) {
                String word = wordsFileInput.nextLine();

                // The string must ONLY include capital letters and a length of 3 letters or more.
                if (word.matches("^[A-Z]+$") && word.length() >= 3) {
                    words.add(word);
                }
            }

            // Close the scanner after importing the words.
            wordsFileInput.close();
        } catch (FileNotFoundException error) {
            System.out.println(this.colorText("91", "ERROR") + ": The \"words.txt\" file is not found.");

            // Anytime a program is exited with a non-zero status, it means there is an error.
            System.exit(1);
        }

        return words;
    }

    /**
     * Generate players.
     *
     * @param scanner - Scanner.
     *
     * @return List<BogglePlayer>
     */
    private List<BogglePlayer> generatePlayers(Scanner scanner) {
        List<BogglePlayer> players = new ArrayList<>();
        int playerAmount = 0;

        // Ask for the number of players and validate it.
        while (playerAmount < 2) {
            System.out.print(this.colorText("95", "Enter number of players") + " (2 or more): ");

            try {
                playerAmount = scanner.nextInt();

                // Only allow the game to be played with 2 or more players.
                if (playerAmount == 1) {
                    System.out.println(this.colorText("91", "ERROR") + ": You can't play Boggle by yourself!");
                } else if (playerAmount < 1) {
                    System.out.println(this.colorText("91", "ERROR") + ": Invalid player amount.");
                }
            } catch (InputMismatchException error) {
                System.out.println(this.colorText("91", "ERROR") + ": Failed to parse integer.");
            }

            // Throw out the rest of the buffer.
            scanner.nextLine();
        }

        // Ask for the player names and create a list of Boggle players.
        while (players.size() < playerAmount) {
            String userInput;

            System.out.print(this.colorText("95", "Enter Player " + (players.size() + 1) + "'s name") + " (no spaces): ");
            userInput = scanner.next();

            // Check if the user input is valid.
            if (userInput.matches("\\s+")) {
                System.out.println(this.colorText("91", "ERROR") + ": No spaces are allowed.");

                continue;
            }

            players.add(new BogglePlayer(userInput));

            // Throw out the rest of the buffer.
            scanner.nextLine();
        }

        return players;
    }

    /**
     * Print message.
     *
     * @param type - Type.
     */
    private void printMessage(int type) {
        switch (type) {
            case 1:
                System.out.println(this.colorText("96", "Welcome to the Boggle Game!"));
                break;
            case 2:
                System.out.println(this.colorText("92", "GAME BEGINS"));
                break;
            case 3:
                System.out.println(this.colorText("91", "GAME OVER"));
                break;
            case 4:
                System.out.println(this.colorText("93", "ROUND " + this.currentRound));
                break;
            default:
                break;
        }
    }

    /**
     * Print board.
     */
    private void printBoard() {
        for (int index = 0; index < BoggleGame.MAX_CUBES; index += 1) {
            System.out.print(this.currentBoard[index] + " ");

            // Shift to the next line.
            if (index != 0 && (index + 1) % (BoggleGame.BOARD_SIZE) == 0) {
                System.out.println();
            }
        }
    }

    /**
     * Color text.
     *
     * @param ansiColorCode - Ansi color code.
     * @param message       - Message.
     * @return String
     */
    private String colorText(String ansiColorCode, String message) {
        return "\033[" + ansiColorCode + "m" + message + "\033[0m";
    }
}
