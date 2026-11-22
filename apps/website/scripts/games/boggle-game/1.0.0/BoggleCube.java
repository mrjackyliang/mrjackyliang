import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Boggle cube.
 */
public class BoggleCube {
    private final char[] letters;

    /**
     * Boggle cube.
     *
     * @param letters - Letters.
     */
    private BoggleCube(char[] letters) {
        // Each cube must only have 6 letters.
        if (letters.length != 6) {
            throw new IllegalArgumentException("Each cube must only have 6 letters.");
        }

        this.letters = letters;
    }

    /**
     * Get random letter.
     *
     * @return char
     */
    public char getRandomLetter() {
        Random random = new Random();

        return letters[random.nextInt(letters.length)];
    }

    /**
     * Make cubes.
     *
     * @param allLetters - All letters.
     *
     * @return List<BoggleCube>
     */
    public static List<BoggleCube> makeCubes(char[][] allLetters) {
        List<BoggleCube> cubes = new ArrayList<>();

        for (char[] allLetter : allLetters) {
            cubes.add(new BoggleCube(allLetter));
        }

        return cubes;
    }
}
