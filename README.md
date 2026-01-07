## **HYDROBRIDGE V5.1 — Documentation**

**Hydrobridge** is a lightweight, file-based communication protocol for Roblox. it allows multiple game instances running on the same machine to talk to each other by using the local file system as a data bridge.

---

### ## 🚀 Quick Start

1. **Execution:** Run the script on all Roblox instances you wish to link.
2. **Identification:** A small UI will appear in the top-right corner showing your **BRIDGE ID** (e.g., `BRIDGE ID: 1`).
3. **Communication:** Use the global `hydrobridge` table to send commands between clients.

---

### ## 🛠 Developer API

The script injects a global table `getgenv().hydrobridge` (shortened to `hb` in the code) which you can call from any other script or your executor's console.

#### **1. Execute on a Specific Instance**

Sends a string of code to be executed by a specific client ID.

```lua
-- Target Bridge ID 2 and make them jump
getgenv().hydrobridge.execute(2, "game.Players.LocalPlayer.Character.Humanoid.Jump = true")

```

#### **2. Execute on All Instances**

Sends a string of code to every active instance (including yourself).

```lua
-- Make every instance say "Hello" in chat
getgenv().hydrobridge.executeAll("game:GetService('ReplicatedStorage').DefaultChatSystemChatEvents.SayMessageRequest:FireServer('Hello!', 'All')")

```

#### **3. Conditional Targeting (Logic Gates)**

If you want to send a command to everyone but only have specific accounts react, wrap your code in a logic gate:

```lua
local code = [[
    if game.Players.LocalPlayer.Name == "YourAltName" then
        print("Command received by the target alt.")
    end
]]
getgenv().hydrobridge.executeAll(code)

```

---

### ## 📂 How it Works (Under the Hood)

* **File Path:** Files are stored in `workspace/hydrobridge/`.
* **Heartbeat:** Each instance updates a `lastHeartbeat` timestamp every second. If an instance doesn't update for 15 seconds, other instances will automatically delete its file to keep the "Bridge IDs" clean.
* **Polling:** Instances check their assigned `.json` file once per second for new strings in the `commands` array.
* **Security:** Only commands containing the correct `SECRET_KEY` ("SECURE_KEY_123") will be executed via `loadstring`.

---

### ## ⚠️ Important Notes

* **Execution Delay:** There is a polling rate of **1 second**. Commands are not instant; they may take up to 1 second to trigger on the target.
* **Executor Requirements:** Your executor must support `readfile`, `writefile`, `listfiles`, `makefolder`, and `loadstring`.
* **Studio Support:** This script identifies the environment as `"STUDIO"` if a JobId is not present.

---
SHEEEEEESH
