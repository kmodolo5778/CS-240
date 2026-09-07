// 4. Write a program that consumes pixel values and creates an image.
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import javax.imageio.ImageIO;
import java.io.File;

public class PixValToImage {

    public static Color convert(String code) {
        if (code.equals("R")) {
            return new Color(237, 28, 36);
        } else if (code.equals("B")) {
            return new Color(0, 0, 0);
        } else if (code.equals("Y")) {
            return new Color(255, 242, 0);
        } else {
            throw new IllegalArgumentException("Unknown color code: " + code);
        }
    }

    public static void main(String[] args) throws IOException {
        List<String> lines =
                Files.readAllLines(Path.of("awesome_picture.txt"));

        int height = lines.size();
        int width = lines.get(0).trim().split("\\s+").length;

        BufferedImage image =
                new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);

        for (int y = 0; y < height; y++) {
            String[] pixels = lines.get(y).trim().split("\\s+");

            for (int x = 0; x < width; x++) {
                String pixel = pixels[x];
                Color color = convert(pixel);

                image.setRGB(x, y, color.getRGB());
            }
        }

        ImageIO.write(image, "png", new File("smiley2.png"));
    }
}
