#!/usr/bin/env python3
# ============================================
# JPetRem Shimeji 客户端 — 单客户端命令行工具
# 用法: python3 shimeji_client.py [命令...]
# 无参数时进入交互模式
# ============================================

import socket
import sys
import argparse

HOST = "127.0.0.1"
PORT = 17521
TIMEOUT = 120.0


def send_cmd(cmd: str) -> str:
    """发送一条命令，返回服务器响应"""
    try:
        with socket.create_connection((HOST, PORT), timeout=TIMEOUT) as s:
            s.settimeout(TIMEOUT)
            s.sendall((cmd + "\n").encode("utf-8"))
            resp = s.recv(4096).decode("utf-8", errors="replace").strip()
            return resp
    except socket.timeout:
        return f"ERROR: 连接超时 ({TIMEOUT}s)"
    except ConnectionRefusedError:
        return f"ERROR: 连接被拒绝，JPetRem 可能未启动"
    except Exception as e:
        return f"ERROR: {e}"


CMDS = {
    "ping":            "测试连通性",
    "dismissall":      "遣散所有角色",
    "quit":            "关闭 ShimejiEE",
    "status":          "查询状态（等同于 ping）",
    "list":            "查询当前角色数量",
    "summon:蕾姆":     "召唤蕾姆",
    "summon:拉姆":     "召唤拉姆",
    "summon:三笠":     "召唤三笠",
    "summon:初音未来": "召唤初音未来",
    "summon:日向雏田": "召唤日向雏田",
    "summon:漩涡鸣人": "召唤漩涡鸣人",
    "summon_n:5":     "随机召唤 5 个角色",
    "setting:throwing:true":  "允许扔角色",
    "setting:throwing:false": "禁止扔角色",
    "setting:breeding:true":  "允许繁衍",
    "setting:breeding:false": "禁止繁衍",
}


def interactive():
    print(f"\n{'='*50}")
    print(f"  JPetRem Shimeji 控制台客户端")
    print(f"  服务器: {HOST}:{PORT}")
    print(f"{'='*50}")
    print(f"\n可用命令:")
    print(f"  {'命令':<35}  说明")
    print(f"  {'-'*35}  {'-'*20}")
    for cmd, desc in CMDS.items():
        print(f"  {cmd:<35}  {desc}")
    print()
    print("直接输入命令，支持: summon:<角色名> / summon_n:N / setting:key:bool")
    print("Ctrl+C 退出\n")

    while True:
        try:
            raw = input("\033[1;36mJPetRem>\033[0m ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\n退出")
            break

        if not raw:
            continue

        if raw in ("exit", "quit", "q"):
            print("退出")
            break

        if raw == "help":
            for cmd, desc in CMDS.items():
                print(f"  {cmd:<35}  {desc}")
            continue

        resp = send_cmd(raw)
        if resp.startswith("ERROR"):
            print(f"  \033[1;31m{resp}\033[0m")
        elif resp.startswith("OK"):
            print(f"  \033[1;32m{resp}\033[0m")
        else:
            print(f"  {resp}")


def main():
    parser = argparse.ArgumentParser(
        description="JPetRem Shimeji 单客户端测试工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python3 shimeji_client.py ping
  python3 shimeji_client.py summon:蕾姆
  python3 shimeji_client.py summon:拉姆 summon:初音未来
  python3 shimeji_client.py dismissall
  python3 shimeji_client.py setting:throwing:false
  python3 shimeji_client.py            # 交互模式
        """
    )
    parser.add_argument("commands", nargs="*", help="要发送的命令，不提供则进入交互模式")
    args = parser.parse_args()

    if not args.commands:
        interactive()
        return

    for cmd in args.commands:
        print(f"\033[1;34m→ {cmd}\033[0m")
        resp = send_cmd(cmd)
        if resp.startswith("ERROR"):
            print(f"  \033[1;31m{resp}\033[0m")
        elif resp.startswith("OK"):
            print(f"  \033[1;32m{resp}\033[0m")
        else:
            print(f"  {resp}")


if __name__ == "__main__":
    main()
