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
            String input;

            System.out.println("\nYour pangram so far is: " + colorText("94", String.valueOf(pangram)));
            System.out.print("Enter the next word (in all uppercase) or enter help for suggestions: ");

            input = scanner.nextLine();

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
     * Count unique letters.
     *
     * @param word                - Word.
     * @param alphabetLettersUsed - Alphabet letters used.
     * @return int
     */
    private static int countUniqueLetters(String word, boolean[] alphabetLettersUsed) {
        Set<Character> uniqueLetters = new HashSet<>();

        for (int i = 0; i < word.length(); i += 1) {
        /*
         REMINDER
         i == (int) ('A' + i - 65).

         The 'A' character is now index 0, not 65 (like the ASCII table index).
         The 'Z' character is now index 25, not 90 (like the ASCII table index).
        */
            char currentCharacter = word.charAt(i);
            int characterIndex = currentCharacter - 65;

            // Check if the letter is not used.
            if (!alphabetLettersUsed[characterIndex]) {
                // Adding to a set. This will ignore any duplicate characters.
                uniqueLetters.add(currentCharacter);
            }
        }
        return uniqueLetters.size();
    }

    /**
     * Get suggestions.
     *
     * @param words               - Words.
     * @param alphabetLettersUsed - Alphabet letters used.
     * @return ArrayList<String>
     */
    private static ArrayList<String> getSuggestions(ArrayList<String> words, boolean[] alphabetLettersUsed) {
        int largestUniqueLetters = 0;
        ArrayList<String> suggestions = new ArrayList<>();

        for (String word : words) {
            int numberOfUniqueLetters = countUniqueLetters(word, alphabetLettersUsed);

            // If a larger unique letters in a word is found, reset the current suggestions.
            // Significantly improves time complexity since you will only need to go through the loop once.
            if (numberOfUniqueLetters > largestUniqueLetters) {
                largestUniqueLetters = numberOfUniqueLetters;

                // No need to check the size (creates additional operations).
                suggestions.clear();
            }

            // Check required, because without it, anything smaller would print out.
            if (numberOfUniqueLetters == largestUniqueLetters) {
                suggestions.add(word);
            }
        }

        return suggestions;
    }

    /**
     * Print suggestions.
     *
     * @param words               - Words.
     * @param alphabetLettersUsed - Alphabet letters used.
     */
    private static void printSuggestions(ArrayList<String> words, boolean[] alphabetLettersUsed) {
        Random random = new Random();
        ArrayList<String> suggestions = getSuggestions(words, alphabetLettersUsed);

        // If there are more than 5 suggestions, randomly pick 5 unique ones.
        if (suggestions.size() > 5) {
            Set<String> randomSuggestions = new HashSet<>();

            while (randomSuggestions.size() < 5) {
                int randomIndexFromSuggestions = random.nextInt(suggestions.size());
                String randomWord = suggestions.get(randomIndexFromSuggestions);

                // Adding to a set. This will ignore any duplicate strings.
                randomSuggestions.add(randomWord);
            }

            // Clear and replace the suggestions with random suggestions.
            suggestions.clear();
            suggestions.addAll(randomSuggestions);
        } else {
            // If suggestion size is 5, the loop below won't run (e.g. 5 - 5 = 0).
            int amountOfWordsToFill = 5 - suggestions.size();

            // Find a random word to fill the "pairs.size()" to 5.
            for (int i = 0; i < amountOfWordsToFill; i += 1) {
                int randomIndexFromWords = random.nextInt(words.size());
                String randomWord = words.get(randomIndexFromWords);

                suggestions.add(randomWord);
            }

            // Now, randomize the current suggestions.
            Collections.shuffle(suggestions);
        }

        // Remember, suggestions is already randomized above. No need to do again.
        for (String suggestion : suggestions) {
            System.out.println(suggestion);
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
     * @param message       - Message.
     * @return String
     */
    private static String colorText(String ansiColorCode, String message) {
        return "\033[" + ansiColorCode + "m" + message + "\033[0m";
    }
}
