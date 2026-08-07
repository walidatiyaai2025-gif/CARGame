using System;
using System.Collections;
using TMPro;
using UnityEngine;
namespace CargoSort3D
{
    [DisallowMultipleComponent]
    public sealed class ComboFXManager:MonoBehaviour
    {
        public static ComboFXManager Instance{get;private set;} public event Action<int> ComboChanged;
        [SerializeField] float comboTimeout=2.2f; [SerializeField] int minimumComboForCelebration=2,baseMatchScore=100; [SerializeField] float comboScoreStep=.25f,floatingTextDuration=.72f,floatingTextRiseDistance=1.1f;
        [SerializeField] TMP_Text floatingTextPrefab; [SerializeField] Transform floatingTextRoot; [SerializeField] Camera gameplayCamera; [SerializeField] ParticleSystem comboParticlePrefab,matchParticlePrefab; [SerializeField] AudioSource sfxSource; [SerializeField] AudioClip matchClip,comboClip; [SerializeField] float pitchStep=.055f,maximumPitch=1.38f;
        int combo,totalScore; float lastMatch=-999f; public int CurrentCombo=>combo; public int TotalScore=>totalScore;
        void Awake(){if(Instance&&Instance!=this){Destroy(gameObject);return;}Instance=this;gameplayCamera=gameplayCamera?gameplayCamera:Camera.main;}
        void Update(){if(combo>0&&Time.unscaledTime-lastMatch>comboTimeout)ResetCombo();}
        public int RegisterMatch(Vector3 worldPosition,int matchedItemCount=3){if(matchedItemCount<=0)return 0;combo=Time.unscaledTime-lastMatch<=comboTimeout?combo+1:1;lastMatch=Time.unscaledTime;int score=Mathf.RoundToInt(baseMatchScore*matchedItemCount*(1+Mathf.Max(0,combo-1)*comboScoreStep));totalScore+=score;Spawn(matchParticlePrefab,worldPosition,1);if(combo>=minimumComboForCelebration)Spawn(comboParticlePrefab,worldPosition,1+Mathf.Min(combo,8)*.06f);if(floatingTextPrefab)StartCoroutine(FloatText(Instantiate(floatingTextPrefab,floatingTextRoot?floatingTextRoot:transform),worldPosition,score));PlayAudio();if(combo>=5&&(Application.platform==RuntimePlatform.Android||Application.platform==RuntimePlatform.IPhonePlayer))Handheld.Vibrate();ComboChanged?.Invoke(combo);return score;}
        public void ResetCombo(){if(combo==0)return;combo=0;ComboChanged?.Invoke(0);} public void ResetScore()=>totalScore=0;
        IEnumerator FloatText(TMP_Text text,Vector3 pos,int score){text.text=combo>=minimumComboForCelebration?$"COMBO x{combo}\n+{score:N0}":$"+{score:N0}";Transform t=text.transform;t.position=pos+Vector3.up*.35f;Vector3 start=t.position,end=start+Vector3.up*floatingTextRiseDistance,scale=t.localScale;float e=0;while(e<floatingTextDuration){e+=Time.unscaledDeltaTime;float n=Mathf.Clamp01(e/floatingTextDuration),s=1-Mathf.Pow(1-n,3);t.position=Vector3.LerpUnclamped(start,end,s);t.localScale=scale*Mathf.Lerp(.6f,1.15f,s);Color c=text.color;c.a=1-Mathf.SmoothStep(0,1,Mathf.InverseLerp(.58f,1,n));text.color=c;if(gameplayCamera)t.rotation=Quaternion.LookRotation(gameplayCamera.transform.forward,gameplayCamera.transform.up);yield return null;}Destroy(text.gameObject);}
        void Spawn(ParticleSystem prefab,Vector3 pos,float scale){if(!prefab)return;ParticleSystem p=Instantiate(prefab,pos,Quaternion.identity);p.transform.localScale*=scale;p.Play();Destroy(p.gameObject,Mathf.Max(1,p.main.duration+p.main.startLifetime.constantMax)+.5f);}
        void PlayAudio(){if(!sfxSource)return;AudioClip clip=combo>=minimumComboForCelebration&&comboClip?comboClip:matchClip;if(!clip)return;sfxSource.pitch=Mathf.Min(maximumPitch,1+Mathf.Max(0,combo-1)*pitchStep);sfxSource.PlayOneShot(clip);}
    }
}
