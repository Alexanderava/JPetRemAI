// PanelPatcher.java — 字节码 patch MultiSelectPlugin.showControlPanel() → return
// 用 JDK 内置 ASM (jdk.internal.org.objectweb.asm)

import java.io.*;
import java.nio.file.*;

public class PanelPatcher {
    public static void main(String[] args) throws Exception {
        Path in = Paths.get(args[0]);
        Path out = Paths.get(args.length > 1 ? args[1] : args[0]);
        byte[] bytes = Files.readAllBytes(in);
        
        // 手动修改：在类文件中找 "showControlPanel" 方法，把方法体改成 return
        // 方法名在常量池，我们需要找到方法并patch其Code属性
        
        // 简单方案：在类bytes中找方法名，然后用空方法体替换
        String target = "showControlPanel";
        byte[] targetBytes = target.getBytes("UTF-8");
        
        int pos = indexOf(bytes, targetBytes);
        if (pos < 0) {
            System.out.println("NOT FOUND in " + in);
            System.exit(1);
        }
        System.out.println("Found showControlPanel at byte offset: " + pos);
        
        // 在常量池中已经找到了方法名引用
        // 我们需要找到实际的 method_info 以及 Code 属性
        // 简化方案：在整个类中搜索该方法的所有引用，然后在method表里定位
        
        // 更简单的方案：把方法名改成 'xxxDisabled_Nopxx' (同长度)
        byte[] replacement = "xxxDisabled_Nopxx".getBytes("UTF-8");
        if (replacement.length != targetBytes.length) {
            System.out.println("Length mismatch, padding...");
            replacement = new byte[targetBytes.length];
            System.arraycopy("xxxDisabledNop".getBytes("UTF-8"), 0, replacement, 0, Math.min(16, targetBytes.length));
        }
        
        // 替换所有出现
        int count = 0;
        int idx = 0;
        while ((idx = indexOf(bytes, targetBytes, idx)) >= 0) {
            System.arraycopy(replacement, 0, bytes, idx, targetBytes.length);
            idx += targetBytes.length;
            count++;
        }
        
        Files.write(out, bytes);
        System.out.println("Patched " + count + " occurrences in " + out + " (" + bytes.length + " bytes)");
    }
    
    static int indexOf(byte[] haystack, byte[] needle) {
        return indexOf(haystack, needle, 0);
    }
    
    static int indexOf(byte[] haystack, byte[] needle, int start) {
        outer:
        for (int i = start; i <= haystack.length - needle.length; i++) {
            for (int j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) continue outer;
            }
            return i;
        }
        return -1;
    }
}
