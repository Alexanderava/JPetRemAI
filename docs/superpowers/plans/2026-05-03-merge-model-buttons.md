# Merge Model Buttons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将聊天页右上角 3 个模型相关按钮合并为 1 个“模型管理”按钮，点击后打开 `com.gfinity.ModelManagerPanel`（内含“模型仓库 / 本地模型 / 下载管理”3 个 Tab），默认打开 Tab=0（模型仓库）。

**Architecture:** 不直接重编译整个应用源码，而是对 `ShimejiEE.jar` 中的 `com.group_finity.mascot.plugin.MultiSelectPlugin` 做一次 Javassist 字节码补丁：在 `buildChatPanel()` 方法返回前遍历按钮控件，隐藏“模型仓库/下载模型”，并将“模型管理”按钮重绑定为 `ModelManagerPanel.show(<chatPanel>, 0)`。

**Tech Stack:** Java 17（应用内置 JRE）、Javassist（补丁编译与字节码编辑）、zip（更新 jar 条目）。

---

## Files

**Modify:**
- `/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar`（更新 `com/group_finity/mascot/plugin/MultiSelectPlugin*.class`）

**Reference (do not modify):**
- `/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar.bak_jd_1777747291199`（可反编译版本，用于定位逻辑）
- `/Applications/JPetRemAI.app/Contents/Resources/docs/superpowers/plans/2026-05-03-merge-model-buttons.md`（本文档）

**Temporary build outputs:**
- `/tmp/jpetrem_patch_model_btn/`（补丁源码与编译产物）

---

### Task 1: 备份 jar 并准备补丁构建目录

**Files:**
- Modify: `/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar`（后续任务）
- Create: `/tmp/jpetrem_patch_model_btn/`（临时目录）

- [ ] **Step 1: 备份 ShimejiEE.jar**

Run:

```bash
cp /Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar \
  /Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar.bak_merge_model_btn_$(date +%s)
```

- [ ] **Step 2: 创建临时目录**

Run:

```bash
mkdir -p /tmp/jpetrem_patch_model_btn
```

---

### Task 2: 确认 ModelManagerPanel 已满足 “三 Tab” 要求

**Files:**
- Read: `/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar`（内部 class）

- [ ] **Step 1: 反编译确认 ModelManagerPanel 三个 Tab**

Run:

```bash
python3 - <<'PY'
import zipfile, pathlib, subprocess
jar='/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar'
tmp=pathlib.Path('/tmp/jpetrem_patch_model_btn/gfinity')
tmp.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(jar) as z:
    p=tmp/'com/gfinity/ModelManagerPanel.class'
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(z.read('com/gfinity/ModelManagerPanel.class'))
java='/Applications/JPetRemAI.app/Contents/Java/bin/java'
cfr='/Applications/JPetRemAI.app/Contents/Resources/cfr.jar'
out=subprocess.check_output([java,'-jar',cfr,str(p),'--silent','true','--comments','false'], text=True)
assert '模型仓库' in out and '本地模型' in out and '下载管理' in out
print('OK: ModelManagerPanel has 3 tabs')
PY
```

Expected: 打印 `OK: ModelManagerPanel has 3 tabs`

---

### Task 3: 写 Javassist 补丁（将 3 按钮合并为 1 个）

**Files:**
- Create: `/tmp/jpetrem_patch_model_btn/PatchModelButtons.java`

- [ ] **Step 1: 写补丁源码**

Create file `/tmp/jpetrem_patch_model_btn/PatchModelButtons.java`:

