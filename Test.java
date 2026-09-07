// 5. Test boundary cases, including zero, the largest supported unsigned value, and at least one negative two's-complement value.

public class Test {

    // interprets a 32-bit unsigned value as a signed
    // two's-complement value
    public static long toSigned32Bit(long unsignedValue) {
        if (unsignedValue >= 2147483648L) {
            return unsignedValue - 4294967296L;
        }

        return unsignedValue;
    }

    public static void main(String[] args) {

        // test zero
        String zero = NumConv.fromDecimal(
                NumConv.toDecimal("0", 10), 2
        );

        System.out.println("Zero: " + zero);
        System.out.println("Expected: 0");
        System.out.println();

        // test the largest 32-bit unsigned value
        String largestUnsigned = NumConv.fromDecimal(
                NumConv.toDecimal("4294967295", 10), 16
        );

        System.out.println("Largest unsigned: " + largestUnsigned);
        System.out.println("Expected: FFFFFFFF");
        System.out.println();

        // test -1 represented using 32-bit two's complement
        long negativeOneBits = NumConv.toDecimal(
                "11111111111111111111111111111111", 2
        );

        long negativeOne = toSigned32Bit(negativeOneBits);

        System.out.println("Signed value: " + negativeOne);
        System.out.println("Expected: -1");
        System.out.println();

        // test the smallest signed 32-bit value
        long minimumBits = NumConv.toDecimal(
                "10000000000000000000000000000000", 2
        );

        long minimumValue = toSigned32Bit(minimumBits);

        System.out.println("Minimum signed value: " + minimumValue);
        System.out.println("Expected: -2147483648");
    }
}
