using System;
using System.Collections;
using UnityEngine;
using UnityEngine.EventSystems;
namespace CargoSort3D
{
    [DisallowMultipleComponent,RequireComponent(typeof(Collider)),RequireComponent(typeof(Rigidbody))]
    public sealed class DragAndDrop3D:MonoBehaviour,IPointerDownHandler,IPointerUpHandler,IBeginDragHandler,IDragHandler,IEndDragHandler
    {
        public event Action<DragAndDrop3D> DragStarted,DragEnded;
        public event Action<DragAndDrop3D,Collider> DroppedOnTarget;
        [SerializeField] Camera gameplayCamera; [SerializeField] Renderer[] highlightRenderers;
        [SerializeField] LayerMask dragSurfaceMask=~0,dropTargetMask=~0; [SerializeField] float maximumRayDistance=100f,dropProbeRadius=.35f,liftHeight=.55f,dragSurfaceOffset=.08f;
        [SerializeField] float springStrength=72f,springDamping=14f,maxAcceleration=80f,maxDragVelocity=15f,rotationSharpness=14f,maximumTilt=6f,scaleSharpness=18f;
        [SerializeField] Vector3 pickupScale=new(.94f,1.10f,.94f),releaseScale=new(1.08f,.92f,1.08f);
        [SerializeField] float idleHighlight=0f,hoverHighlight=.75f,dragHighlight=1.35f;
        static readonly int HighlightStrength=Shader.PropertyToID("_HighlightStrength");
        Rigidbody body; Collider ownCollider; MaterialPropertyBlock block; Vector3 originalScale,desiredPosition,desiredScale; Quaternion originalRotation; bool dragging,hasPoint,pointerDown; Coroutine releaseRoutine;
        void Awake(){body=GetComponent<Rigidbody>();ownCollider=GetComponent<Collider>();gameplayCamera=gameplayCamera?gameplayCamera:Camera.main;if(highlightRenderers==null||highlightRenderers.Length==0)highlightRenderers=GetComponentsInChildren<Renderer>(true);block=new MaterialPropertyBlock();originalScale=transform.localScale;desiredScale=originalScale;originalRotation=transform.rotation;body.interpolation=RigidbodyInterpolation.Interpolate;body.collisionDetectionMode=CollisionDetectionMode.ContinuousSpeculative;SetHighlight(idleHighlight);}
        void Update(){float s=1-Mathf.Exp(-scaleSharpness*Time.deltaTime);transform.localScale=Vector3.LerpUnclamped(transform.localScale,desiredScale,s);if(!dragging)return;Vector3 lv=transform.InverseTransformDirection(body.velocity);Quaternion tilt=originalRotation*Quaternion.Euler(Mathf.Clamp(-lv.z*.75f,-maximumTilt,maximumTilt),0,Mathf.Clamp(lv.x*.75f,-maximumTilt,maximumTilt));transform.rotation=Quaternion.Slerp(transform.rotation,tilt,1-Mathf.Exp(-rotationSharpness*Time.deltaTime));}
        void FixedUpdate(){if(!dragging||!hasPoint)return;Vector3 a=(desiredPosition-body.position)*springStrength-body.velocity*springDamping;body.AddForce(Vector3.ClampMagnitude(a,maxAcceleration),ForceMode.Acceleration);body.velocity=Vector3.ClampMagnitude(body.velocity,maxDragVelocity);}
        public void OnPointerDown(PointerEventData e){pointerDown=true;SetHighlight(hoverHighlight);} public void OnPointerUp(PointerEventData e){pointerDown=false;if(!dragging)SetHighlight(idleHighlight);}
        public void OnBeginDrag(PointerEventData e){if(!gameplayCamera)return;if(releaseRoutine!=null)StopCoroutine(releaseRoutine);dragging=true;body.useGravity=false;body.angularVelocity=Vector3.zero;body.drag=.5f;desiredScale=Vector3.Scale(originalScale,pickupScale);SetHighlight(dragHighlight);UpdatePoint(e.position);DragStarted?.Invoke(this);}
        public void OnDrag(PointerEventData e){if(dragging)UpdatePoint(e.position);} public void OnEndDrag(PointerEventData e){if(!dragging)return;dragging=false;hasPoint=false;body.useGravity=true;body.drag=0;Collider t=FindDropTarget();if(t)DroppedOnTarget?.Invoke(this,t);releaseRoutine=StartCoroutine(Release());DragEnded?.Invoke(this);}
        void UpdatePoint(Vector2 screen){Ray ray=gameplayCamera.ScreenPointToRay(screen);if(Physics.Raycast(ray,out RaycastHit hit,maximumRayDistance,dragSurfaceMask,QueryTriggerInteraction.Ignore)){desiredPosition=hit.point+hit.normal*dragSurfaceOffset+Vector3.up*liftHeight;hasPoint=true;return;}Plane plane=new(Vector3.up,new Vector3(0,transform.position.y-liftHeight,0));if(plane.Raycast(ray,out float d)){desiredPosition=ray.GetPoint(d)+Vector3.up*liftHeight;hasPoint=true;}}
        Collider FindDropTarget(){Collider best=null;float bestD=float.MaxValue;foreach(Collider c in Physics.OverlapSphere(transform.position,dropProbeRadius,dropTargetMask,QueryTriggerInteraction.Collide)){if(!c||c==ownCollider||c.transform.IsChildOf(transform))continue;float d=(c.ClosestPoint(transform.position)-transform.position).sqrMagnitude;if(d<bestD){bestD=d;best=c;}}return best;}
        IEnumerator Release(){desiredScale=Vector3.Scale(originalScale,releaseScale);SetHighlight(hoverHighlight);yield return new WaitForSeconds(.11f);desiredScale=originalScale;float e=0;while(e<.22f){e+=Time.deltaTime;transform.rotation=Quaternion.Slerp(transform.rotation,originalRotation,1-Mathf.Exp(-rotationSharpness*Time.deltaTime));yield return null;}transform.localScale=originalScale;SetHighlight(pointerDown?hoverHighlight:idleHighlight);releaseRoutine=null;}
        void SetHighlight(float value){if(highlightRenderers==null)return;foreach(Renderer r in highlightRenderers){if(!r)continue;r.GetPropertyBlock(block);block.SetFloat(HighlightStrength,value);r.SetPropertyBlock(block);}}
        void OnDrawGizmosSelected(){Gizmos.DrawWireSphere(transform.position,dropProbeRadius);}
    }
}
