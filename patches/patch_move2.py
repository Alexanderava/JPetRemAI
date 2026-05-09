import subprocess
import os
import shutil

# We will start from a clean copy of the currently running MultiSelectPlugin
# Wait, I already added `tmpComboRef` to it. That's fine.
# But wait, my previous javassist modification:
# `var15.add(var32, "Center")` -> I replaced it to set tmpComboRef and NOT add it.
# So it's not added to var15.
# And I replaced `var59.add(var30)` to also add `tmpComboRef`.
# Why didn't it show up?
# Because `var59` is a `LiquidGlassPanel`, and its layout might not show it properly?
# Or because `var32` has `setOpaque(false)` and `setBorder(null)` and `putClientProperty("JComboBox.buttonType", "none")` which makes it invisible if it's not in the center of a BorderLayout?
# Actually, the original code had:
# var32.setOpaque(false);
# var32.setBorder(BorderFactory.createEmptyBorder());
# var32.putClientProperty("JComboBox.buttonType", "none");
# So it looks like a flat text field without the combo box styling!
# And it was placed in `var15` (BorderLayout.CENTER), which made it expand.
# If we put it in `var59` (FlowLayout), it might have 0 width or just not render properly!
# Let's undo `putClientProperty("JComboBox.buttonType", "none")` and set a preferred size so it shows up!

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class ChatPatchMove2 {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
        
        CtMethod m = cc.getDeclaredMethod("buildChatPanel");
        
        m.instrument(new javassist.expr.ExprEditor() {
            public void edit(javassist.expr.MethodCall mc) throws CannotCompileException {
                // Remove the buttonType none
                if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("putClientProperty") && mc.getSignature().equals("(Ljava/lang/Object;Ljava/lang/Object;)V")) {
                    mc.replace("{ if ($1.equals(\\"JComboBox.buttonType\\") && $2.equals(\\"none\\")) { /* do nothing */ } else { $proceed($$); } }");
                }
                // Set preferred size so it shows up in FlowLayout
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setOpaque")) {
                    mc.replace("{ $0.setPreferredSize(new java.awt.Dimension(200, 26)); $0.setOpaque(true); }");
                }
                // Also give it a border
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setBorder")) {
                    mc.replace("{ $0.setBorder(javax.swing.BorderFactory.createLineBorder(java.awt.Color.GRAY)); }");
                }
            }
        });
        
        os.system("mkdir -p /tmp/shimeji_move2");
        cc.writeFile("/tmp/shimeji_move2");
        System.out.println("Saved modified MultiSelectPlugin with visible ComboBox");
    }
}
"""
os.system("mkdir -p /tmp/shimeji_move2")
with open("/tmp/shimeji_move2/ChatPatchMove2.java", "w") as f:
    f.write(javassist_code.replace('os.system("mkdir -p /tmp/shimeji_move2");', ''))

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_move2/ChatPatchMove2.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_move2:/tmp/javassist.jar", "ChatPatchMove2"])