```java
import javassist.ClassPool;
import javassist.CtClass;
import javassist.CtMethod;

public class PatchModelButtons {
  public static void main(String[] args) throws Exception {
    String jarPath = "/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar";
    String outDir = "/tmp/jpetrem_patch_model_btn/out";

    ClassPool pool = ClassPool.getDefault();
    pool.insertClassPath(jarPath);

    CtClass cc = pool.get("com.group_finity.mascot.plugin.MultiSelectPlugin");
    CtMethod m = cc.getDeclaredMethod("buildChatPanel");

    String code =
        "{"
            + "  final java.awt.Component __ctx = $_;"
            + "  java.util.ArrayDeque __q = new java.util.ArrayDeque();"
            + "  __q.add(__ctx);"
            + "  while (!__q.isEmpty()) {"
            + "    Object __o = __q.removeFirst();"
            + "    if (__o instanceof java.awt.Container) {"
            + "      java.awt.Component[] __cs = ((java.awt.Container)__o).getComponents();"
            + "      if (__cs != null) {"
            + "        for (int __i=0; __i<__cs.length; __i++) {"
            + "          if (__cs[__i] != null) __q.add(__cs[__i]);"
            + "        }"
            + "      }"
            + "    }"
            + "    if (__o instanceof javax.swing.AbstractButton) {"
            + "      javax.swing.AbstractButton __b = (javax.swing.AbstractButton)__o;"
            + "      String __t = __b.getText();"
            + "      if (__t == null) continue;"
            + "      if (\"模型仓库\".equals(__t) || \"下载模型\".equals(__t)) {"
            + "        __b.setVisible(false);"
            + "        __b.setEnabled(false);"
            + "      }"
            + "      if (\"模型管理\".equals(__t)) {"
            + "        java.awt.event.ActionListener[] __ls = __b.getActionListeners();"
            + "        if (__ls != null) {"
            + "          for (int __j=0; __j<__ls.length; __j++) {"
            + "            __b.removeActionListener(__ls[__j]);"
            + "          }"
            + "        }"
            + "        __b.addActionListener(new java.awt.event.ActionListener() {"
            + "          public void actionPerformed(java.awt.event.ActionEvent e) {"
            + "            try {"
            + "              com.gfinity.ModelManagerPanel.show(__ctx, 0);"
            + "            } catch (Throwable ex) {"
            + "              ex.printStackTrace();"
            + "            }"
            + "          }"
            + "        });"
            + "      }"
            + "    }"
            + "  }"
            + "}";

    m.insertAfter(code, true);
    cc.writeFile(outDir);
  }
}
```

- [ ] **Step 2: 准备 javassist.jar**

Run:

```bash
ls -l /tmp/javassist.jar
```

If missing, download it once (example: Maven Central) or locate an existing jar in the app bundle and copy it to `/tmp/javassist.jar`.

- [ ] **Step 3: 编译补丁**

Run:

```bash
/Applications/JPetRemAI.app/Contents/Java/bin/javac \
  -cp /tmp/javassist.jar \
  /tmp/jpetrem_patch_model_btn/PatchModelButtons.java
```

- [ ] **Step 4: 运行补丁，产出新的 MultiSelectPlugin.class**

Run:

```bash
/Applications/JPetRemAI.app/Contents/Java/bin/java \
  -cp /tmp/jpetrem_patch_model_btn:/tmp/javassist.jar \
  PatchModelButtons
```

Expected: `/tmp/jpetrem_patch_model_btn/out/com/group_finity/mascot/plugin/MultiSelectPlugin.class` 出现，并且可能还有 `MultiSelectPlugin$*.class`。

---

### Task 4: 写回 jar 并验证

**Files:**
- Modify: `/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar`

- [ ] **Step 1: 更新 jar 中的 class 条目**

Run:

```bash
cd /tmp/jpetrem_patch_model_btn/out && \
zip -u /Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar \
  com/group_finity/mascot/plugin/MultiSelectPlugin*.class
```

- [ ] **Step 2: 静态检查：确认字节码包含 ModelManagerPanel 调用**

Run:

```bash
python3 - <<'PY'
import zipfile
jar='/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar'
with zipfile.ZipFile(jar) as z:
    b=z.read('com/group_finity/mascot/plugin/MultiSelectPlugin.class')
assert b'ModelManagerPanel' in b
print('OK: patched class references ModelManagerPanel')
PY
```

- [ ] **Step 3: 运行时验证（手动）**

1) 启动 JPetRemAI  
2) 打开「聊天」Tab  
3) 右上角应只剩 1 个按钮“模型管理”  
4) 点击后弹出 “模型管理” 窗口，Tab 包含：模型仓库 / 本地模型 / 下载管理，默认打开模型仓库  

---

## Plan Self-Review

- 覆盖需求：合并 3 按钮为 1 按钮、点击打开 ModelManagerPanel、包含 3 Tab、默认 Tab=0 ✅
- 占位符扫描：仅 javassist.jar 获取方式存在分支，但给出了检查命令与补救路径 ✅
- 一致性：使用 `ModelManagerPanel.show(component, tabIndex)`，tabIndex=0 与需求一致 ✅

---

## Execution Choice

Plan complete and saved to `/Applications/JPetRemAI.app/Contents/Resources/docs/superpowers/plans/2026-05-03-merge-model-buttons.md`. Two execution options:

1. **Subagent-Driven (recommended)** - dispatch a fresh worker per task, review between tasks
2. **Inline Execution** - execute tasks in this session with checkpoints

Which approach?

