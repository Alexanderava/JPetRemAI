import os
import zipfile

jar_path = "/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar"
temp_dir = "/tmp/shimeji_final_fix"

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
            
            # Fix previously messed up strings (from my previous python scripts)
            content = content.replace(
                b"https://hf-mirror.com/api/models?&sort=",
                b" https://hf-mirror.com/api/models?sort="
            )
            content = content.replace(
                b"https://hf-mirror.com/api/models?&search=",
                b" https://hf-mirror.com/api/models?search="
            )
            content = content.replace(
                b"https://hf-mirror.com/api/models/.",
                b" https://hf-mirror.com/api/models/"
            )
            content = content.replace(
                b"https://hf-mirror.com/.",
                b" https://hf-mirror.com/"
            )
            content = content.replace(
                b"https://hf-mirror.com/....",
                b" https://hf-mirror.com/..."
            )
            
            # If the user somehow reverted to original huggingface.co jar
            content = content.replace(
                b"https://huggingface.co",
                b" https://hf-mirror.com"
            )
            
            if content != orig:
                with open(filepath, "wb") as fp:
                    fp.write(content)
                print(f"Fixed {f}")

os.system(f"cd {temp_dir} && zip -q -r /tmp/ShimejiEE_perfect.jar .")
os.system(f"cp /tmp/ShimejiEE_perfect.jar {jar_path}")
print("Done fixing all URLs.")
