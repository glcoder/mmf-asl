state("MomodoraMoonlitFarewell")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");

    vars.Helper.GameName = "Momodora: Moonlit Farewell";
    vars.Helper.LoadSceneManager = true;

    vars.Strings = new Dictionary<string,string> {
        { "", "(null)" },
        { "boss_01", "Gariser Demon" },
        { "boss_02", "Raging Demon" },
        { "boss_03", "Harpy Archdemon Plunia" },
        { "boss_04", "Black Cat" },
        { "boss_05", "Accursed Autarch" },
        { "boss_06", "Very Big Spider" },
        { "boss_07", "Viper Archdemon Sorrelia" },
        { "boss_08", "Selin's Sorrow" },
        { "boss_09", "Moon Goddess Lineth" },
        { "boss_10", "Moon God Selin, First Invocation" },
        { "boss_11", "Black Gariser" },
        { "boss_12", "Remnant of an Unknown Phantasm" },
        { "boss_13", "Bloodthirsty Archdemon Sariel" },
        { "boss_14", "Bloodthirsty Siblings" },
        { "boss_15", "Selin's Fear" },
        { "boss_16", "Selin's Mendacity" },
        { "boss_17", "Selin's Envy" },
        { "boss_18", "Tainted Serpent" },
        { "boss_19", "Moon God Selin, Second Invocation" },
        { "boss_20", "Moon God Selin, Third Invocation" },
        { "boss_21", "The Final Invocation of Selin" },
    };

    settings.Add("TimerStart", true, "Timer start conditions");
    settings.Add("GameStarted", false, "On New Game started", "TimerStart");
    settings.Add("GameModeSelected", true, "On Game Mode selected", "TimerStart");
    settings.Add("FirstMomoDialog", false, "On first Momo dialog", "TimerStart");

    settings.Add("GameSplits", true, "General game splits");
    settings.Add("DoraFinalDialog", true, "Final dialog with Dora started", "GameSplits");
    settings.Add("SacredLeaf", false, "Sacred Leaf awaken", "GameSplits");
    settings.Add("Sprint", false, "Sprint acquired", "GameSplits");
    settings.Add("DoubleJump", false, "Double Jump acquired", "GameSplits");
    settings.Add("WallJump", false, "Wall Jump acquired", "GameSplits");
    settings.Add("BerserkMode", false, "Lunar Attunement acquired", "GameSplits");
    settings.Add("FastTravel", false, "Fast Travel unlocked", "GameSplits");
    settings.Add("SilverDust", false, "Silver Dust acquired", "GameSplits");
    settings.Add("GoldenDust", false, "Golden Dust acquired", "GameSplits");
    settings.Add("WindmillKey", false, "Windmill Key acquired", "GameSplits");

    var BossIdArray = new string[] {
        "boss_01", "boss_02", "boss_03", "boss_04", "boss_05", "boss_06", "boss_07",
        "boss_08", "boss_09", "boss_10", "boss_11", "boss_12", "boss_13", "boss_14",
        "boss_15", "boss_16", "boss_17", "boss_18", "boss_19", "boss_20", "boss_21",
    };

    settings.Add("BossSplits", false, "Boss defeat splits");
    foreach (var BossId in BossIdArray)
    {
        settings.Add(BossId + "_defeat", false, vars.Strings[BossId], "BossSplits");
    }
}

init
{
    current.Scene = "";
    current.IsLoading = true;

    current.BossRushIsActive = false;
    current.BossIsActive = false;
    current.LastBossPtr = IntPtr.Zero;
    current.CurrentBossPtr = IntPtr.Zero;
    current.BossId = "";
    current.BossHP = 0.0f;
    current.BossIsDead = false;

    current.DialogueQueueLength = 0;
    current.NavigationTitle = "";
    current.StaffRollActive = false;

    current.Events = new int[512];

    vars.CommonEnemyDeadOffset = 0;
    vars.CommonEnemyHealthOffset = 0;

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var MainScr = mono["MainScr"];
        vars.Helper["IsLoading"] = MainScr.Make<bool>("sys_scene_loading");

        var BossRematchManager = mono["BossRematchManager"];
        vars.Helper["BossRushIsActive"] = BossRematchManager.Make<bool>("active");

        var Platformer3D = mono["Platformer3D"];
        vars.Helper["PlayerHP"] = Platformer3D.Make<float>("player_hp");

        var BossScr = mono["BossHPBarScr"];
        vars.Helper["BossIsActive"] = BossScr.Make<bool>("active");
        vars.Helper["CurrentBossPtr"] = BossScr.Make<IntPtr>("BossEnemyComponent");
        vars.Helper["CurrentBossPtr"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

        var BossNamesScr = mono["BossNamesScr"];
        vars.Helper["BossId"] = BossNamesScr.MakeString("bossname");

        var CommonEnemy = mono["CommonEnemy"];
        vars.CommonEnemyDeadOffset = CommonEnemy["dead"];
        vars.CommonEnemyHealthOffset = CommonEnemy["hp"];

        var DialogueManager = mono["DialogueManager"];
        vars.Helper["DialogueQueueLength"] = MainScr.Make<int>("dialogueManager", DialogueManager["queue"], 0x28);

        var StaffRoll = mono["StaffRoll"];
        vars.Helper["StaffRollActive"] = StaffRoll.Make<bool>("active");

        var GameData = mono["GameData"];
        var MomoEventData = mono["MomoEventData"];
        vars.Helper["Events"] = GameData.MakeArray<int>("current", "MomoEvent", MomoEventData["m_events"]);

        var NavInputPrompt = mono["NavInputPrompt"];
        vars.GetNavigationTitle = (Func<string>)(() =>
        {
            var TextEntries = vars.Helper.ReadList<IntPtr>(MainScr.Static + MainScr["NavInputPrompt"], NavInputPrompt["m_textEntries"]);
            return TextEntries.Count == 0 ? string.Empty : vars.Helper.ReadString(256, ReadStringType.AutoDetect, TextEntries[0] + 0x14);
        });

        return true;
    });
}

