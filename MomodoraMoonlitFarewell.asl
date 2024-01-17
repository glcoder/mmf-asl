state("MomodoraMoonlitFarewell")
{
}

startup
{
    var AslHelper = Assembly.Load(File.ReadAllBytes("Components/asl-help"));
    AslHelper.CreateInstance("Unity");

    vars.SceneManagerAddress = AslHelper.GetType("AslHelp.SceneManagement.SceneManager").GetProperty("Address", BindingFlags.Public | BindingFlags.Static);

    vars.Helper.GameName = "Momodora: Moonlit Farewell";
    vars.Helper.LoadSceneManager = true;
}

init
{
    current.Scene = "";
    current.IsLoading = true;

    current.BossRushIsActive = false;
    current.BossIsActive = false;
    current.BossId = "";
    current.BossIsDead = false;
    current.BossHP = 0;
    current.TargetEnemyIsDead = false;

    current.DialogueQueueLength = 0;
    current.BrightnessScreenMode = 0;
    current.StaffRollActive = false;

    current.Events = new int[512];

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

    Func<IntPtr, string, IntPtr> GameObjectFindComponentByName = null; // for recursive call
    GameObjectFindComponentByName = (ManagedGameObjectPtr, ComponentName) =>
    {
        if (ManagedGameObjectPtr == IntPtr.Zero)
            return IntPtr.Zero;

        var NativeGameObjectPtr = vars.Helper.Read<IntPtr>(ManagedGameObjectPtr + 0x10 /* ManagedGameObject.m_CachedPtr */);
        if (NativeGameObjectPtr == IntPtr.Zero)
            return IntPtr.Zero;

        var NativeGameObjectName = vars.Helper.ReadString(256, ReadStringType.AutoDetect, NativeGameObjectPtr + 0x60 /* GameObject.m_Name */ + 0x0 /* ConstantString.m_Buffer */, 0x0 /* char* */);
        if (string.IsNullOrEmpty(NativeGameObjectName))
            return IntPtr.Zero;

        var NativeComponentsCount = vars.Helper.Read<int>(NativeGameObjectPtr + 0x30 /* GameObject.m_Component */ + 0x10 /* dynamic_array.m_size */);
        if (NativeComponentsCount == 0)
            return IntPtr.Zero;

        var RootTransformPtr = vars.Helper.Read<IntPtr>(NativeGameObjectPtr + 0x30 /* GameObject.m_Component */, 0x8 /* ComponentPair.component */); // First component is GameObject's root Transform
        var RootTransformChildCount = vars.Helper.Read<int>(RootTransformPtr + 0x70 /* Transform.m_Children */ + 0x10 /* dynamic_array.m_size */);
        for (int i = 0; i < RootTransformChildCount; ++i)
        {
            var NativeChildTransformPtr = vars.Helper.Read<IntPtr>(RootTransformPtr + 0x70 /* Transform.m_Children */, i * 0x8 /* ImmediatePtr */);
            var NativeChildGameObjectPtr = vars.Helper.Read<IntPtr>(NativeChildTransformPtr + 0x30 /* Unity::Component.m_GameObject */);
            var ManagedChildGameObjectPtr = vars.Helper.Read<IntPtr>(NativeChildGameObjectPtr + 0x18 /* Object.m_MonoReference */ + 0x10 /* ScriptingGCHandle.m_Object */);
            var ManagedComponentPtr = GameObjectFindComponentByName(ManagedChildGameObjectPtr, ComponentName);
            if (ManagedComponentPtr != IntPtr.Zero)
                return ManagedComponentPtr;
        }

        for (int i = 0; i < NativeComponentsCount; ++i)
        {
            var NativeComponentPtr = vars.Helper.Read<IntPtr>(NativeGameObjectPtr + 0x30 /* GameObject.m_Component */, i * 0x10 /* ComponentPair */ + 0x8 /* ComponentPair.component */);
            var ManagedComponentPtr = vars.Helper.Read<IntPtr>(NativeComponentPtr + 0x18 /* Object.m_MonoReference */ + 0x10 /* ScriptingGCHandle.m_Object */);
            var ManagedComponentName = vars.Helper.ReadString(256, ReadStringType.AutoDetect, ManagedComponentPtr /* MonoObject.vtable */, 0x0 /* MonoVTable.klass */, 0x48 /* MonoClass.name */, 0x0 /* char* */);
            if (!string.IsNullOrEmpty(ManagedComponentName) && ManagedComponentName == ComponentName)
                return ManagedComponentPtr;
        }

        return IntPtr.Zero;
    };

    Func<IntPtr, string, IntPtr> SceneFindComponentByName = (ScenePtr, ComponentName) =>
    {
        if (ScenePtr == IntPtr.Zero)
            return IntPtr.Zero;

        var SceneObjectsPrevPtr = vars.Helper.Read<IntPtr>(ScenePtr + 0xB0 /* UnityScene.m_Roots */ + 0x0 /* List.m_Root */ + 0x0 /* ListElement.m_Prev */);
        var SceneObjectsNextPtr = vars.Helper.Read<IntPtr>(ScenePtr + 0xB0 /* UnityScene.m_Roots */ + 0x0 /* List.m_Root */ + 0x8 /* ListElement.m_Next */);

        for (var AddressIt = SceneObjectsNextPtr; AddressIt != SceneObjectsPrevPtr && AddressIt != IntPtr.Zero; AddressIt = vars.Helper.Read<IntPtr>(AddressIt + 0x8 /* ListElement.m_Prev */))
        {
            var NativeTransformPtr = vars.Helper.Read<IntPtr>(AddressIt + 0x10 /* ListNode.m_Data */);
            var NativeGameObjectPtr = vars.Helper.Read<IntPtr>(NativeTransformPtr + 0x30 /* Unity::Component.m_GameObject */);
            var ManagedGameObjectPtr = vars.Helper.Read<IntPtr>(NativeGameObjectPtr + 0x18 /* Object.m_MonoReference */ + 0x10 /* ScriptingGCHandle.m_Object */);
            var ManagedComponentPtr = GameObjectFindComponentByName(ManagedGameObjectPtr, ComponentName);
            if (ManagedComponentPtr != IntPtr.Zero)
                return ManagedComponentPtr;
        }

        return IntPtr.Zero;
    };

    Func<IntPtr, string, IntPtr> SceneManagerFindComponentByName = (SceneManagerPtr, ComponentName) =>
    {
        if (SceneManagerPtr == IntPtr.Zero)
            return IntPtr.Zero;

        var SceneCount = vars.Helper.Read<int>(SceneManagerPtr + 0x8 /* RuntimeSceneManager.m_Scenes */ + 0x10 /* dynamic_array.m_size */);
        for (int i = 0; i < SceneCount; ++i)
        {
            var ScenePtr = vars.Helper.Read<IntPtr>(SceneManagerPtr + 0x8 /* RuntimeSceneManager.m_Scenes */, i * IntPtr.Size /* UnityScene* */);
            var ScenePath = vars.Helper.ReadString(256, ReadStringType.AutoDetect, ScenePtr + 0x10 /* UnityScene.m_ScenePath */, 0x0 /* char* */);
            var SceneName = System.IO.Path.GetFileNameWithoutExtension(ScenePath);
            var ManagedComponentPtr = SceneFindComponentByName(ScenePtr, ComponentName);
            if (ManagedComponentPtr != IntPtr.Zero)
                return ManagedComponentPtr;
        }

        return IntPtr.Zero;
    };

    vars.FindComponentByName = (Func<string, IntPtr>)(ComponentName =>
    {
        var SceneManagerPtr = vars.SceneManagerAddress.GetValue(IntPtr.Zero);
        print("SceneManagerPtr: " + SceneManagerPtr);
        return SceneManagerFindComponentByName(vars.Helper.Read<IntPtr>(SceneManagerPtr), ComponentName);
    });

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var MainScr = mono["MainScr"];
        vars.Helper["IsLoading"] = MainScr.Make<bool>("sys_scene_loading");

        var BossRematchManager = mono["BossRematchManager"];
        vars.Helper["BossRushIsActive"] = BossRematchManager.Make<bool>("active");

        var Platformer3D = mono["Platformer3D"];
        vars.Helper["PlayerHP"] = Platformer3D.Make<float>("player_hp");

        var CommonEnemy = mono["CommonEnemy"];
        vars.Helper["TargetEnemyIsDead"] = MainScr.Make<bool>("p3d", Platformer3D["TargetEnemy"], CommonEnemy["dead"]);
        
        var BossScr = mono["BossHPBarScr"];
        vars.Helper["BossIsActive"] = BossScr.Make<bool>("active");
        vars.Helper["BossHP"] = BossScr.Make<float>("BossEnemyComponent", CommonEnemy["hp"]);
        vars.Helper["BossIsDead"] = BossScr.Make<bool>("BossEnemyComponent", CommonEnemy["dead"]);

        var BossNamesScr = mono["BossNamesScr"];
        vars.Helper["BossId"] = BossNamesScr.MakeString("bossname");

        var DialogueManager = mono["DialogueManager"];
        vars.Helper["DialogueQueueLength"] = MainScr.Make<int>("dialogueManager", DialogueManager["queue"], 0x28);

        var FirstBrightnessSetup = mono["FirstBrightnessSetup"];
        var FirstBrightnessSetupPtr = vars.FindComponentByName("FirstBrightnessSetup");
        vars.Helper["BrightnessScreenMode"] = vars.Helper.Make<int>(FirstBrightnessSetupPtr + FirstBrightnessSetup["m_mode"]);

        var StaffRoll = mono["StaffRoll"];
        vars.Helper["StaffRollActive"] = StaffRoll.Make<bool>("active");

        var GameData = mono["GameData"];
        var MomoEventData = mono["MomoEventData"];
        vars.Helper["Events"] = GameData.MakeArray<int>("current", "MomoEvent", MomoEventData["m_events"]);

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
    current.BossIsDead = current.BossHP == 0;

    if (old.Scene != current.Scene)
    {
        print("Scene Transition: " + old.Scene + " > " + current.Scene + " Address: " + vars.Helper.Scenes.Active.Address);
    }

    if (current.BossIsActive && old.BossHP != current.BossHP)
    {
        print("Boss Damage " + vars.Strings[current.BossId] + " HP: " + current.BossHP);
    }

    if (current.BossIsActive && current.BossIsDead && !old.BossIsDead)
    {
        print("Boss Dead: " + vars.Strings[current.BossId]);
    }

    if (!old.StaffRollActive && current.StaffRollActive)
    {
        print("StaffRollActive: " + current.StaffRollActive);
    }

    for (int i = 0; i < 512; ++i)
    {
        if (old.Events[i] != current.Events[i])
        {
            print("Event: " + i + " = " + current.Events[i]);
        }
    }
}

start
{
    // on first Momo dialog
    // return current.Scene == "Well01" && current.DialogueQueueLength == 3;

    // on new game started
    // return current.Scene == "BrightnessSetup";

    // on game mode select
    return old.BrightnessScreenMode == 2 && current.BrightnessScreenMode == 3;
}

split
{
    // Selin final blow
    // if (current.BossIsActive && current.BossId == "boss_20" && !old.BossIsDead && current.BossIsDead)
    //     return true;

    // Final dialog with Dora
    if (current.Scene == "Koho19" && current.DialogueQueueLength == 34)
        return true;
}
