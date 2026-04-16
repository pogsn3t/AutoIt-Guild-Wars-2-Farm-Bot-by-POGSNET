; ===================================================================
; POGS-GW2 Bot - Attack Priority & Defensive Retaliation
; Version 1.0 Beta
; ===================================================================

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <ProgressConstants.au3>
#include <SliderConstants.au3>
#include <StaticConstants.au3>
#include <UpDownConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>

Opt("GUIOnEventMode", 1)
Opt("SendKeyDownDelay", 50) 

; ----------------------------
; Globals
; ----------------------------
Global Const $GAME_CLASS = "[CLASS:ArenaNet_Gr_Window_Class]"
Global Const $SAVE_FILE  = @ScriptDir & "\ESBsave.ini"
Global Const $CHECK_COLOR = 0x050505

Global $gRunning = False
Global $gPaused = False
Global $gNeedsSetup = False
Global $gMiniMode = False
Global $gTurnDirection = 1 
Global $gGameHwnd = 0
Global $gColorVariance = 15 

Global $gTargetLeft[2] = [0, 0]
Global $gTargetColor = 0
Global $gHealthGlobe[2] = [0, 0]
Global $gPetHealth[2] = [0, 0]
Global $gCheckRange = False
Global $gRangePoint[2] = [0, 0]
Global $gRangeColor = 0

; Skill 2 Defensive Setup Globals
Global $gSkill2Ready[2] = [0, 0]
Global $gSkill2Color = 0

; Timers & States
Global $gRoamTimer = 0 
Global $gIsMovingToTarget = False 
Global $gInCombat = False       
Global $gLastTargetTimer = 0    
Global $gCombatStartTime = 0
Global $gLastStrafeTime = 0

; Survival Mode
Global $gSurvivalMode = False
Global $gFleeTimer = 0

Global $gSkillTimer[4]
For $i = 0 To 3
    $gSkillTimer[$i] = TimerInit()
Next

; GUI Handles
Global $hGUI, $cTimeLabel, $cProgress, $cStatusLabel
Global $btnStart, $btnStop, $btnSave, $btnMini
Global $chkRotateOneDir, $chkPet, $chkAutoRoam, $chkMoveToOOR, $chkUnstuck, $chkWallDetect
Global $sliderTurn, $sliderMove, $sliderHealth, $sliderPet, $sliderPause, $sliderLag
Global $inpVariance, $inpHealKey, $inpStuckSec, $inpTargetKey
Global $radPriorityNearest, $radPriorityAttacker
Global $skillKey[4], $skillEnabled[4], $skillCooldown[4], $skillCast[4]

; ----------------------------
; Initialization
; ----------------------------
CreateGUI()
LoadConfig()
HotKeySet("{PAUSE}", "TogglePause")
HotKeySet("^q", "_Exit")

; ===================================================================
; MAIN EVENT LOOP 
; ===================================================================
While 1
    Sleep(30) 
    
    Local $sec = @SEC
    If Mod($sec, 2) = 0 Then GUICtrlSetData($cTimeLabel, _Time())
    
    If $gNeedsSetup Then
        $gNeedsSetup = False
        If CaptureSetupPoints() Then
            $gRunning = True
            UpdateStatus("Bot Active and Scanning!")
            WinActivate($gGameHwnd)
            $gRoamTimer = TimerInit()
        Else
            _Stop()
        EndIf
    EndIf

    If $gRunning Then
        If Not $gPaused And GUICtrlRead($sliderPause) <> 2 Then
            BotLogicPulse()
        Else
            UpdateStatus("PAUSED - Waiting to resume...")
        EndIf
    EndIf
WEnd

