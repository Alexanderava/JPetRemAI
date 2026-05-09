import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class ChatPatchMove {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
        
        try {
            CtField f = CtField.make("public static java.awt.Component tmpComboRef = null;", cc);
            cc.addField(f);
        } catch (DuplicateMemberException e) {
            // Ignore if already added
        }
        
        CtMethod m = cc.getDeclaredMethod("buildChatPanel");
        
        m.instrument(new javassist.expr.ExprEditor() {
            public void edit(javassist.expr.MethodCall mc) throws CannotCompileException {
                if (mc.getMethodName().equals("add") && mc.getSignature().equals("(Ljava/awt/Component;Ljava/lang/Object;)V")) {
                    mc.replace("{ if ($2 != null && $2.equals(\\"Center\\") && $1 instanceof javax.swing.JComboBox) { com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef = $1; } else { $proceed($$); } }");
                }
                else if (mc.getMethodName().equals("add") && mc.getSignature().equals("(Ljava/awt/Component;)Ljava/awt/Component;")) {
                    mc.replace("{ if ($1 instanceof javax.swing.JButton && ((javax.swing.JButton)$1).getText() != null && ((javax.swing.JButton)$1).getText().contains(\\"模型仓库\\")) { if (com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef != null) { $0.add(com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef); } } $_ = $proceed($$); }");
                }
                else if (mc.getMethodName().equals("getComponent") && mc.getSignature().equals("(I)Ljava/awt/Component;")) {
                    mc.replace("{ if ($0.getComponentCount() == 0 && com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef != null) { $_ = com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef; } else { $_ = $proceed($$); } }");
                }
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setToolTipText")) {
                    mc.replace("{ $0.setVisible(true); $_ = $proceed($$); }");
                }
            }
        });
        
        os.system("mkdir -p /tmp/shimeji_move");
        cc.writeFile("/tmp/shimeji_move");
        System.out.println("Saved modified MultiSelectPlugin with moved ComboBox");
    }
}
"""
os.system("mkdir -p /tmp/shimeji_move")
with open("/tmp/shimeji_move/ChatPatchMove.java", "w") as f:
    f.write(javassist_code.replace('os.system("mkdir -p /tmp/shimeji_move");', ''))

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_move/ChatPatchMove.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_move:/tmp/javassist.jar", "ChatPatchMove"])