isLoading
{
    return current.IsLoading;
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name;
    current.NavigationTitle = vars.GetNavigationTitle();

    current.LastBossPtr = current.CurrentBossPtr == IntPtr.Zero ? old.LastBossPtr : current.CurrentBossPtr;
    if (current.LastBossPtr != IntPtr.Zero)
    {
        current.BossHP = vars.Helper.Read<float>(current.LastBossPtr + vars.CommonEnemyHealthOffset);
        current.BossIsDead = vars.Helper.Read<bool>(current.LastBossPtr + vars.CommonEnemyDeadOffset);
    }

    if (old.Scene != current.Scene)
    {
        print("Scene Transition: " + old.Scene + " > " + current.Scene);
    }

    if (old.BossId != current.BossId && !string.IsNullOrEmpty(current.BossId))
    {
        print("Boss Encountered: " + vars.Strings[current.BossId]);
    }

    if (!old.BossIsDead && current.BossIsDead)
    {
        print("Boss Defeated: " + vars.Strings[current.BossId]);
    }
    
    if (old.BossHP != current.BossHP)
    {
        print("Boss Damage: " + vars.Strings[current.BossId] + " HP: " + current.BossHP);
    }

    if (!old.StaffRollActive && current.StaffRollActive)
    {
        print("StaffRollActive: " + current.StaffRollActive);
    }

    for (int i = 0; i < current.Events.Length; ++i)
    {
        if (old.Events[i] != current.Events[i])
        {
            print("Event: " + i + " = " + current.Events[i]);
        }
    }

    if (old.NavigationTitle != current.NavigationTitle)
    {
        print("NavigationTitle: " + current.NavigationTitle);
    }
}

start
{
    return (settings["GameStarted"] && old.Scene != "BrightnessSetup" && current.Scene == "BrightnessSetup")
        || (settings["GameModeSelected"] && old.NavigationTitle == "ui_navigation" && current.NavigationTitle == "ui_brightness")
        || (settings["FirstMomoDialog"] && current.Scene == "Well01" && current.DialogueQueueLength == 3);
}

split
{
    if (settings["DoraFinalDialog"] && current.Scene == "Koho19" && old.DialogueQueueLength != 34 && current.DialogueQueueLength == 34)
        return true;

    if (settings["SacredLeaf"] && current.Scene == "Well26" && old.Events[20] != 1 && current.Events[20] == 1)
        return true;

    if (settings["Sprint"] && current.Scene == "Well29" && old.Events[9] != 1 && current.Events[9] == 1)
        return true;

    if (settings["DoubleJump"] && current.Scene == "Bark42" && old.Events[10] != 1 && current.Events[10] == 1)
        return true;

    if (settings["WallJump"] && current.Scene == "Fairy10" && old.Events[194] != 1 && current.Events[194] == 1)
        return true;

    if (settings["BerserkMode"] && current.Scene == "Marsh08" && old.Events[131] != 1 && current.Events[131] == 1)
        return true;

    if (settings["FastTravel"] && current.Scene == "Cove03" && old.Events[190] != 1 && current.Events[190] == 1)
        return true;

    if (settings["GoldenDust"] && current.Scene == "Koho16" && old.Events[180] != 1 && current.Events[180] == 1)
        return true;

    if (settings["SilverDust"] && current.Scene == "Bark41" && old.Events[181] != 1 && current.Events[181] == 1)
        return true;

    if (settings["WindmillKey"] && current.Scene == "Demon01" && old.Events[212] != 1 && current.Events[212] == 1)
        return true;

    if (!old.BossIsDead && current.BossIsDead && settings[current.BossId + "_defeat"])
        return true;
}
