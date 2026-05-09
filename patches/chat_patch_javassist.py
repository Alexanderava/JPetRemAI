import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class ChatPatch {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
        ClassFile cf = cc.getClassFile();
        ConstPool cp = cf.getConstPool();
        
        boolean modified = false;
        for (int i = 1; i < cp.getSize(); i++) {
            int tag = cp.getTag(i);
            if (tag == ConstPool.CONST_Utf8) {
                String str = cp.getUtf8Info(i);
                // Look for the previously patched string
                if (str != null && str.contains("<html><div style='color:#ccc;text-align:right'>    \\u0001</div></html>")) {
                    cp.setUtf8Info(i, "<html><div style='color:#000;font-size:10px;text-align:right'>\\u0001</div></html>");
                    modified = true;
                    System.out.println("Patched chat user message HTML");
                }
                // Also look for original string just in case
                else if (str != null && str.contains("<html><div style='text-align: right; width: 100%;'>\\u0001</div></html>")) {
                    cp.setUtf8Info(i, "<html><div style='color:#000;font-size:10px;text-align:right'>\\u0001</div></html>");
                    modified = true;
                    System.out.println("Patched original chat user message HTML");
                }
            }
        }
        
        if (modified) {
            os.system("mkdir -p /tmp/shimeji_chat");
            cc.writeFile("/tmp/shimeji_chat");
            System.out.println("Saved modified MultiSelectPlugin");
        } else {
            System.out.println("HTML string not found!");
        }
    }
}
"""
os.system("mkdir -p /tmp/shimeji_chat")
with open("/tmp/shimeji_chat/ChatPatch.java", "w") as f:
    f.write(javassist_code.replace('os.system("mkdir -p /tmp/shimeji_chat");', ''))

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_chat/ChatPatch.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_chat:/tmp/javassist.jar", "ChatPatch"])
