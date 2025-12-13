
from mcstatus import JavaServer

SERVER_HOST = "IP_ADDRESS_HERE"  # Example: "mc.example.com"
SERVER_PORT = 25565                        # Default port

def main():
    try:
        server = JavaServer(SERVER_HOST, SERVER_PORT)
        status = server.status()

        online = status.players.online
        print(f"Players online: {online}")

        # status.players.sample may be None if server hides names
        if status.players.sample:
            print("Player names:")
            for player in status.players.sample:
                print(f" - {player.name}")
        else:
            print("No player list available (server hides names or no players).")

    except Exception as e:
        print(f"Could not reach server: {e}")

if __name__ == "__main__":
    main()