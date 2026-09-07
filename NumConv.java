// 2. Build a number-base converter supporting binary, decimal, octal, and hexadecimal.
import java.util.Scanner;

public class NumConv {

    // converts character to numerical value
    public static int charToValue(char digit) {
        if (digit >= '0' && digit <= '9') {
            return digit - '0';
        } else if (digit >= 'A' && digit <= 'F') {
            return digit - 'A' + 10;
        }

        return -1;
    }

    // converts numerical value to character rep
    public static char valueToChar(int value) {
        if (value >= 0 && value <= 9) {
            return (char) ('0' + value);
        } else {
            return (char) ('A' + value - 10);
        }
    }

    // checks if given base is supported
    public static boolean isValidBase(int base) {
        return base == 2 || base == 8 || base == 10 || base == 16;
    }

    // checks if every digit in number is valid for given base
    public static boolean isValidNumber(String number, int base) {
        if (number.isEmpty()) {
            return false;
        }

        for (int i = 0; i < number.length(); i++) {
            int value = charToValue(number.charAt(i));

            if (value < 0 || value >= base) {
                return false;
            }
        }

        return true;
    }

    // converts a number from original base into decimal
    public static long toDecimal(String number, int base) {
        long decimal = 0;

        for (int i = 0; i < number.length(); i++) {
            int digitValue = charToValue(number.charAt(i));

            decimal = decimal * base + digitValue;
        }

        return decimal;
    }

    // converts  decimal number into desired base
    public static String fromDecimal(long decimal, int base) {
        if (decimal == 0) {
            return "0";
        }

        StringBuilder result = new StringBuilder();

        while (decimal > 0) {
            int remainder = (int) (decimal % base);

            result.append(valueToChar(remainder));

            decimal /= base;
        }

        return result.reverse().toString();
    }


    public static void main(String[] args) {
        // create Scanner
        Scanner input = new Scanner(System.in);

        // ask for number
        System.out.print("Enter number: ");
        String number = input.nextLine().trim().toUpperCase();

        // ask for original base
        System.out.print("Enter current base for number(2, 8, 10, or 16): ");
        int originalBase = input.nextInt();

        // Ask for desired base
        System.out.print("Enter desired base for number(2, 8, 10, or 16): ");
        int desiredBase = input.nextInt();

        // check that both bases are supported
        if (!isValidBase(originalBase) || !isValidBase(desiredBase)) {
            System.out.println("Error: The base must be 2, 8, 10, or 16.");

        // check that the number is valid in its original base
        } else if(!isValidNumber(number, originalBase)) {
            System.out.println("Error: " + number + " is not valid in base " + originalBase + ".");

        // convert the original number to decimal, convert decimal to desire base, and display result
        } else{
            long decimalValue = toDecimal(number, originalBase);
            String result = fromDecimal(decimalValue, desiredBase);
            System.out.println(number + " in base " + originalBase + " is " + result + " in base " + desiredBase + ".");
        }

        input.close();
    }
}
