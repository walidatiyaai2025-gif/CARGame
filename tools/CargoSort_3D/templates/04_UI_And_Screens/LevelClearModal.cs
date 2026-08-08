using System;
using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
namespace CargoSort3D
{
    [DisallowMultipleComponent]
    public sealed class LevelClearModal:MonoBehaviour
    {
        public event Action ContinuePressed,ReplayPressed;
        [SerializeField] CanvasGroup canvasGroup; [SerializeField] RectTransform panel; [SerializeField] RectTransform[] stars; [SerializeField] Graphic[] starGraphics; [SerializeField] Color earnedStarColor=new(1f,.85f,.25f,1f),emptyStarColor=new(.25f,.32f,.40f,.65f); [SerializeField] TMP_Text coinCounter,scoreText,bestText; [SerializeField] Button continueButton,replayButton; [SerializeField] ParticleSystem celebrationParticles; [SerializeField] float panelDuration=.38f,starDuration=.32f,starInterval=.17f,coinRollDuration=.9f; Coroutine routine;
        void Awake(){if(continueButton)continueButton.onClick.AddListener(()=>ContinuePressed?.Invoke());if(replayButton)replayButton.onClick.AddListener(()=>ReplayPressed?.Invoke());SetHidden();}
        public void Present(int earnedStars,int coinsEarned,int score,int bestScore){if(routine!=null)StopCoroutine(routine);gameObject.SetActive(true);routine=StartCoroutine(PresentRoutine(Mathf.Clamp(earnedStars,0,3),Mathf.Max(0,coinsEarned),score,bestScore));}
        public void Hide(){if(routine!=null)StopCoroutine(routine);routine=null;SetHidden();gameObject.SetActive(false);}
        IEnumerator PresentRoutine(int earned,int coins,int score,int best){canvasGroup.alpha=0;canvasGroup.interactable=false;canvasGroup.blocksRaycasts=true;panel.localScale=Vector3.one*.72f;if(coinCounter)coinCounter.text="0";if(scoreText)scoreText.text=score.ToString("N0");if(bestText)bestText.text=best.ToString("N0");for(int i=0;i<stars.Length;i++){if(stars[i])stars[i].localScale=Vector3.one*.05f;if(i<starGraphics.Length&&starGraphics[i])starGraphics[i].color=emptyStarColor;}float e=0;while(e<panelDuration){e+=Time.unscaledDeltaTime;float t=Mathf.Clamp01(e/panelDuration);canvasGroup.alpha=Mathf.Clamp01(t*1.6f);panel.localScale=Vector3.one*Mathf.LerpUnclamped(.72f,1,EaseOutBack(t));yield return null;}canvasGroup.alpha=1;panel.localScale=Vector3.one;for(int i=0;i<stars.Length;i++){bool ok=i<earned;if(i<starGraphics.Length&&starGraphics[i])starGraphics[i].color=ok?earnedStarColor:emptyStarColor;yield return AnimateStar(stars[i],ok);if(ok&&celebrationParticles)celebrationParticles.Emit(Mathf.Max(8,14+i*4));if(starInterval>0)yield return new WaitForSecondsRealtime(starInterval);}yield return RollCoins(coins);canvasGroup.interactable=true;routine=null;}
        IEnumerator AnimateStar(RectTransform star,bool earned){if(!star)yield break;float target=earned?1:.86f,startRot=earned?-24:0,e=0;while(e<starDuration){e+=Time.unscaledDeltaTime;float t=Mathf.Clamp01(e/starDuration);star.localScale=Vector3.one*Mathf.LerpUnclamped(.05f,target,earned?EaseOutBack(t):EaseOutCubic(t));star.localRotation=Quaternion.Euler(0,0,Mathf.Lerp(startRot,0,EaseOutCubic(t)));yield return null;}star.localScale=Vector3.one*target;star.localRotation=Quaternion.identity;}
        IEnumerator RollCoins(int target){if(!coinCounter)yield break;float e=0;while(e<coinRollDuration){e+=Time.unscaledDeltaTime;coinCounter.text=Mathf.RoundToInt(Mathf.Lerp(0,target,EaseOutCubic(Mathf.Clamp01(e/coinRollDuration)))).ToString("N0");yield return null;}coinCounter.text=target.ToString("N0");}
        void SetHidden(){if(canvasGroup){canvasGroup.alpha=0;canvasGroup.interactable=false;canvasGroup.blocksRaycasts=false;}if(panel)panel.localScale=Vector3.one*.8f;}
        static float EaseOutCubic(float t)=>1-Mathf.Pow(1-t,3); static float EaseOutBack(float t){const float c1=1.70158f,c3=c1+1;return 1+c3*Mathf.Pow(t-1,3)+c1*Mathf.Pow(t-1,2);}
    }
}
