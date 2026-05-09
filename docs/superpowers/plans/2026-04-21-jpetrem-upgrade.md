# JPetRem (Desktop-Pixel-Pet) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement three advanced features: JNA real window interaction (Scheme 1), programmer immersive companion mode with global hooks (Scheme 3), and JBox2D physics engine (Scheme 4).

**Architecture:** 
- Scheme 1 (JNA): Integrate `jna.jar` and `jna-platform.jar`. Write a `MacWindowObserver` using CoreGraphics to fetch active window bounds and feed them to Shimeji-ee's `Environment`.
- Scheme 3 (Immersive Mode): Integrate `jnativehook.jar`. Write a `KeyboardSyncPlugin` that listens to global key events, calculates typing speed (WPM), and dynamically overrides the Mascot's speed and animation state. Enhance existing `PomodoroManager` to force a sleeping action.
- Scheme 4 (JBox2D): Integrate `jbox2d-library.jar`. Create a `PhysicsWorld` singleton running in a separate thread. For each spawned Mascot, attach a rigid body. Override the XML behavior system so that when the pet is dragged or falling, the physics engine takes over the XY coordinates.

**Tech Stack:** Java Swing, JNA, JNativeHook, JBox2D.

---

### Task 1: Scheme 1 - JNA Window Interaction (macOS)
- [ ] **Step 1: Download JNA dependencies**
```bash
cd /Applications/JPetRem.app/Contents/Resources/lib
curl -L https://repo1.maven.org/maven2/net/java/dev/jna/jna/5.13.0/jna-5.13.0.jar -o jna.jar
curl -L https://repo1.maven.org/maven2/net/java/dev/jna/jna-platform/5.13.0/jna-platform-5.13.0.jar -o jna-platform.jar
```
- [ ] **Step 2: Implement `MacWindowObserver.java`**
Write a JNA wrapper for macOS `CGWindowListCopyWindowInfo` to detect foreground windows.

### Task 2: Scheme 3 - Immersive Companion Mode (Global Hook)
- [ ] **Step 1: Download JNativeHook**
```bash
curl -L https://repo1.maven.org/maven2/com/1stleg/jnativehook/2.1.0/jnativehook-2.1.0.jar -o lib/jnativehook.jar
```
- [ ] **Step 2: Implement `KeyboardSyncPlugin.java`**
Listen to `nativeKeyPressed`. Calculate CPM (Characters Per Minute). If CPM > 100, trigger "Run" or "Excited" animations. Connect `PomodoroManager` to `SocketCommandServer` to broadcast `setting:sleep` after 45 minutes.

### Task 3: Scheme 4 - JBox2D Multi-pet Collision
- [ ] **Step 1: Download JBox2D**
```bash
curl -L https://repo1.maven.org/maven2/org/jbox2d/jbox2d-library/2.2.1.1/jbox2d-library-2.2.1.1.jar -o lib/jbox2d.jar
```
- [ ] **Step 2: Implement `PhysicsEngine.java`**
Create a `World(new Vec2(0, 9.8f))`. Map Mascot bounds to Box2D bodies. Apply forces when dragged, and handle collisions.

