# AutoIt-Guild-Wars-2-Farm-Bot-by-POGSNET
A customizable, pixel-based automated combat and roaming bot for Guild Wars 2, written in AutoIt. This bot utilizes screen pixel detection to manage targeting, combat rotations, survival mechanics, and anti-stuck navigation without hooking into the game's memory.

# POGS-GW2 Bot

A customizable, pixel-based automated combat and roaming bot for Guild Wars 2, written in AutoIt. This bot utilizes screen pixel detection to manage targeting, combat rotations, survival mechanics, and anti-stuck navigation without hooking into the game's memory.

## 🌟 Key Features

### Combat & Targeting
* **Smart Attack Priority:** Choose between two modes:
  * *Aggressive:* Actively seeks and attacks the nearest enemy.
  * *Defensive:* Waits and only retaliates when you take damage (Ambush Detection).
* **Persistent Target Tracking:** Uses an expanded pixel search area to track enemy health bars all the way down to 1% HP, preventing the bot from abandoning targets mid-fight.
* **Customizable Skill Rotations:** Configure up to 4 primary skills with individual hotkeys, cast times (ms), and cooldowns (sec).
* **Defensive Skill Auto-Cast:** Automatically detects when you are being attacked or surrounded (via minor health globe drops) and immediately fires Skill 2 if it is off cooldown.
* **Out of Range (OOR) Handling:** Visually detects if a target is out of range. Configurable to either chase the target down to close the gap, or drop the target and find a new one.
* **Combat Strafing:** Automatically strafes left or right during extended combat sequences to clear line-of-sight obstacles.

### Survival & Healing
* **Emergency Flee Mode:** Monitors your health globe. If health drops below a user-defined threshold, the bot instantly drops the target, hits the heal key, and executes an evasive retreat maneuver until health stabilizes.
* **Pet Health Monitoring:** Optional toggle to monitor a pet's health bar and trigger heals when they are taking heavy damage.

### Navigation & Roaming
* **Auto-Roaming:** Explores the area using configurable "Turn Time" and "Move Time" sliders to find new targets. 
* **Visual Wall Detection:** Uses pixel checksums to detect screen freezing (walking into a wall or corner) and immediately executes an un-stick maneuver.
* **Time-Stuck Failsafe:** If the bot roams for a set number of seconds without finding a target, it assumes it is trapped and executes an escape sequence.

### UI & Quality of Life
* **Interactive 4-Step Setup:** A built-in calibration wizard that prompts you to click specific UI elements (Enemy Health, Self Health, OOR Line, Skill 2 Ready state) to adapt to your screen resolution and UI scale.
* **Mini Mode:** Collapse the GUI into a tiny footprint to keep it out of the way while monitoring the bot's current status.
* **Save/Load Config:** All slider values, delays, and toggle states are saved to a local `.ini` file for quick startup on your next session.

---

## ⚙️ Setup Instructions
-- Requirements:
* **Windows based system
* **AutoIt Program
* **GW2 game

1. Run the script.
2. Adjust your skill hotkeys, cooldowns, and movement sliders.
3. Click **START**.
4. Follow the on-screen tooltips for the 4-step calibration:
   * **Click 1:** The far-left edge of an enemy's red health bar.
   * **Click 2:** The top of your character's health globe.
   * **Click 3:** The red Out-of-Range line under Skill 1 (or press F2 to skip).
   * **Click 4:** The center of your Skill 2 icon while it is off cooldown.

## ⚠️ Disclaimer
*This script interacts with the game client via simulated keystrokes and pixel reading. Use at your own risk. Automated gameplay may violate the Terms of Service for Guild Wars 2 and can result in account suspension.*
