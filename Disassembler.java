import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;

/** Collaboration: developed with OpenAI ChatGPT assistance. */

/** Decodes real instructions; labels are generated from instruction addresses. */
public class Disassembler {
    private static final String[] REGS = {
        "$zero", "$at", "$v0", "$v1", "$a0", "$a1", "$a2", "$a3",
        "$t0", "$t1", "$t2", "$t3", "$t4", "$t5", "$t6", "$t7",
        "$s0", "$s1", "$s2", "$s3", "$s4", "$s5", "$s6", "$s7",
        "$t8", "$t9", "$k0", "$k1", "$gp", "$sp", "$fp", "$ra"
    };

    public static void main(String[] args) {
        if (args.length != 2) {
            System.err.println("Usage: java Disassembler input.mhc-ascii|input.mhc-bin output.asm");
            System.exit(1);
        }
        try {
            Assembler.Result input = MachineCodeFile.read(Paths.get(args[0]));
            String source = disassemble(input);
            // Check before saving: decoded text must reproduce EVERY payload byte.
            Assembler.Result rebuilt = Assembler.assemble(source);
            if (!Arrays.equals(input.text, rebuilt.text) || !Arrays.equals(input.data, rebuilt.data))
                throw new IllegalArgumentException("Round-trip verification failed.");
            Files.write(Paths.get(args[1]), source.getBytes(StandardCharsets.UTF_8));
            System.out.println("Created " + args[1]);
            System.out.println("PASS: reassembly reproduces all instruction and data bytes.");
        } catch (IOException | IllegalArgumentException e) {
            System.err.println("Disassembly failed: " + e.getMessage());
            System.exit(1);
        }
    }

    static String disassemble(Assembler.Result result) {
        StringBuilder source = new StringBuilder();
        source.append("# Reconstructed from MHC1 machine code. Run with delayed branching OFF.\n");
        source.append(".data 0x10010000\n");
        // .byte preserves zeros and non-printable bytes without interpreting data as code.
        for (int i = 0; i < result.data.length; i += 16) {
            source.append("    .byte ");
            for (int j = i; j < Math.min(i + 16, result.data.length); j++) {
                if (j != i) source.append(", ");
                source.append(result.data[j] & 255);
            }
            source.append('\n');
        }
        source.append("\n.text 0x00400000\n.globl main\nmain:\n");
        for (int i = 0; i < result.text.length; i += 4) {
            int pc = Assembler.TEXT_BASE + i;
            source.append(label(pc)).append(":\n    ");
            source.append(decode(MachineCodeFile.word(result.text, i), pc, result.text.length));
            source.append('\n');
        }
        return source.toString();
    }

    private static String label(int address) { return "L" + Assembler.hex(address); }

    private static String target(int address, int textSize) {
        long offset = (long) address - Assembler.TEXT_BASE;
        if (offset < 0 || offset >= textSize || offset % 4 != 0)
            throw new IllegalArgumentException("Control-flow target outside .text: 0x" + Assembler.hex(address));
        return label(address);
    }

    static String decode(int word, int pc, int textSize) {
        int op = word >>> 26, rs = (word >>> 21) & 31, rt = (word >>> 16) & 31;
        int rd = (word >>> 11) & 31, shamt = (word >>> 6) & 31, fn = word & 63;
        int unsigned = word & 65535, signed = (short) unsigned;
        String a = REGS[rs], b = REGS[rt], d = REGS[rd];
        if (op == 0) {
            switch (fn) {
                case 0: if (rs == 0) return "sll " + d + ", " + b + ", " + shamt; break;
                case 8: if (rt == 0 && rd == 0 && shamt == 0) return "jr " + a; break;
                case 12: if (word == 12) return "syscall"; break;
                case 16: if (rs == 0 && rt == 0 && shamt == 0) return "mfhi " + d; break;
                case 26: if (rd == 0 && shamt == 0) return "div " + a + ", " + b; break;
                case 32: case 33: case 34:
                    if (shamt == 0) return (fn == 32 ? "add " : fn == 33 ? "addu " : "sub ")
                        + d + ", " + a + ", " + b;
                    break;
            }
        } else {
            switch (op) {
                case 2: case 3:
                    int address = ((pc + 4) & 0xF0000000) | ((word & 0x03FFFFFF) << 2);
                    return (op == 2 ? "j " : "jal ") + target(address, textSize);
                case 4: case 5:
                    return (op == 4 ? "beq " : "bne ") + a + ", " + b + ", "
                        + target(pc + 4 + signed * 4, textSize);
                case 8: case 9:
                    return (op == 8 ? "addi " : "addiu ") + b + ", " + a + ", " + signed;
                case 13: return "ori " + b + ", " + a + ", " + unsigned;
                case 15: if (rs == 0) return "lui " + b + ", " + unsigned; break;
                case 35: case 43:
                    return (op == 35 ? "lw " : "sw ") + b + ", " + signed + "(" + a + ")";
            }
        }
        throw new IllegalArgumentException("Unsupported/invalid instruction 0x" + Assembler.hex(word)
            + " at 0x" + Assembler.hex(pc));
    }
}
