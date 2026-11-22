import java.util.ArrayList;
import java.util.List;

/**
 * Boggle player.
 */
public class BogglePlayer {
    private final String name;
    private final List<String> usedWords;
    private int points;

    /**
     * Boggle player.
     *
     * @param name - Name.
     */
    public BogglePlayer(String name) {
        this.name = name;
        this.usedWords = new ArrayList<>();
        this.points = 0;
    }

    /**
     * Get name.
     *
     * @return String
     */
    public String getName() {
        return this.name;
    }

    /**
     * Add points.
     *
     * @param points - Points.
     */
    public void addPoints(int points) {
        this.points += points;
    }

    /**
     * Get score.
     *
     * @return int
     */
    public int getScore() {
        return this.points;
    }

    /**
     * Add word.
     *
     * @param word - Word.
     */
    public void addWord(String word) {
        this.usedWords.add(word);
    }

    /**
     * Get words.
     *
     * @return List<String>
     */
    public List<String> getWords() {
        return this.usedWords;
    }

    /**
     * Clear words.
     */
    public void clearWords() {
        this.usedWords.clear();
    }
}
