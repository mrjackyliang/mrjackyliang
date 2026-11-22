import java.io.File;
import java.io.FileNotFoundException;
import java.util.*;

/**
 * Pangram maker.
 */
public class PangramMaker {
    /**
     * Main.
     *
     * @param argv - Argv.
     */
    public static void main(String[] argv) {
        String completedPangram;
        ArrayList<String> words = new ArrayList<>();

        importAndInitialize(words);
        printIntro();
        completedPangram = makePangram(words);
        printResults(completedPangram);
    }

    /**
     * Import and initialize.
     *
     * @param words - Words.
     */
    private static void importAndInitialize(ArrayList<String> words) {
        try {
            File wordsFile = new File("words.txt");
            Scanner input = new Scanner(wordsFile);

            while (input.hasNextLine()) {
                String word = input.nextLine();

                // The string must ONLY include capital letters. If it does not match the regex, do not add.
                // The included file doesn't seem to have such issues, but good to have.
                if (word.matches("^[A-Z]+$")) {
                    words.add(word);
                } else {
                    System.out.println(colorText("93", "WARNING") + ": The \"" + word + "\" word is not all capital letters. Skipping ...");
                }
            }

            // Close the scanner after importing the words.
            input.close();

            // If the words list does not contain the letter "A", add it in.
            if (!words.contains("A")) {
                words.add("A");
            }

            // If the words list does not contain the letter "I", add it in.
            if (!words.contains("I")) {
                words.add("I");
            }
        } catch (FileNotFoundException error) {
            System.out.println(colorText("91", "ERROR") + ": The \"words.txt\" file is not found.");

            // Anytime a program is exited with a non-zero status, it means there is an error.
            System.exit(1);
        }
    }

    /**
     * Make pangram.
     *
     * @param words - Words.
     * @return String
     */
    private static String makePangram(ArrayList<String> words) {
        boolean[] alphabetLettersUsed = new boolean[26]; // Initializes with no alphabet letters used.
        Scanner scanner = new Scanner(System.in);
        StringBuilder pangram = new StringBuilder();

        while (!isAllAlphabetLettersUsed(alphabetLettersUsed)) {
            System.out.println("\nYour pangram so far is: " + colorText("94", String.valueOf(pangram)));
            System.out.print("Enter the next word (in all uppercase) or enter help for suggestions: ");

            String input = scanner.nextLine();

            // If the input is not a valid word and user is not looking for suggestions.
            if (!words.contains(input) && !input.equals("help")) {
                System.out.println(colorText("93", "That's not a valid word!"));

                continue;
            }

            // If user is looking for suggestions.
            if (input.equals("help")) {
                printSuggestions(words, alphabetLettersUsed);

                continue;
            }

            // Loop through the "alphabetLettersUsed" for checking against the input string.
            for (int i = 0; i < alphabetLettersUsed.length; i += 1) {
                // Check if the alphabet letter is not used and if the input contains the alphabet letter.
                if (!alphabetLettersUsed[i] && input.contains(String.valueOf((char) ('A' + i)))) {
                    alphabetLettersUsed[i] = true;
                }
            }

            // Inject the input into the pangram.
            pangram.append(input).append(" ");
        }

        // Close the scanner when the pangram is created.
        scanner.close();

        return pangram.toString();
    }

    /**
     * Is all alphabet letters used.
     *
     * @param lettersUsed - Letters used.
     * @return boolean
     */
    private static boolean isAllAlphabetLettersUsed(boolean[] lettersUsed) {
        for (boolean letterUsed : lettersUsed) {
            // If a letter is used, the value corresponding to that index should be "true".
            if (!letterUsed) {
                return false;
            }
        }

        return true;
    }

    /**
     * Count unused distinct letters.
     *
     * @param word - Word.
     * @param alphabetLettersUsed - Alphabet letters used.
     * @return int
     */
    private static int countUnusedDistinctLetters(String word, boolean[] alphabetLettersUsed) {
        LinkedHashSet<Character> uniqueCharacters = new LinkedHashSet<>();

        for (int i = 0; i < word.length(); i += 1) {
            /*
             REMINDER
             i == (int) ('A' + i - 65).

             The 'A' character is now index 0, not 65 (like the ASCII table index).
             The 'Z' character is now index 25, not 90 (like the ASCII table index).
            */
            int characterIndex = word.charAt(i) - 65;

            // Check if the letter is not used.
            if (!alphabetLettersUsed[characterIndex]) {
                // Adding to a set. This will ignore any duplicate characters.
                uniqueCharacters.add(word.charAt(i));
            }
        }

        return uniqueCharacters.size();
    }

    /**
     * Print suggestions.
     *
     * @param words - Words.
     * @param alphabetLettersUsed - Alphabet letters used.
     */
    private static void printSuggestions(ArrayList<String> words, boolean[] alphabetLettersUsed) {
        Random random = new Random();
        ArrayList<SuggestionPair> pairs = new ArrayList<>();

        // First find out the unused letters for each word.
        for (String word : words) {
            pairs.add(new SuggestionPair(countUnusedDistinctLetters(word, alphabetLettersUsed), word));
        }

        // Sort the pairs in descending order based on the "unusedDistinctLetters".
        pairs.sort(Comparator.comparingInt(SuggestionPair::unusedDistinctLetters).reversed());

        // Truncate the pairs if the size is greater than 5.
        if (pairs.size() > 5) {
            pairs = new ArrayList<>(pairs.subList(0, 5));
        } else {
            int amountOfWordsToFill = 5 - pairs.size(); // If size is 5, the for loop won't run.

            // Find a random word to fill the "pairs.size()" to 5.
            for (int i = 0; i < amountOfWordsToFill; i += 1) {
                int randomIndex = random.nextInt(words.size());
                String randomWord = words.get(randomIndex);

                pairs.add(new SuggestionPair(countUnusedDistinctLetters(randomWord, alphabetLettersUsed), randomWord));
            }
        }

        // Randomize the pairs.
        Collections.shuffle(pairs);

        // Display the randomized pairs.
        for (SuggestionPair pair : pairs) {
            System.out.println(pair.word);
        }
    }

    /**
     * Print intro.
     */
    private static void printIntro() {
        System.out.println("Welcome to Pangram Maker!");
    }

    /**
     * Print results.
     *
     * @param completedPangram - Completed pangram.
     */
    private static void printResults(String completedPangram) {
        String[] words = completedPangram.split(" "); // Uses regex to match a single space.
        int letters = 0;

        // Adds the length of each word from the exploded string.
        for (String word : words) {
            letters += word.length();
        }

        System.out.println(colorText("92", "Your pangram is complete!"));
        System.out.println(colorText("94", completedPangram));
        System.out.println(colorText("95", "Total Words") + ": " + words.length);
        System.out.println(colorText("95", "Total Letters") + ": " + letters);
    }

    /**
     * Color text.
     *
     * @param ansiColorCode - Ansi color code.
     * @param message - Message.
     * @return String
     */
    private static String colorText(String ansiColorCode, String message) {
        return "\033[" + ansiColorCode + "m" + message + "\033[0m";
    }

    /**
     * Suggestion pair.
     *
     * @param unusedDistinctLetters - Unused distinct letters.
     * @param word - Word.
     */
    private record SuggestionPair(int unusedDistinctLetters, String word) {}
}
