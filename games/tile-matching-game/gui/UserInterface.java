import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionListener;
import java.util.UUID;

public class UserInterface {
    /**
     * Ask for boolean dialog.
     *
     * @param parentComponent - Parent component.
     * @param message         - Message.
     * @return Boolean
     */
    public static Boolean askForBooleanDialog(Component parentComponent, String message) {
        Utility.printDebugMessage("\"askForBooleanDialog\" - Showing confirm dialog (message: \"" + message + "\")");

        try {
            int result = JOptionPane.showConfirmDialog(
                    parentComponent,
                    message,
                    Utility.getApplicationName(),
                    JOptionPane.YES_NO_OPTION,
                    JOptionPane.QUESTION_MESSAGE,
                    Utility.getLogoIcon()
            );

            // User pressed the "X" button.
            if (result == -1) {
                Utility.printDebugMessage("\"askForBooleanDialog\" - User pressed the \"X\" button");

                return null;
            }

            Utility.printDebugMessage("\"askForBooleanDialog\" - User pressed the \"" + ((result == 0) ? "Yes" : "No") + "\" button");

            // Returns "true" if 0.
            return result == 0;
        } catch (HeadlessException error) {
            Utility.printErrorMessage("\"askForBooleanDialog\" - Confirm dialog cannot be shown in a headless environment");
        }

        return null;
    }

    /**
     * Ask for integer dialog.
     *
     * @param parentComponent - Parent component.
     * @param message         - Message.
     * @return Integer
     */
    public static Integer askForIntegerDialog(Component parentComponent, String message) {
        while (true) {
            Utility.printDebugMessage("\"askForIntegerDialog\" - Showing input dialog (message: \"" + message + "\")");

            try {
                // Casting to "String" is safe here.
                String result = (String) JOptionPane.showInputDialog(
                        parentComponent,
                        message,
                        Utility.getApplicationName(),
                        JOptionPane.QUESTION_MESSAGE,
                        Utility.getLogoIcon(),
                        null,
                        ""
                );

                if (result == null) {
                    Utility.printDebugMessage("\"askForIntegerDialog\" - User pressed the \"Cancel\" or \"X\" button");

                    return null;
                }

                // Try to return the result as an integer.
                try {
                    int parsedInt = Integer.parseInt(result);

                    Utility.printDebugMessage("\"askForIntegerDialog\" - User submitted input (input: " + parsedInt + ")");

                    return parsedInt;
                } catch (NumberFormatException error) {
                    Utility.printErrorMessage("\"askForIntegerDialog\" - User input cannot be converted to an integer");
                }
            } catch (HeadlessException error) {
                Utility.printErrorMessage("\"askForIntegerDialog\" - Input dialog cannot be shown in a headless environment");
            }
        }
    }

    /**
     * Create color tile.
     *
     * @param name      - Name.
     * @param action    - Action.
     * @param color     - Color.
     * @param clickable - Clickable.
     * @param callback  - Callback.
     * @return JButton
     */
    public static JButton createColorTile(String name, String action, Color color, boolean clickable, ActionListener callback) {
        JButton button = new JButton();

        // Name and action strings are required.
        if (name == null || action == null) {
            Utility.printErrorMessage("\"createColorTile\" - A button name and action is required to create a color tile");

            return null;
        }

        // Tile names should be universally unique. Treat them as IDs.
        button.setName(name + "-" + UUID.randomUUID());

        // Set the action ("action||color") and color of the button.
        if (color != null) {
            button.setActionCommand(action + "||" + color.getRGB());
            button.setBackground(color);
            button.setBorder(BorderFactory.createLineBorder(new Color(255, 255, 255, 63), 10));
        } else {
            button.setActionCommand(action + "||" + Color.WHITE.getRGB());
            button.setBackground(Color.WHITE);
            button.setBorder(BorderFactory.createLineBorder(new Color(255, 255, 255, 63), 10));
        }

        // Override the button click event.
        if (clickable && callback != null) {
            button.setEnabled(true);
            button.addActionListener(callback);
        } else {
            button.setEnabled(false);
        }

        button.setOpaque(true);
        button.setSize(100, 100);

        return button;
    }

    /**
     * Create window grid.

     * @param rows    - Rows.
     * @param columns - Columns.
     * @param title   - Title.
     * @return JFrame
     */
    public static JFrame createWindowGrid(int rows, int columns, String title) {
        JFrame frame = new JFrame();

        // Customize the window grid.
        frame.getContentPane().setBackground(new Color(238, 238, 238));
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(new GridLayout(rows, columns, 10, 10));
        frame.setResizable(false);

        // Add title to window.
        if (title == null) {
            frame.setTitle(Utility.getApplicationName());
        } else {
            frame.setTitle(title);
        }

        return frame;
    }

    /**
     * Show error dialog.
     *
     * @param parentComponent - Parent component.
     * @param message         - Message.
     */
    public static void showErrorDialog(Component parentComponent, String message) {
        Utility.printDebugMessage("\"showErrorDialog\" - Showing message dialog (message: \"" + message + "\")");

        try {
            JOptionPane.showMessageDialog(
                    parentComponent,
                    message,
                    Utility.getApplicationName(),
                    JOptionPane.ERROR_MESSAGE,
                    Utility.getLogoIcon()
            );
        } catch (HeadlessException error) {
            Utility.printErrorMessage("\"showErrorDialog\" - Message dialog cannot be shown in a headless environment");
        }
    }

    /**
     * Show information dialog.
     *
     * @param parentComponent - Parent component.
     * @param message         - Message.
     */
    public static void showInformationDialog(Component parentComponent, String message) {
        Utility.printDebugMessage("\"showInformationDialog\" - Showing message dialog (message: \"" + message + "\")");

        try {
            JOptionPane.showMessageDialog(
                    parentComponent,
                    message,
                    Utility.getApplicationName(),
                    JOptionPane.INFORMATION_MESSAGE,
                    Utility.getLogoIcon()
            );
        } catch (HeadlessException error) {
            Utility.printErrorMessage("\"showInformationDialog\" - Message dialog cannot be shown in a headless environment");
        }
    }
}
