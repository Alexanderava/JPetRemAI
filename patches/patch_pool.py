import subprocess
import os

javassist_code = """
import javassist.*;
import javassist.bytecode.*;
import java.io.*;

public class PatchPool {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        String[] classes = {
            "com.gfinity.HuggingFaceBrowserPanel",
            "com.gfinity.DownloadManagerPanel",
            "com.gfinity.DownloadManagerPanel$DownloadTaskPanel"
        };
        
        for (String className : classes) {
            try {
                CtClass cc = pool.get(className);
                ClassFile cf = cc.getClassFile();
                ConstPool cp = cf.getConstPool();
                
                boolean modified = false;
                for (int i = 1; i < cp.getSize(); i++) {
                    int tag = cp.getTag(i);
                    if (tag == ConstPool.CONST_Utf8) {
                        String str = cp.getUtf8Info(i);
                        if (str != null && str.contains("hf-mirror.com")) {
                            // Let's restore and then correctly change to hf-mirror.com
                            String newStr = str.replace("https://hf-mirror.com//", "https://hf-mirror.com/")
                                               .replace("https://hf-mirror.com/.", "https://hf-mirror.com/")
                                               .replace("?&sort=", "?sort=")
                                               .replace("?&search=", "?search=");
                            if (!str.equals(newStr)) {
                                cp.setUtf8Info(i, newStr);
                                modified = true;
                            }
                        }
                        if (str != null && str.contains("huggingface.co")) {
                            String newStr = str.replace("huggingface.co", "hf-mirror.com");
                            if (!str.equals(newStr)) {
                                cp.setUtf8Info(i, newStr);
                                modified = true;
                            }
                        }
                    }
                }
                
                if (modified) {
                    cc.writeFile("/tmp/hf_patched");
                    System.out.println("Patched " + className);
                } else {
                    System.out.println("No modifications for " + className);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
"""
os.system("mkdir -p /tmp/hf_patched")
with open("/tmp/hf_patched/PatchPool.java", "w") as f:
    f.write(javassist_code)

subprocess.run(["javac", "-cp", "/tmp/javassist.jar", "/tmp/hf_patched/PatchPool.java"])
subprocess.run(["java", "-cp", "/tmp/hf_patched:/tmp/javassist.jar", "PatchPool"])
