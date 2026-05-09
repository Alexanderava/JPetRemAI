import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class ChatPatchMoveFinal2 {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
        
        try {
            CtField f = CtField.make("public static java.awt.Component tmpComboRef6 = null;", cc);
            cc.addField(f);
        } catch (DuplicateMemberException e) {
            // Ignore
        }
        
        CtMethod m = cc.getDeclaredMethod("buildChatPanel");
        
        m.instrument(new javassist.expr.ExprEditor() {
            public void edit(javassist.expr.NewExpr e) throws CannotCompileException {
                if (e.getClassName().equals("javax.swing.JComboBox") && e.getSignature().equals("()V")) {
                    e.replace("{ $_ = $proceed($$); com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef6 = $_; }");
                }
            }
            
            public void edit(javassist.expr.MethodCall mc) throws CannotCompileException {
                if (mc.getClassName().equals("javax.swing.JPanel") && mc.getMethodName().equals("add") && mc.getSignature().equals("(Ljava/awt/Component;Ljava/lang/Object;)V")) {
                    mc.replace("{ if ($2 != null && $2.equals(\\"Center\\") && $1 instanceof javax.swing.JComboBox) { /* do nothing */ } else { $proceed($$); } }");
                }
                
                else if (mc.getClassName().equals("com.group_finity.mascot.plugin.ui.LiquidGlassPanel") && mc.getMethodName().equals("add") && mc.getSignature().equals("(Ljava/awt/Component;)Ljava/awt/Component;")) {
                    mc.replace("{ if ($1 instanceof javax.swing.JButton && ((javax.swing.JButton)$1).getText() != null && ((javax.swing.JButton)$1).getText().contains(\\"模型仓库\\")) { if (com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef6 != null) { javax.swing.JComboBox cb = (javax.swing.JComboBox)com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef6; cb.setPreferredSize(new java.awt.Dimension(250, 30)); cb.setOpaque(true); cb.putClientProperty(\\"JComboBox.buttonType\\", \\"default\\"); $0.add(cb); } } $_ = $proceed($$); }");
                }
                
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setToolTipText")) {
                    mc.replace("{ $0.setVisible(true); $_ = $proceed($$); }");
                }
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("putClientProperty") && mc.getSignature().equals("(Ljava/lang/Object;Ljava/lang/Object;)V")) {
                    mc.replace("{ if ($1.equals(\\"JComboBox.buttonType\\") && $2.equals(\\"none\\")) { /* do nothing */ } else { $proceed($$); } }");
                }
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setOpaque")) {
                    mc.replace("{ if ($1 == false && $0 == com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef6) { /* do nothing */ } else { $proceed($$); } }");
                }
                else if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setBorder")) {
                    mc.replace("{ if ($0 == com.group_finity.mascot.plugin.MultiSelectPlugin.tmpComboRef6) { /* do nothing */ } else { $proceed($$); } }");
                }
            }
        });
        
        cc.writeFile("/tmp/shimeji_layout6_out");
        System.out.println("Saved modified MultiSelectPlugin with properly styled ComboBox");
    }
}
"""
os.system("mkdir -p /tmp/shimeji_layout6_out")
with open("/tmp/shimeji_layout6_out/ChatPatchMoveFinal2.java", "w") as f:
    f.write(javassist_code)

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_layout6_out/ChatPatchMoveFinal2.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_layout6_out:/tmp/javassist.jar", "ChatPatchMoveFinal2"])
