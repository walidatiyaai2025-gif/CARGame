using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace CargoSort3D
{
    [DisallowMultipleComponent]
    public sealed class WorldMap3DNodes:MonoBehaviour
    {
        [Serializable] public sealed class LevelNodeDefinition{public int levelId=1;public string displayName="Harbor";public Vector3 localPosition;public int requiredStars;public bool unlockedByDefault;}
        [Serializable] public sealed class NodeVisualSet{public GameObject lockedPrefab,availablePrefab,completedPrefab;}
        public enum NodeState{Locked,Available,Completed} public event Action<int> LevelSelected;
        [SerializeField] List<LevelNodeDefinition> levels=new(); [SerializeField] NodeVisualSet visualSet; [SerializeField] Transform nodesRoot; [SerializeField] float nodeAppearDelay=.045f,idleFloatFrequency=1.6f,idleFloatAmplitude=.08f;
        readonly Dictionary<int,RuntimeNode> runtime=new(); int earnedStars; sealed class RuntimeNode{public LevelNodeDefinition Def;public GameObject Obj;public NodeState State;public Vector3 Base;public float Phase;}
        sealed class NodeInput:MonoBehaviour{public int LevelId;public WorldMap3DNodes Owner;void OnMouseUpAsButton()=>Owner?.TrySelectLevel(LevelId);}
        void Start()=>BuildMap(); void Update(){float now=Time.unscaledTime;foreach(RuntimeNode n in runtime.Values)if(n.Obj)n.Obj.transform.localPosition=n.Base+Vector3.up*Mathf.Sin(now*idleFloatFrequency+n.Phase)*idleFloatAmplitude;}
        public void BuildMap(){Clear();if(!nodesRoot)nodesRoot=transform;for(int i=0;i<levels.Count;i++)Create(levels[i],Resolve(levels[i]),i);}
        public void SetProgress(int stars,IReadOnlyCollection<int> completed){earnedStars=Mathf.Max(0,stars);for(int i=0;i<levels.Count;i++){LevelNodeDefinition d=levels[i];NodeState s=completed!=null&&Contains(completed,d.levelId)?NodeState.Completed:Resolve(d);if(runtime.TryGetValue(d.levelId,out RuntimeNode old)&&old.State!=s){if(old.Obj)Destroy(old.Obj);runtime.Remove(d.levelId);Create(d,s,i);}}}
        public void TrySelectLevel(int id){if(!runtime.TryGetValue(id,out RuntimeNode n))return;if(n.State==NodeState.Locked){StartCoroutine(LockedFeedback(n.Obj.transform));return;}LevelSelected?.Invoke(id);}
        void Create(LevelNodeDefinition d,NodeState s,int index){GameObject prefab=s==NodeState.Completed?visualSet.completedPrefab:s==NodeState.Available?visualSet.availablePrefab:visualSet.lockedPrefab;if(!prefab)return;GameObject o=Instantiate(prefab,nodesRoot);o.name=$"LevelNode_{d.levelId:D3}_{d.displayName}";o.transform.localPosition=d.localPosition;o.transform.localRotation=Quaternion.identity;NodeInput input=o.GetComponent<NodeInput>()??o.AddComponent<NodeInput>();input.LevelId=d.levelId;input.Owner=this;runtime[d.levelId]=new RuntimeNode{Def=d,Obj=o,State=s,Base=d.localPosition,Phase=index*.73f};o.transform.localScale=Vector3.one*.01f;StartCoroutine(Entrance(o.transform,index*nodeAppearDelay));}
        NodeState Resolve(LevelNodeDefinition d)=>d.unlockedByDefault||earnedStars>=d.requiredStars?NodeState.Available:NodeState.Locked;
        IEnumerator Entrance(Transform t,float delay){if(delay>0)yield return new WaitForSecondsRealtime(delay);float e=0,d=.34f;while(e<d){e+=Time.unscaledDeltaTime;float x=Mathf.Clamp01(e/d)-1;float over=1+1.70158f*x*x*x+2.70158f*x*x;t.localScale=Vector3.one*Mathf.Max(.01f,over);yield return null;}t.localScale=Vector3.one;}
        IEnumerator LockedFeedback(Transform t){Quaternion q=t.localRotation;float e=0,d=.28f;while(e<d){e+=Time.unscaledDeltaTime;float n=e/d;t.localRotation=q*Quaternion.Euler(0,Mathf.Sin(n*Mathf.PI*6)*(1-n)*7,0);yield return null;}t.localRotation=q;}
        void Clear(){foreach(RuntimeNode n in runtime.Values)if(n.Obj)Destroy(n.Obj);runtime.Clear();}
        static bool Contains<T>(IReadOnlyCollection<T> c,T v){var cmp=EqualityComparer<T>.Default;foreach(T item in c)if(cmp.Equals(item,v))return true;return false;}
    }
}
