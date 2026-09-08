using CargoV2.Data;
using UnityEngine;

namespace CargoV2.UI
{
    /// <summary>
    /// Lightweight project-original feedback layer. Audio is synthesized
    /// deterministically at runtime; no third-party or unlicensed media is loaded.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class SCR_PlayerFeedback : MonoBehaviour
    {
        public enum Cue
        {
            Ui = 0,
            Pickup = 1,
            Checkpoint = 2,
            Delivery = 3,
            Impact = 4,
            Error = 5,
        }

        private const int SampleRate = 22050;
        private static SCR_PlayerFeedback instance;

        private AudioSource sfxSource;
        private AudioSource engineSource;
        private AudioClip uiClip;
        private AudioClip pickupClip;
        private AudioClip checkpointClip;
        private AudioClip deliveryClip;
        private AudioClip impactClip;
        private AudioClip errorClip;
        private AudioClip engineClip;
        private CargoV2PlayerSettings.Snapshot settings;
        private bool lifecycleMuted;
        private bool engineRequested;
        private float requestedEngineAmount;
        private float requestedEngineThrottle;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Install()
        {
            EnsureInstance();
        }

        private static SCR_PlayerFeedback EnsureInstance()
        {
            if (instance != null) return instance;
            GameObject host = new GameObject("CARGO_V2_PlayerFeedback");
            instance = host.AddComponent<SCR_PlayerFeedback>();
            DontDestroyOnLoad(host);
            return instance;
        }

        private void Awake()
        {
            if (instance != null && instance != this)
            {
                Destroy(gameObject);
                return;
            }

            instance = this;
            DontDestroyOnLoad(gameObject);
            settings = CargoV2PlayerSettings.Load();
            BuildSources();
            BuildOriginalClips();
            CargoV2PlayerSettings.Changed += HandleSettingsChanged;
            ApplySettings();
        }

        private void OnDestroy()
        {
            CargoV2PlayerSettings.Changed -= HandleSettingsChanged;
            if (instance == this) instance = null;
            DestroyClip(uiClip);
            DestroyClip(pickupClip);
            DestroyClip(checkpointClip);
            DestroyClip(deliveryClip);
            DestroyClip(impactClip);
            DestroyClip(errorClip);
            DestroyClip(engineClip);
        }

        public static void Play(Cue cue, float intensity = 1f, bool haptic = false)
        {
            SCR_PlayerFeedback feedback = EnsureInstance();
            if (feedback == null) return;
            feedback.PlayInternal(cue, Mathf.Clamp01(intensity), haptic);
        }

        public static void StartEngine()
        {
            SCR_PlayerFeedback feedback = EnsureInstance();
            if (feedback == null) return;
            feedback.engineRequested = true;
            feedback.ApplyEngineState();
        }

        public static void SetEngineState(float normalizedSpeed, float throttle)
        {
            SCR_PlayerFeedback feedback = EnsureInstance();
            if (feedback == null) return;
            feedback.engineRequested = true;
            feedback.requestedEngineAmount = Mathf.Clamp01(normalizedSpeed);
            feedback.requestedEngineThrottle = Mathf.Clamp01(Mathf.Abs(throttle));
            feedback.ApplyEngineState();
        }

        public static void StopEngine()
        {
            if (instance == null) return;
            instance.engineRequested = false;
            instance.requestedEngineAmount = 0f;
            instance.requestedEngineThrottle = 0f;
            if (instance.engineSource != null) instance.engineSource.Stop();
        }

        private void BuildSources()
        {
            sfxSource = gameObject.AddComponent<AudioSource>();
            sfxSource.playOnAwake = false;
            sfxSource.loop = false;
            sfxSource.spatialBlend = 0f;
            sfxSource.priority = 64;

            engineSource = gameObject.AddComponent<AudioSource>();
            engineSource.playOnAwake = false;
            engineSource.loop = true;
            engineSource.spatialBlend = 0f;
            engineSource.priority = 96;
        }

        private void BuildOriginalClips()
        {
            uiClip = CreateTone("CARGO_V2_UI", 620f, 0.055f, 0.18f, 0f);
            pickupClip = CreateTone("CARGO_V2_Pickup", 430f, 0.16f, 0.26f, 0.62f);
            checkpointClip = CreateTone("CARGO_V2_Checkpoint", 690f, 0.12f, 0.24f, 0.80f);
            deliveryClip = CreateTone("CARGO_V2_Delivery", 520f, 0.34f, 0.32f, 1.05f);
            impactClip = CreateTone("CARGO_V2_Impact", 105f, 0.11f, 0.30f, -0.22f);
            errorClip = CreateTone("CARGO_V2_Error", 180f, 0.18f, 0.23f, -0.35f);
            engineClip = CreateEngineLoop();
            if (engineSource != null) engineSource.clip = engineClip;
        }

        private static AudioClip CreateTone(string name, float frequency, float duration, float gain, float sweep)
        {
            int count = Mathf.Max(64, Mathf.CeilToInt(SampleRate * duration));
            float[] samples = new float[count];
            float phase = 0f;
            for (int i = 0; i < count; i++)
            {
                float t = i / (float)Mathf.Max(1, count - 1);
                float envelope = Mathf.Sin(Mathf.PI * Mathf.Clamp01(t));
                float f = Mathf.Max(35f, frequency * (1f + sweep * (t - 0.5f)));
                phase += (Mathf.PI * 2f * f) / SampleRate;
                float fundamental = Mathf.Sin(phase);
                float harmonic = Mathf.Sin(phase * 2.01f) * 0.22f;
                samples[i] = (fundamental + harmonic) * gain * envelope;
            }

            AudioClip clip = AudioClip.Create(name, count, 1, SampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }

        private static AudioClip CreateEngineLoop()
        {
            int count = SampleRate / 2;
            float[] samples = new float[count];
            for (int i = 0; i < count; i++)
            {
                float t = i / (float)SampleRate;
                float baseWave = Mathf.Sin(Mathf.PI * 2f * 54f * t);
                float second = Mathf.Sin(Mathf.PI * 2f * 108f * t + 0.22f) * 0.32f;
                float third = Mathf.Sin(Mathf.PI * 2f * 27f * t) * 0.18f;
                samples[i] = (baseWave + second + third) * 0.22f;
            }

            AudioClip clip = AudioClip.Create("CARGO_V2_Engine_Original", count, 1, SampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }

        private void PlayInternal(Cue cue, float intensity, bool haptic)
        {
            if (haptic && !lifecycleMuted && settings.Haptics && Application.isMobilePlatform)
            {
                Handheld.Vibrate();
            }

            if (sfxSource == null || lifecycleMuted || settings.Muted || settings.MasterVolume <= 0f || settings.SfxVolume <= 0f) return;
            AudioClip clip = ResolveClip(cue);
            if (clip != null) sfxSource.PlayOneShot(clip, Mathf.Lerp(0.45f, 1f, intensity));
        }

        private AudioClip ResolveClip(Cue cue)
        {
            switch (cue)
            {
                case Cue.Pickup: return pickupClip;
                case Cue.Checkpoint: return checkpointClip;
                case Cue.Delivery: return deliveryClip;
                case Cue.Impact: return impactClip;
                case Cue.Error: return errorClip;
                default: return uiClip;
            }
        }

        private void HandleSettingsChanged(CargoV2PlayerSettings.Snapshot snapshot)
        {
            settings = snapshot;
            ApplySettings();
        }

        private void ApplySettings()
        {
            bool mute = lifecycleMuted || settings.Muted;
            if (sfxSource != null)
            {
                sfxSource.mute = mute;
                sfxSource.volume = Mathf.Clamp01(settings.MasterVolume * settings.SfxVolume);
            }
            if (engineSource != null)
            {
                engineSource.mute = mute;
                ApplyEngineState();
            }
        }

        private void ApplyEngineState()
        {
            if (engineSource == null || engineClip == null) return;
            if (!engineRequested)
            {
                if (engineSource.isPlaying) engineSource.Stop();
                return;
            }

            engineSource.pitch = Mathf.Lerp(0.78f, 1.48f, requestedEngineAmount) + requestedEngineThrottle * 0.08f;
            float activity = Mathf.Clamp01(0.22f + requestedEngineAmount * 0.55f + requestedEngineThrottle * 0.23f);
            engineSource.volume = Mathf.Clamp01(settings.MasterVolume * settings.EngineVolume * activity);
            engineSource.mute = lifecycleMuted || settings.Muted;
            if (!engineSource.isPlaying && !engineSource.mute) engineSource.Play();
        }

        private void OnApplicationPause(bool paused)
        {
            lifecycleMuted = paused;
            ApplySettings();
        }

        private void OnApplicationFocus(bool focused)
        {
            lifecycleMuted = !focused;
            ApplySettings();
        }

        private static void DestroyClip(AudioClip clip)
        {
            if (clip != null) Destroy(clip);
        }
    }
}
