import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class ChatPatchMoveFinal5 {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
        
        CtMethod m = cc.getDeclaredMethod("buildChatPanel");
        
        m.instrument(new javassist.expr.ExprEditor() {
            public void edit(javassist.expr.MethodCall mc) throws CannotCompileException {
                if (mc.getClassName().equals("com.group_finity.mascot.plugin.ui.LiquidGlassPanel") && mc.getMethodName().equals("add") && mc.getSignature().equals("(Ljava/awt/Component;)Ljava/awt/Component;")) {
                    mc.replace("{ System.out.println(\\"LiquidGlassPanel.add called with: \\" + $1.getClass().getName()); $_ = $proceed($$); }");
                }
            }
        });
        
        cc.writeFile("/tmp/shimeji_layout9_out");
    }
}
"""
os.system("mkdir -p /tmp/shimeji_layout9_out")
with open("/tmp/shimeji_layout9_out/ChatPatchMoveFinal5.java", "w") as f:
    f.write(javassist_code)

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_layout9_out/ChatPatchMoveFinal5.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_layout9_out:/tmp/javassist.jar", "ChatPatchMoveFinal5"])
