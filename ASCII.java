// 1. Build an ASCII-to-decimal converter.

public class ASCII {
    public static void main(String[] args) {
        String s = "Kayla";

        for(Character c : s.toCharArray()){
            System.out.println((int)c);
        }
    }
}