// ControlPanelSuppressor.java
// Java Agent — 在类加载时修改 MultiSelectPlugin.showControlPanel 为空方法
// 比字节码 patch 更干净、更可维护

import java.lang.instrument.*;
import java.security.ProtectionDomain;

public class ControlPanelSuppressor {

    public static void premain(String agentArgs, Instrumentation inst) {
        System.out.println("[Agent] 控制面板抑制器已加载");
        inst.addTransformer(new ClassFileTransformer() {
            public byte[] transform(ClassLoader loader, String className,
                                     Class<?> classBeingRedefined,
                                     ProtectionDomain protectionDomain,
                                     byte[] classfileBuffer) {
                if (className == null) return null;

                // 只处理 MultiSelectPlugin
                if (!className.equals("com/group_finity/mascot/plugin/MultiSelectPlugin")) {
                    return null;
                }

                System.out.println("[Agent] 拦截 MultiSelectPlugin — 改造 showControlPanel");

                // 方案：修改常量池中 "showControlPanel" 字符串长度
                // 将长度 16 改为 0（变成空字符串方法名），使调用无法匹配
                // 这样调用方会得到 NoSuchMethodError 但被 catch 掉

                byte[] newBytes = classfileBuffer.clone();
                String target = "showControlPanel";
                byte[] targetBytes = target.getBytes();

                // 先找长度前缀（u2: 0x00 0x10 然后是 "showControlPanel"）
                byte[] prefix = new byte[3]; // [tag=0x01][len_hi][len_lo]
                prefix[0] = 0x01; // CONSTANT_Utf8 tag
                prefix[1] = 0x00;
                prefix[2] = 0x10; // length = 16

                int foundCount = 0;
                for (int i = 0; i < newBytes.length - targetBytes.length - 3; i++) {
                    if (newBytes[i] == prefix[0] &&
                        newBytes[i+1] == prefix[1] &&
                        newBytes[i+2] == prefix[2]) {
                        // Check if bytes after length match target
                        boolean match = true;
                        for (int j = 0; j < targetBytes.length; j++) {
                            if (newBytes[i+3+j] != targetBytes[j]) {
                                match = false;
                                break;
                            }
                        }
                        if (match) {
                            // Change length to 0 → method name becomes empty
                            newBytes[i+2] = 0x00;
                            foundCount++;
                            System.out.println("[Agent]   NOP'd showControlPanel at offset " + i);
                        }
                    }
                }

                if (foundCount > 0) {
                    System.out.println("[Agent] MultiSelectPlugin 已改造 (" + foundCount + " 处)");
                    return newBytes;
                }

                return null;
            }
        });
    }

    public static void agentmain(String agentArgs, Instrumentation inst) {
        premain(agentArgs, inst);
    }
}
