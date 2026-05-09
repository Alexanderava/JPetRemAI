import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class ChatPatchMove3 {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
        
        try {
            CtField f = CtField.make("public static java.awt.Component tmpComboRef3 = null;", cc);
            cc.addField(f);
        } catch (DuplicateMemberException e) {
            // Ignore
        }
        
        CtMethod m = cc.getDeclaredMethod("buildChatPanel");
        
        m.instrument(new javassist.expr.ExprEditor() {
            public void edit(javassist.expr.NewExpr e) throws CannotCompileException {
                if (e.getClassName().equals("javax.swing.JComboBox")) {
                    e.replace("{ $_ = $proceed($$); com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef3 = $_; }");
                }
            }
            
            public void edit(javassist.expr.MethodCall mc) throws CannotCompileException {
                // Remove from center
                if (mc.getClassName().equals("javax.swing.JPanel") && mc.getMethodName().equals("add") && mc.getSignature().equals("(Ljava/awt/Component;Ljava/lang/Object;)V")) {
                    mc.replace("{ if ($2 != null && $2.equals(\\"Center\\") && $1 instanceof javax.swing.JComboBox) { /* do nothing */ } else { $proceed($$); } }");
                }
                
                // Add to var59 (the top panel)
                else if (mc.getClassName().equals("com.group_finity.mascot.plugin.ui.LiquidGlassPanel") && mc.getMethodName().equals("add")) {
                    mc.replace("{ $0.add($1); if ($1 instanceof javax.swing.JButton && ((javax.swing.JButton)$1).getText() != null && ((javax.swing.JButton)$1).getText().contains(\\"模型仓库\\")) { if (com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef3 != null) { $0.add(com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef3); ((javax.swing.JComboBox)com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef3).setPreferredSize(new java.awt.Dimension(250, 30)); ((javax.swing.JComboBox)com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef3).setOpaque(true); ((javax.swing.JComboBox)com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef3).putClientProperty(\\"JComboBox.buttonType\\", \\"default\\"); } } }");
                }
                
                // Override the visibility hook from my previous mistake (which hid it)
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setToolTipText")) {
                    mc.replace("{ $0.setVisible(true); $_ = $proceed($$); }");
                }
                
                // Override the previous layout hooks
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("putClientProperty") && mc.getSignature().equals("(Ljava/lang/Object;Ljava/lang/Object;)V")) {
                    mc.replace("{ if ($1.equals(\\"JComboBox.buttonType\\") && $2.equals(\\"none\\")) { /* do nothing */ } else { $proceed($$); } }");
                }
            }
        });
        
        cc.writeFile("/tmp/shimeji_move3_out");
        System.out.println("Saved modified MultiSelectPlugin with moved ComboBox");
    }
}
"""
os.system("mkdir -p /tmp/shimeji_move3_out")
with open("/tmp/shimeji_move3/ChatPatchMove3.java", "w") as f:
    f.write(javassist_code)

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_move3/ChatPatchMove3.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_move3:/tmp/javassist.jar", "ChatPatchMove3"])
