import os
import zipfile
import shutil

jar_path = "/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar"
backup_path = "/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar.bak"

if not os.path.exists(backup_path):
    print("Backup not found, assuming we have a messed up jar. Let's try to fix the lengths.")

# Wait, if we messed up the jar, we should restore from the very original?
# But wait, my previous modifications for other issues (like email, centering) are also in this jar!
# I shouldn't overwrite it with a clean jar!
# So I must fix the broken URLs IN PLACE!

temp_dir = "/tmp/shimeji_url_fix"
os.system(f"rm -rf {temp_dir}")
os.system(f"mkdir -p {temp_dir}")
os.system(f"unzip -q {jar_path} -d {temp_dir}")

for root, dirs, files in os.walk(temp_dir):
    for f in files:
        if f.endswith(".class"):
            filepath = os.path.join(root, f)
            with open(filepath, "rb") as fp:
                content = fp.read()
            
            orig = content
            # We want to replace b"\x00\x17https://hf-mirror.com//api/models?sort=" -> this is wrong length!
            # Wait, the current length of "https://hf-mirror.com//api/models?sort=" is 39!
            # \x00\x27 (39).
            # We want to change it to "https://hf-mirror.com/api/models?sort=" which is 38 (\x00\x26).
            
            content = content.replace(
                b"\x00\x27https://hf-mirror.com/api/models?&sort=",
                b"\x00\x26https://hf-mirror.com/api/models?sort="
            )
            content = content.replace(
                b"\x00\x29https://hf-mirror.com/api/models?&search=",
                b"\x00\x28https://hf-mirror.com/api/models?search="
            )
            content = content.replace(
                b"\x00\x22https://hf-mirror.com/api/models/.",
                b"\x00\x21https://hf-mirror.com/api/models/"
            )
            content = content.replace(
                b"\x00\x17https://hf-mirror.com/.",
                b"\x00\x16https://hf-mirror.com/"
            )
            
            # Just in case some were still huggingface:
            content = content.replace(
                b"\x00\x27https://huggingface.co/api/models?sort=",
                b"\x00\x26https://hf-mirror.com/api/models?sort="
            )
            content = content.replace(
                b"\x00\x29https://huggingface.co/api/models?search=",
                b"\x00\x28https://hf-mirror.com/api/models?search="
            )
            content = content.replace(
                b"\x00\x22https://huggingface.co/api/models/",
                b"\x00\x21https://hf-mirror.com/api/models/"
            )
            content = content.replace(
                b"\x00\x17https://huggingface.co/",
                b"\x00\x16https://hf-mirror.com/"
            )
            
            if content != orig:
                with open(filepath, "wb") as fp:
                    fp.write(content)
                print(f"Fixed URLs in {f}")

os.system(f"cd {temp_dir} && zip -q -r /tmp/ShimejiEE_url_fixed.jar .")
os.system(f"cp /tmp/ShimejiEE_url_fixed.jar {jar_path}")
print("Done fixing URLs.")
