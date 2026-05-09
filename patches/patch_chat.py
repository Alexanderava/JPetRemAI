import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class ChatPatchHideCb {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
        
        CtMethod m = cc.getDeclaredMethod("buildChatPanel");
        m.instrument(new javassist.expr.ExprEditor() {
            public void edit(javassist.expr.MethodCall mc) throws CannotCompileException {
                if (mc.getClassName().equals("javax.swing.JComboBox") && mc.getMethodName().equals("setToolTipText")) {
                    mc.replace("{ $0.setVisible(false); $_ = $proceed($$); }");
                }
            }
        });
        
        cc.writeFile("/tmp/shimeji_hide_cb");
        System.out.println("Saved modified MultiSelectPlugin");
    }
}
"""
os.system("mkdir -p /tmp/shimeji_hide_cb")
with open("/tmp/shimeji_hide_cb/ChatPatchHideCb.java", "w") as f:
    f.write(javassist_code)

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_hide_cb/ChatPatchHideCb.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_hide_cb:/tmp/javassist.jar", "ChatPatchHideCb"])
