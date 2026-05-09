import os
import subprocess

javassist_code = """
import javassist.*;

public class PatchOldCp {
    public static void main(String[] args) throws Exception {
        ClassPool pool = ClassPool.getDefault();
        pool.insertClassPath("/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar");
        
        CtClass cc = pool.get("com.group_finity.mascot.Main");
        CtMethod[] ms = cc.getDeclaredMethods("createTrayIcon");
        
        for (CtMethod m : ms) {
            m.instrument(new javassist.expr.ExprEditor() {
                public void edit(javassist.expr.MethodCall call) throws CannotCompileException {
                    if (call.getMethodName().equals("add") && (call.getClassName().equals("java.awt.Menu") || call.getClassName().equals("java.awt.PopupMenu"))) {
                        call.replace("{ " +
                            "if ($1 instanceof java.awt.MenuItem && ((java.awt.MenuItem)$1).getLabel() != null && ((java.awt.MenuItem)$1).getLabel().equals(com.group_finity.mascot.Tr.tr(\\"ChooseShimeji\\"))) { " +
                            "    /* do nothing, skip adding old control panel */ " +
                            "} else if ($1 instanceof java.awt.Menu && ((java.awt.Menu)$1).getLabel() != null && ((java.awt.Menu)$1).getLabel().equals(com.group_finity.mascot.Tr.tr(\\"Language\\"))) { " +
                            "    /* skip Language menu */ " +
                            "} else if ($1 instanceof java.awt.Menu && ((java.awt.Menu)$1).getLabel() != null && ((java.awt.Menu)$1).getLabel().equals(com.group_finity.mascot.Tr.tr(\\"AllowedBehaviours\\"))) { " +
                            "    /* skip AllowedBehaviours menu */ " +
                            "} else if ($1 instanceof java.awt.Menu && ((java.awt.Menu)$1).getLabel() != null && ((java.awt.Menu)$1).getLabel().equals(com.group_finity.mascot.Tr.tr(\\"Scaling\\"))) { " +
                            "    /* skip Scaling menu */ " +
                            "} else { " +
                            "    $_ = $proceed($$); " +
                            "} " +
                        "}");
                    }
                }
            });
        }
        
        cc.writeFile("/Applications/JPetRemAI.app/Contents/Resources/patch_out");
        System.out.println("Patched old control panel successfully.");
    }
}
"""

with open("/Applications/JPetRemAI.app/Contents/Resources/PatchOldCp.java", "w") as f:
    f.write(javassist_code)

os.system("mkdir -p /Applications/JPetRemAI.app/Contents/Resources/patch_out")
subprocess.run(["javac", "-cp", "/tmp/javassist.jar:/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar", "/Applications/JPetRemAI.app/Contents/Resources/PatchOldCp.java"])
subprocess.run(["java", "-cp", ".:/tmp/javassist.jar:/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar", "PatchOldCp"], cwd="/Applications/JPetRemAI.app/Contents/Resources")

if os.path.exists("/Applications/JPetRemAI.app/Contents/Resources/patch_out/com/group_finity/mascot/Main.class"):
    os.system("cd /Applications/JPetRemAI.app/Contents/Resources/patch_out && zip -u ../ShimejiEE.jar com/group_finity/mascot/Main.class")
    os.system("killall JPetRemAI ; killall JPetRemAI_bin ; killall java")
    os.system("sleep 2 ; open /Applications/JPetRemAI.app")
    print("Old control panel disabled successfully!")
else:
    print("Failed to patch.")
