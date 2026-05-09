import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class PatchLlama {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.plugin.LlamaManager");
        ClassFile cf = cc.getClassFile();
        ConstPool cp = cf.getConstPool();
        
        boolean modified = false;
        for (int i = 1; i < cp.getSize(); i++) {
            int tag = cp.getTag(i);
            if (tag == ConstPool.CONST_Utf8) {
                String str = cp.getUtf8Info(i);
                if (str != null && str.equals("hf-mirror.com")) {
                    cp.setUtf8Info(i, "huggingface.co");
                    modified = true;
                    System.out.println("Replaced hf-mirror.com -> huggingface.co");
                }
                // Also if my previous python script broke the first argument, let's fix it
                if (str != null && str.equals("hf-mirror.com/")) {
                    cp.setUtf8Info(i, "huggingface.co");
                    modified = true;
                    System.out.println("Replaced hf-mirror.com/ -> huggingface.co");
                }
            }
        }
        
        if (modified) {
            os.system("mkdir -p /tmp/shimeji_llama");
            cc.writeFile("/tmp/shimeji_llama");
            System.out.println("Patched LlamaManager");
        } else {
            System.out.println("No modifications needed");
        }
    }
}
"""
os.system("mkdir -p /tmp/shimeji_llama")
with open("/tmp/shimeji_llama/PatchLlama.java", "w") as f:
    f.write(javassist_code.replace('os.system("mkdir -p /tmp/shimeji_llama");', ''))

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/shimeji_llama/PatchLlama.java"])
subprocess.run(["java", "-cp", "/tmp/shimeji_llama:/tmp/javassist.jar", "PatchLlama"])
