using System;
using System.Collections.Generic;
using UnityEngine;

namespace CargoV2.QA
{
    public sealed class SCR_QATester : MonoBehaviour
    {
        [Serializable]
        public sealed class Result
        {
            public string check;
            public bool passed;
            public string details;
        }

        [SerializeField] private bool runOnStart = true;
        [SerializeField] private List<Result> lastResults = new List<Result>();

        public IReadOnlyList<Result> LastResults => lastResults;
        public bool AllPassed
        {
            get
            {
                if (lastResults.Count == 0) return false;
                for (int i = 0; i < lastResults.Count; i++)
                {
                    if (!lastResults[i].passed) return false;
                }
                return true;
            }
        }

        private void Start()
        {
            if (runOnStart) RunSmokeSuite();
        }

        [ContextMenu("Run CARGO V2 Smoke Suite")]
        public void RunSmokeSuite()
        {
            lastResults.Clear();
            Check("Screen size", Screen.width > 0 && Screen.height > 0, $"{Screen.width}x{Screen.height}");
            Check("Target frame rate", Application.targetFrameRate == -1 || Application.targetFrameRate >= 30, $"target={Application.targetFrameRate}");
            Check("Persistent path", !string.IsNullOrWhiteSpace(Application.persistentDataPath), Application.persistentDataPath);
            Check("Audio listener", FindFirstObjectByType<AudioListener>() != null, "AudioListener required for CARGO V2 audio QA");

            Debug.Log($"[CARGO V2][QA] Smoke suite {(AllPassed ? "PASS" : "FAIL")} checks={lastResults.Count}");
            for (int i = 0; i < lastResults.Count; i++)
            {
                Result result = lastResults[i];
                Debug.Log($"[CARGO V2][QA] {(result.passed ? "PASS" : "FAIL")} {result.check}: {result.details}");
            }
        }

        public void Check(string name, bool passed, string details)
        {
            lastResults.Add(new Result { check = name, passed = passed, details = details });
        }
    }
}
