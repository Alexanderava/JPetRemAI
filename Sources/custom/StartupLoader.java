// StartupLoader.java
// 与 SwiftUI 客户端生命周期绑定
// 用 AWTEventListener 即时截获控制面板窗口

import com.group_finity.mascot.loader.SocketCommandServer;
import java.awt.*;
import java.awt.event.*;
import java.io.*;

public class StartupLoader {

    private static RandomAccessFile lockRaf;
    private static java.nio.channels.FileChannel lockChannel;
    private static java.nio.channels.FileLock fileLock;
    private static volatile boolean running = true;

    public static void main(String[] args) {
        try {
            String userDir = System.getProperty("user.dir");
            
            // 单例锁
            String lockPath = userDir + "/conf/app.lock";
            File lockFile = new File(lockPath);
            lockFile.getParentFile().mkdirs();
            lockRaf = new RandomAccessFile(lockFile, "rw");
            lockChannel = lockRaf.getChannel();
            fileLock = lockChannel.tryLock();
            if (fileLock == null) {
                System.err.println("[StartupLoader] 已在运行");
                System.exit(1);
            }

            // 0. 注册 AWT 事件监听器——拦截所有窗口创建
            Toolkit.getDefaultToolkit().addAWTEventListener(event -> {
                if (event.getID() == WindowEvent.WINDOW_OPENED) {
                    Window w = ((WindowEvent) event).getWindow();
                    // 只 dispose 控制面板窗口（有标题的 Frame/Dialog），不碰 shimeji 宠物窗口
                    if (w instanceof Frame) {
                        String title = ((Frame) w).getTitle();
                        if (title != null && !title.isEmpty()) {
                            System.out.println("[Gate] 拦截窗口: " + title + " → dispose");
                            w.dispose();
                        }
                    }
                }
            }, AWTEvent.WINDOW_EVENT_MASK);

            System.out.println("[StartupLoader] 引擎启动 (AWT 拦截模式)");

            // 1. Socket 命令服务器
            SocketCommandServer server = SocketCommandServer.getInstance();
            boolean ok = server.start();
            if (ok) {
                System.out.println("[OK] Socket 127.0.0.1:" + server.getPort());
            } else {
                System.out.println("[Error] Socket 启动失败");
            }

            // 2. 桌面宠物渲染引擎
            final Class<?> mainClass = Class.forName("com.group_finity.mascot.Main");
            Thread engineThread = new Thread(() -> {
                try {
                    mainClass.getMethod("main", String[].class)
                        .invoke(null, new Object[]{new String[0]});
                } catch (Exception e) {
                    System.err.println("[Error] 引擎: " + e.getMessage());
                }
            }, "Shimeji-Main");
            engineThread.setDaemon(true);
            engineThread.start();
            System.out.println("[OK] 桌面宠物引擎已启动");
            Thread.sleep(3000);

            // Shutdown hook
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                System.out.println("[Shutdown] 收到退出信号，关闭引擎...");
                running = false;
                try { server.stop(); } catch (Exception e) {}
                try { if (fileLock != null) fileLock.release(); } catch (Exception e) {}
                try { if (lockChannel != null) lockChannel.close(); } catch (Exception e) {}
                try { if (lockRaf != null) lockRaf.close(); } catch (Exception e) {}
                System.out.println("[Shutdown] 引擎已关闭");
            }));

            System.out.println("[OK] 引擎就绪 (AWT Gate 激活)");
            System.out.println("");

            // 保持运行
            while (running) {
                Thread.sleep(1000);
            }

        } catch (Exception e) {
            System.err.println("[Fatal] " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
