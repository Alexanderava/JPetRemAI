import os
import zipfile

jar_path = "/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar"
temp_dir = "/tmp/shimeji_restore"

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
            
            # Replace all variations back to huggingface.co
            content = content.replace(b" https://hf-mirror.com", b"https://huggingface.co")
            
            # And any leftover broken ones from previous steps
            content = content.replace(b"https://hf-mirror.com/api/models?&sort=", b"https://huggingface.co/api/models?sort=")
            content = content.replace(b"https://hf-mirror.com//api/models?sort=", b"https://huggingface.co/api/models?sort=")
            
            content = content.replace(b"https://hf-mirror.com/api/models?&search=", b"https://huggingface.co/api/models?search=")
            content = content.replace(b"https://hf-mirror.com//api/models?search=", b"https://huggingface.co/api/models?search=")
            
            content = content.replace(b"https://hf-mirror.com/api/models/.", b"https://huggingface.co/api/models/")
            content = content.replace(b"https://hf-mirror.com//api/models/", b"https://huggingface.co/api/models/")
            
            content = content.replace(b"https://hf-mirror.com/.", b"https://huggingface.co/")
            content = content.replace(b"https://hf-mirror.com//", b"https://huggingface.co/")
            
            if content != orig:
                with open(filepath, "wb") as fp:
                    fp.write(content)
                print(f"Restored {f}")

os.system(f"cd {temp_dir} && zip -q -r /tmp/ShimejiEE_restored.jar .")
os.system(f"cp /tmp/ShimejiEE_restored.jar {jar_path}")
print("Done restoring huggingface.co URLs.")
