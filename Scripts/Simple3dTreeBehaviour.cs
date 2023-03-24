using DaggerfallWorkshop.Game;
using DaggerfallWorkshop.Game.Utility.ModSupport;
using DaggerfallWorkshop.Game.Utility.ModSupport.ModSettings;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;

public class Simple3dTreeBehaviour : MonoBehaviour
{
    static Mod mod;

    static bool hasHD = false;

    static Dictionary<string, Material> modMaterials = new Dictionary<string, Material>();

    [Invoke(StateManager.StateTypes.Start, 0)]
    public static void Init(InitParams initParams)
    {
        mod = initParams.Mod;

        foreach(var file in mod.ModInfo.Files)
        {
            if(file.EndsWith(".mat"))
            {
                var materialFileName = Path.GetFileName(file);
                if (!ModManager.Instance.TryGetAsset(materialFileName, clone: false, out Material mat))
                    continue;

                var materialName = Path.GetFileNameWithoutExtension(materialFileName);
                modMaterials.Add(materialName, mat);
            }
        }

        mod.LoadSettingsCallback = LoadSettings;
        mod.LoadSettings();
        mod.IsReady = true;
    }

    static void LoadSettings(ModSettings modSettings, ModSettingsChange change)
    {
        hasHD = modSettings.GetBool("Core", "HighDefinition");

        foreach(Simple3dTreeBehaviour s3dtree in FindObjectsOfType<Simple3dTreeBehaviour>())
        {
            s3dtree.UpdateMaterials();
        }
    }

    private void Awake()
    {
        UpdateMaterials();
    }

    void UpdateMaterials()
    {
        foreach (Renderer renderer in GetComponentsInChildren<Renderer>())
        {
            var materials = renderer.sharedMaterials;
            bool changed = false;

            if (hasHD)
            {
                for (int i = 0; i < materials.Length; ++i)
                {
                    string name = materials[i].name.Split(' ')[0];
                    if (!name.EndsWith("_4x"))
                    {
                        string newName = name + "_4x";
                        if (modMaterials.TryGetValue(newName, out Material newMat))
                        {
                            materials[i] = newMat;
                            changed = true;
                        }
                    }
                }
            }
            else
            {
                for (int i = 0; i < materials.Length; ++i)
                {
                    string name = materials[i].name.Split(' ')[0];
                    if (name.EndsWith("_4x"))
                    {
                        string newName = name.Substring(0, name.Length - 3);
                        if (modMaterials.TryGetValue(newName, out Material newMat))
                        {
                            materials[i] = newMat;
                            changed = true;
                        }
                    }
                }
            }

            if (changed)
            {
                renderer.sharedMaterials = materials;
                renderer.materials = renderer.sharedMaterials;
            }
        }
    }
}