; ===================================================================
; GUI CREATION 
; ===================================================================
Func CreateGUI()
    $hGUI = GUICreate("POGS-GW2 Bot", 400, 640, -1, -1, -1, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
    GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
    GUISetBkColor(0xDAE0F1)

    ; --- TOP BLOCK (Visible in Mini Mode) ---
    GUICtrlCreateLabel("Status:", 10, 10, 40, 20)
    $cStatusLabel = GUICtrlCreateLabel("Idle / Ready", 55, 10, 330, 20)
    GUICtrlSetFont($cStatusLabel, 9, 800)

    $btnStart = GUICtrlCreateButton("START", 10, 35, 80, 35)
    GUICtrlSetOnEvent($btnStart, "_Start")
    
    $btnStop = GUICtrlCreateButton("STOP", 95, 35, 80, 35)
    GUICtrlSetOnEvent($btnStop, "_Stop")
    GUICtrlSetState($btnStop, $GUI_DISABLE)
    
    $btnSave = GUICtrlCreateButton("SAVE", 180, 35, 60, 35)
    GUICtrlSetOnEvent($btnSave, "SaveConfig")

    $btnMini = GUICtrlCreateButton("MINIMIZE", 245, 35, 80, 35)
    GUICtrlSetOnEvent($btnMini, "ToggleMiniMode")

    $cTimeLabel = GUICtrlCreateLabel(_Time(), 335, 42, 60, 20)

    $cProgress = GUICtrlCreateProgress(10, 75, 380, 15)
    
    ; --- DIVIDER ---
    GUICtrlCreateLabel("=========================================================", 10, 100, 380, 15)

    ; --- BOTTOM BLOCK (Hidden in Mini Mode) ---
    Local $baseY = 115
    GUICtrlCreateLabel("Skill #", 10, $baseY, 40, 20)
    GUICtrlCreateLabel("Enable", 60, $baseY, 45, 20)
    GUICtrlCreateLabel("CD (sec)", 120, $baseY, 55, 20)
    GUICtrlCreateLabel("Cast (ms)", 190, $baseY, 55, 20)
    GUICtrlCreateLabel("Hotkey", 260, $baseY, 50, 20)

    Local $y = $baseY + 25
    For $i = 0 To 3
        GUICtrlCreateLabel("Skill " & ($i + 1), 10, $y, 45, 20)
        $skillEnabled[$i] = GUICtrlCreateInput("0", 60, $y, 40, 20, $ES_NUMBER)
        $skillCooldown[$i] = GUICtrlCreateInput("0", 120, $y, 55, 20, $ES_NUMBER)
        $skillCast[$i] = GUICtrlCreateInput("0", 190, $y, 55, 20, $ES_NUMBER)
        $skillKey[$i] = GUICtrlCreateInput(String($i + 1), 260, $y, 40, 20)
        $y += 30
    Next

    $y += 10
    GUICtrlCreateLabel("Target Key:", 10, $y, 60, 20)
    $inpTargetKey = GUICtrlCreateInput("TAB", 75, $y-3, 40, 20)
    GUICtrlCreateLabel("Heal Key:", 135, $y, 50, 20)
    $inpHealKey = GUICtrlCreateInput("6", 190, $y-3, 40, 20)
    GUICtrlCreateLabel("Color Var:", 245, $y, 60, 20)
    $inpVariance = GUICtrlCreateInput("15", 305, $y-3, 40, 20)

    ; --- NEW: ATTACK PRIORITY ---
    $y += 30
    GUICtrlCreateGroup(" Attack Priority ", 10, $y, 380, 50)
    $radPriorityNearest = GUICtrlCreateRadio("Attack Nearest (Aggressive)", 20, $y+20, 160, 20)
    $radPriorityAttacker = GUICtrlCreateRadio("Target Attacker (Defensive)", 200, $y+20, 160, 20)
    GUICtrlSetState($radPriorityNearest, $GUI_CHECKED)

    $y += 60
    $sliderTurn = GUICtrlCreateSlider(95, $y-3, 90, 30)
    GUICtrlSetLimit($sliderTurn, 50, 0)
    GUICtrlCreateLabel("Turn Time", 10, $y, 80, 20)
    
    $sliderMove = GUICtrlCreateSlider(285, $y-3, 90, 30)
    GUICtrlSetLimit($sliderMove, 50, 0)
    GUICtrlCreateLabel("Move Time", 200, $y, 80, 20)

    $y += 40
    $sliderHealth = GUICtrlCreateSlider(95, $y-3, 90, 30)
    GUICtrlCreateLabel("Self Flee HP", 10, $y, 80, 20) 
    
    $sliderPet = GUICtrlCreateSlider(285, $y-3, 90, 30)
    GUICtrlCreateLabel("Pet HP", 200, $y, 80, 20)

    $y += 40
    $sliderLag = GUICtrlCreateSlider(95, $y-3, 90, 30)
    GUICtrlSetLimit($sliderLag, 1000, 100)
    GUICtrlCreateLabel("Lag Delay", 10, $y, 80, 20)
    
    $sliderPause = GUICtrlCreateSlider(285, $y-3, 90, 30)
    GUICtrlSetLimit($sliderPause, 2, 1)
    GUICtrlCreateLabel("Pause Mode", 200, $y, 80, 20)

    $y += 40
    $chkRotateOneDir = GUICtrlCreateCheckbox("Rotate 1-Way Only", 10, $y, 120, 20)
    $chkPet = GUICtrlCreateCheckbox("Monitor Pet Health", 140, $y, 120, 20)
    
    $y += 25
    $chkAutoRoam = GUICtrlCreateCheckbox("Enable Auto Roam", 10, $y, 120, 20)
    $chkMoveToOOR = GUICtrlCreateCheckbox("Chase Target (OOR)", 140, $y, 130, 20)

    $y += 25
    $chkUnstuck = GUICtrlCreateCheckbox("Time Stuck Failsafe", 10, $y, 125, 20)
    GUICtrlCreateLabel("Trigger (sec):", 140, $y+2, 70, 20)
    $inpStuckSec = GUICtrlCreateInput("10", 215, $y, 40, 20, $ES_NUMBER)

    $y += 25
    $chkWallDetect = GUICtrlCreateCheckbox("Visual Wall/Collision Detect (Screen Freeze)", 10, $y, 250, 20)

    GUISetState(@SW_SHOW)
EndFunc

Func ToggleMiniMode()
    $gMiniMode = Not $gMiniMode
    If $gMiniMode Then
        GUICtrlSetData($btnMini, "MAXIMIZE")
        WinMove($hGUI, "", Default, Default, 416, 135) 
    Else
        GUICtrlSetData($btnMini, "MINIMIZE")
        WinMove($hGUI, "", Default, Default, 416, 680) 
    EndIf
EndFunc

; ===================================================================
; BOT LOGIC PULSE
; ===================================================================
Func BotLogicPulse()
    Local $hOff = GUICtrlRead($sliderHealth)
    Local $lDelay = GUICtrlRead($sliderLag)

    If Not WinActive($gGameHwnd) Then WinActivate($gGameHwnd)

    If IsCtrlChecked($chkPet) Then CheckPetHealth()
    
    Local $bLowHP = IsLowHealth($hOff)
    Local $bUnderAttack = IsLowHealth(15) 

    ; ==========================================
    ; SURVIVAL & FLEE MODE
    ; ==========================================
    If $bLowHP Then
        If Not $gSurvivalMode Then
            $gSurvivalMode = True
            $gInCombat = False
            
            If $gIsMovingToTarget Then
                Send("{w up}")
                $gIsMovingToTarget = False
            EndIf
            
            UpdateStatus("EMERGENCY: Health Critical! Dropping target and fleeing...")
            Send("{ESC}")
            Sleep(50)
            SendGameKey(GUICtrlRead($inpHealKey), 60, 120)
            HoldGameKey("D", Random(1400, 1700, 1))
            Send("{w down}")
            $gFleeTimer = TimerInit()
        EndIf
        
        UpdateStatus("FLEEING: Health Critical! Waiting to recover...")
        
        If TimerDiff($gFleeTimer) > 4000 Then
            SendGameKey(GUICtrlRead($inpHealKey), 60, 120)
            $gFleeTimer = TimerInit()
        EndIf
        
        If Random(1, 100, 1) > 95 Then SendGameKey("SPACE", 50, 100)
        
        Return 
    Else
        If $gSurvivalMode Then
            Send("{w up}")
            $gSurvivalMode = False
            UpdateStatus("RECOVERED: Health stable. Resuming operations...")
            $gRoamTimer = TimerInit()
            Return
        EndIf
    EndIf

    ; ==========================================
    ; DEFENSIVE SKILL 2 (ATTACKED/SURROUNDED)
    ; ==========================================
    If $bUnderAttack And Not $gSurvivalMode Then
        Local $cd = Number(GUICtrlRead($skillCooldown[1])) * 1000 
        If TimerDiff($gSkillTimer[1]) > $cd Then
            If IsSkill2Ready() Then
                UpdateStatus("ATTACKED/SURROUNDED: Firing Skill 2!")
                SendGameKey(GUICtrlRead($skillKey[1]), 60, 120)
                $gSkillTimer[1] = TimerInit()
                Local $ct = Number(GUICtrlRead($skillCast[1])) * 100
                If $ct > 0 Then InterruptibleSleep($ct)
                If $lDelay > 0 Then InterruptibleSleep($lDelay)
            EndIf
        EndIf
    EndIf

    ; ==========================================
    ; TARGET LOCK LOGIC 
    ; ==========================================
    Local $bSeeTarget = HasTarget()

    If $bSeeTarget Then
        If Not $gInCombat Then
            $gInCombat = True
            $gCombatStartTime = TimerInit()
            $gLastStrafeTime = TimerInit()
        EndIf
        $gLastTargetTimer = TimerInit() 
        $gRoamTimer = 0 
    Else
        ; INCREASED DROPOFF TIMER TO 2.5 SECONDS to prevent losing target due to visual clutter
        If $gInCombat And TimerDiff($gLastTargetTimer) > 2500 Then
            $gInCombat = False 
            
            UpdateStatus("TARGET DEAD! Looting area...")
            If $gIsMovingToTarget Then
                Send("{w up}")
                $gIsMovingToTarget = False
            EndIf
            
            For $i = 1 To 5
                SendGameKey("f", 50, 100)
                Sleep(80)
            Next
        EndIf
    EndIf

    ; ==========================================
    ; COMBAT PHASE
    ; ==========================================
    If $gInCombat Then
        
        If $bSeeTarget And $gCheckRange And IsOutOfRange() Then
            If IsCtrlChecked($chkMoveToOOR) Then
                UpdateStatus("CLOSING GAP: Target OOR...")
                If Not $gIsMovingToTarget Then
                    Send("{w down}")
                    $gIsMovingToTarget = True
                EndIf
                Return 
            Else
                UpdateStatus("Target OOR. Dropping.")
                If $gIsMovingToTarget Then
                    Send("{w up}")
                    $gIsMovingToTarget = False
                EndIf
                Send("{ESC}") 
                Sleep(100)
                HoldGameKey("D", 300) 
                $gInCombat = False 
                Return
            EndIf
        EndIf

        If $gIsMovingToTarget Then
            Send("{w up}")
            $gIsMovingToTarget = False
        EndIf

        UpdateStatus("COMBAT: Attacking Target...")
        
        If TimerDiff($gCombatStartTime) > 5000 And TimerDiff($gLastStrafeTime) > 3000 Then
            UpdateStatus("COMBAT: Clearing Obstacle (Strafing)...")
            Local $strafeKey = "q"
            If Random(0, 10, 1) > 5 Then $strafeKey = "e"
            HoldGameKey($strafeKey, Random(500, 900, 1))
            $gLastStrafeTime = TimerInit()
        EndIf

        If TimerDiff($gSkillTimer[0]) > 400 Then
            SendGameKey(GUICtrlRead($skillKey[0]), 60, 120) 
            $gSkillTimer[0] = TimerInit()
        EndIf
        
        FireSkill(1, $lDelay)
        FireSkill(2, $lDelay)
        FireSkill(3, $lDelay)
        
    ; ==========================================
    ; ROAMING PHASE
    ; ==========================================
    Else
        If $gIsMovingToTarget Then
            Send("{w up}")
            $gIsMovingToTarget = False
        EndIf

        UpdateStatus("SEARCHING: Roaming for targets...")
        
        If IsCtrlChecked($chkAutoRoam) Then
            If $gRoamTimer = 0 Then $gRoamTimer = TimerInit()
            
            Local $stuckLimit = Number(GUICtrlRead($inpStuckSec)) * 1000
            If IsCtrlChecked($chkUnstuck) And TimerDiff($gRoamTimer) > $stuckLimit Then
                PerformUnstuck("TIME STUCK!")
            Else
                AutoRoamAction()
            EndIf
        Else
            TriggerPriorityTargeting()
            Sleep(200)
        EndIf
    EndIf
EndFunc

; ===================================================================
; GUI CONTROLS & SETUP
; ===================================================================
Func _Start()
    $gGameHwnd = WinGetHandle($GAME_CLASS)
    If @error Then Return MsgBox(16, "Error", "Guild Wars 2 not running.")
    
    $gColorVariance = Number(GUICtrlRead($inpVariance))
    GUICtrlSetState($btnStart, $GUI_DISABLE)
    GUICtrlSetState($btnStop, $GUI_ENABLE)
    
    $gNeedsSetup = True 
EndFunc

Func _Stop()
    $gRunning = False
    $gNeedsSetup = False
    $gInCombat = False
    
    If $gIsMovingToTarget Or $gSurvivalMode Then
        Send("{w up}")
        $gIsMovingToTarget = False
        $gSurvivalMode = False
    EndIf
    
    UpdateStatus("Idle / Stopped")
    GUICtrlSetState($btnStart, $GUI_ENABLE)
    GUICtrlSetState($btnStop, $GUI_DISABLE)
EndFunc

Func CaptureSetupPoints()
    UpdateStatus("Waiting for setup on screen...")
    
    ; UPDATED INSTRUCTIONS TO PREVENT DROPPING COMBAT EARLY
    SplashTextOn("Setup (1 of 4)", "Target an Enemy." & @CRLF & "Left-Click the FAR LEFT edge of the RED health bar." & @CRLF & "(Keeps target locked until 1% HP)", 550, 80, -1, 50, 1)
    While Not _IsPressed("01")
        If _IsPressed("1B") Then 
            SplashOff()
            Return False
        EndIf
        Sleep(10)
    WEnd
    $gTargetLeft = MouseGetPos()
    $gTargetColor = PixelGetColor($gTargetLeft[0], $gTargetLeft[1])
    SplashOff()
    Sleep(300)
    
    SplashTextOn("Setup (2 of 4)", "Left-Click the TOP of your own Health Globe.", 500, 60, -1, 50, 1)
    While Not _IsPressed("01")
        If _IsPressed("1B") Then 
            SplashOff()
            Return False
        EndIf
        Sleep(10)
    WEnd
    $gHealthGlobe = MouseGetPos()
    SplashOff()
    Sleep(300)
    
    SplashTextOn("Setup (3 of 4)", "Target an OUT OF RANGE enemy." & @CRLF & "Left-Click the RED LINE under Skill 1." & @CRLF & "(Press F2 to Skip)", 500, 90, -1, 50, 1)
    While 1
        If _IsPressed("01") Then
            $gRangePoint = MouseGetPos()
            $gRangeColor = PixelGetColor($gRangePoint[0], $gRangePoint[1])
            $gCheckRange = True
            ExitLoop
        EndIf
        If _IsPressed("71") Then 
            $gCheckRange = False
            ExitLoop
        EndIf
        If _IsPressed("1B") Then 
            SplashOff()
            Return False
        EndIf
        Sleep(10)
    WEnd
    SplashOff()
    Sleep(300)
    
    SplashTextOn("Setup (4 of 4)", "Ensure Skill 2 is READY (off cooldown)." & @CRLF & "Left-Click the center of your Skill 2 icon.", 500, 70, -1, 50, 1)
    While Not _IsPressed("01")
        If _IsPressed("1B") Then 
            SplashOff()
            Return False
        EndIf
        Sleep(10)
    WEnd
    $gSkill2Ready = MouseGetPos()
    $gSkill2Color = PixelGetColor($gSkill2Ready[0], $gSkill2Ready[1])
    SplashOff()
    
    Return True
EndFunc

; ===================================================================
; CORE FUNCTIONS
; ===================================================================
Func UpdateStatus($msg)
    GUICtrlSetData($cStatusLabel, $msg)
EndFunc

Func HasTarget()
    ; EXPANDED SEARCH AREA: Scans up to 150 pixels to the left to catch shrinking health bars
    PixelSearch($gTargetLeft[0]-150, $gTargetLeft[1]-5, $gTargetLeft[0]+15, $gTargetLeft[1]+5, $gTargetColor, $gColorVariance)
    Return (Not @error)
EndFunc

Func IsOutOfRange()
    PixelSearch($gRangePoint[0]-5, $gRangePoint[1]-5, $gRangePoint[0]+5, $gRangePoint[1]+5, $gRangeColor, 15)
    Return (Not @error)
EndFunc

Func IsSkill2Ready()
    PixelSearch($gSkill2Ready[0]-2, $gSkill2Ready[1]-2, $gSkill2Ready[0]+2, $gSkill2Ready[1]+2, $gSkill2Color, $gColorVariance)
    Return (Not @error)
EndFunc

Func TriggerPriorityTargeting()
    Local $targetKey = GUICtrlRead($inpTargetKey)
    
    If GUICtrlRead($radPriorityNearest) = $GUI_CHECKED Then
        SendGameKey($targetKey, 40, 80)
        Sleep(150)
        
    ElseIf GUICtrlRead($radPriorityAttacker) = $GUI_CHECKED Then
        If IsLowHealth(10) Then 
            UpdateStatus("AMBUSH DETECTED! Retaliating...")
            SendGameKey($targetKey, 40, 80)
            Sleep(150)
        EndIf
    EndIf
EndFunc

Func AutoRoamAction()
    TriggerPriorityTargeting()
    
    If HasTarget() Then Return 

    Local $move = GUICtrlRead($sliderMove) * 40
    Local $turn = GUICtrlRead($sliderTurn) * 30
    
    Local $turnKey = "D"
    If $gTurnDirection = 2 Then $turnKey = "A"

    If $turn > 0 Then HoldGameKey($turnKey, $turn + Random(0, 50, 1))
    
    If $move > 0 Then 
        Send("{w down}")
        Local $mTimer = TimerInit()
        Local $stuckDetected = False
        
        Local $cx = @DesktopWidth / 2
        Local $cy = (@DesktopHeight / 2) - 150 
        Local $lastPixels = PixelChecksum($cx - 20, $cy - 20, $cx + 20, $cy + 20)

        While TimerDiff($mTimer) < ($move + Random(0, 100, 1))
            If Not $gRunning Then ExitLoop
            Sleep(250) 
            
            If IsCtrlChecked($chkWallDetect) Then
                Local $currPixels = PixelChecksum($cx - 20, $cy - 20, $cx + 20, $cy + 20)
                If $currPixels = $lastPixels Then
                    $stuckDetected = True
                    ExitLoop 
                EndIf
                $lastPixels = $currPixels
            EndIf
        WEnd
        
        Send("{w up}")
        
        If $stuckDetected Then PerformUnstuck("WALL DETECTED!")
    EndIf
    
    If Not IsCtrlChecked($chkRotateOneDir) Then
        If Random(0, 10, 1) > 8 Then
            If $gTurnDirection = 1 Then
                $gTurnDirection = 2
            Else
                $gTurnDirection = 1
            EndIf
        EndIf
    EndIf
EndFunc

Func PerformUnstuck($msg = "STUCK DETECTED!")
    UpdateStatus($msg & " Executing un-stick maneuver...")
    Local $turnKey = "D"
    If $gTurnDirection = 2 Then $turnKey = "A"
    
    HoldGameKey($turnKey, Random(1400, 1800, 1))
    SendGameKey("SPACE", 50, 100)
    HoldGameKey("W", Random(1000, 2000, 1))
    
    If $gTurnDirection = 1 Then
        $gTurnDirection = 2
    Else
        $gTurnDirection = 1
    EndIf
    
    $gRoamTimer = TimerInit() 
EndFunc

Func FireSkill($idx, $lDel)
    Local $en = Number(GUICtrlRead($skillEnabled[$idx]))
    If $en <> 1 Then Return

    Local $cd = Number(GUICtrlRead($skillCooldown[$idx])) * 1000
    Local $ct = Number(GUICtrlRead($skillCast[$idx])) * 100
    Local $key = GUICtrlRead($skillKey[$idx])

    If TimerDiff($gSkillTimer[$idx]) < $cd Then Return

    SendGameKey($key, 60, 120)
    
    If $ct > 0 Then InterruptibleSleep($ct)
    If $lDel > 0 Then InterruptibleSleep($lDel)

    $gSkillTimer[$idx] = TimerInit()
EndFunc

Func SendGameKey($k, $min=50, $max=100)
    If StringStripWS($k, 8) = "" Or $k = "0" Then Return
    Send("{" & $k & " down}")
    Sleep(Random($min, $max, 1))
    Send("{" & $k & " up}")
EndFunc

Func HoldGameKey($k, $dur)
    If $dur <= 0 Then Return
    Send("{" & $k & " down}")
    Local $timer = TimerInit()
    While TimerDiff($timer) < $dur
        If Not $gRunning Then ExitLoop
        Sleep(10)
    WEnd
    Send("{" & $k & " up}")
EndFunc

Func IsLowHealth($off)
    PixelSearch($gHealthGlobe[0], $gHealthGlobe[1] + $off, $gHealthGlobe[0], $gHealthGlobe[1] + $off, $CHECK_COLOR, 20)
    Return (Not @error)
EndFunc

Func CheckPetHealth()
    Local $off = GUICtrlRead($sliderPet) - 150
    PixelSearch($gPetHealth[0] + $off, $gPetHealth[1], $gPetHealth[0] + $off, $gPetHealth[1], $CHECK_COLOR, 20)
    If Not @error Then SendGameKey(GUICtrlRead($inpHealKey))
EndFunc

Func InterruptibleSleep($ms)
    Local $timer = TimerInit()
    While TimerDiff($timer) < $ms
        If Not $gRunning Then Return
        Sleep(20)
    WEnd
EndFunc

Func TogglePause()
    $gPaused = Not $gPaused
    If $gPaused Then
        If $gIsMovingToTarget Or $gSurvivalMode Then
            Send("{w up}")
            $gIsMovingToTarget = False
        EndIf
    EndIf
EndFunc

Func SaveConfig()
    IniWrite($SAVE_FILE, "Config", "AutoRoam", IsCtrlChecked($chkAutoRoam))
    IniWrite($SAVE_FILE, "Config", "MoveToOOR", IsCtrlChecked($chkMoveToOOR))
    IniWrite($SAVE_FILE, "Config", "Unstuck", IsCtrlChecked($chkUnstuck))
    IniWrite($SAVE_FILE, "Config", "WallDetect", IsCtrlChecked($chkWallDetect))
    IniWrite($SAVE_FILE, "Config", "StuckSec", GUICtrlRead($inpStuckSec))
    
    If GUICtrlRead($radPriorityNearest) = $GUI_CHECKED Then
        IniWrite($SAVE_FILE, "Config", "Priority", "1")
    Else
        IniWrite($SAVE_FILE, "Config", "Priority", "2")
    EndIf
    
    UpdateStatus("Settings Saved to ESBsave.ini!")
EndFunc

Func LoadConfig()
    If Not FileExists($SAVE_FILE) Then Return
    If IniRead($SAVE_FILE, "Config", "AutoRoam", "0") = "1" Then GUICtrlSetState($chkAutoRoam, $GUI_CHECKED)
    If IniRead($SAVE_FILE, "Config", "MoveToOOR", "0") = "1" Then GUICtrlSetState($chkMoveToOOR, $GUI_CHECKED)
    If IniRead($SAVE_FILE, "Config", "Unstuck", "0") = "1" Then GUICtrlSetState($chkUnstuck, $GUI_CHECKED)
    If IniRead($SAVE_FILE, "Config", "WallDetect", "0") = "1" Then GUICtrlSetState($chkWallDetect, $GUI_CHECKED)
    GUICtrlSetData($inpStuckSec, IniRead($SAVE_FILE, "Config", "StuckSec", "10"))
    
    If IniRead($SAVE_FILE, "Config", "Priority", "1") = "2" Then
        GUICtrlSetState($radPriorityAttacker, $GUI_CHECKED)
    EndIf
EndFunc

Func IsCtrlChecked($c)
    Return BitAND(GUICtrlRead($c), $GUI_CHECKED) = $GUI_CHECKED
EndFunc

Func _Time()
    Return @HOUR & ":" & @MIN & ":" & @SEC
EndFunc

Func _Exit()
    Exit
EndFunc