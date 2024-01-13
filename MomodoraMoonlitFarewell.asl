state("MomodoraMoonlitFarewell")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");

    vars.Helper.GameName = "Momodora: Moonlit Farewell";
    vars.Helper.LoadSceneManager = true;
}

init
{
    current.Scene = "";
    current.GameScene = "";
    current.IsLoading = true;
    current.PlayTime = -1;

    current.BossRushIsActive = false;
    current.BossIsActive = false;
    current.BossId = "";
    current.BossIsDead = false;
    current.BossHP = 0;
    current.TargetEnemyIsDead = false;

    current.DialogueQueueLength = 0;

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

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        //var LinkedListClass = mono.GetClass("LinkedList`1");

        var GameData = mono["GameData"];
        var MainScr = mono["MainScr"];
        var PlaytimeCounter = mono["PlaytimeCounter"];
        var Platformer3D = mono["Platformer3D"];
        var BossScr = mono["BossHPBarScr"];
        var BossNamesScr = mono["BossNamesScr"];
        var CommonEnemy = mono["CommonEnemy"];
        var BossRematchManager = mono["BossRematchManager"];
        var DialogueManager = mono["DialogueManager"];

        vars.Helper["GameScene"] = GameData.MakeString("current", "scene_name");
        vars.Helper["IsLoading"] = MainScr.Make<bool>("sys_scene_loading");
        vars.Helper["PlayTime"] = PlaytimeCounter.Make<float>("playtime");
        vars.Helper["PlayerHP"] = Platformer3D.Make<float>("player_hp");
        vars.Helper["BossRushIsActive"] = BossRematchManager.Make<bool>("active");
        vars.Helper["BossIsActive"] = BossScr.Make<bool>("active");
        vars.Helper["BossId"] = BossNamesScr.MakeString("bossname");
        vars.Helper["BossHP"] = BossScr.Make<float>("BossEnemyComponent", CommonEnemy["hp"]);
        vars.Helper["BossIsDead"] = BossScr.Make<bool>("BossEnemyComponent", CommonEnemy["dead"]);
        vars.Helper["TargetEnemyIsDead"] = MainScr.Make<bool>("p3d", Platformer3D["TargetEnemy"], CommonEnemy["dead"]);
        vars.Helper["DialogueQueueLength"] = MainScr.Make<int>("dialogueManager", DialogueManager["queue"], 0x28);

        return true;
    });
}

isLoading
{
    return current.IsLoading;
}

gameTime
{
    // in-game timer
    // return TimeSpan.FromSeconds(current.PlayTime);
}

update
{
    if (!vars.Helper.Loaded)
        return false;

    vars.Helper.Update();

    current.Scene = vars.Helper.Scenes.Active.Name;
    current.BossIsDead = current.BossHP == 0;

    if (old.Scene != current.Scene)
    {
        print("Scene Transition: " + old.Scene + " > " + current.Scene);
    }

    if (old.GameScene != current.GameScene)
    {
        print("GameScene Transition: " + old.GameScene + " > " + current.GameScene);
    }

    if (current.BossIsActive && old.BossHP != current.BossHP)
    {
        print("Boss Damage " + vars.Strings[current.BossId] + " HP: " + current.BossHP);
    }

    if (current.BossIsActive && current.BossIsDead && !old.BossIsDead)
    {
        print("Boss Dead: " + vars.Strings[current.BossId]);
    }
}

start
{
    // on first Momo dialog
    return current.Scene == "Well01" && current.DialogueQueueLength == 3;

    // on new game started
    // return current.Scene == "BrightnessSetup";
}

split
{
    // Selin final fight
    if (current.BossIsActive && current.BossId == "boss_20" && !old.BossIsDead && current.BossIsDead)
        return true;
}

exit
{
    vars.Helper.Dispose();
}

shutdown
{
    vars.Helper.Dispose();
}
