using UnityEngine;
namespace CargoSort3D
{
    [DisallowMultipleComponent, RequireComponent(typeof(Camera))]
    public sealed class CameraSetup : MonoBehaviour
    {
        [SerializeField] Transform target;
        [SerializeField] Vector3 targetOffset=new(0f,.65f,0f);
        [SerializeField,Range(20,65)] float pitch=38f;
        [SerializeField,Range(-180,180)] float yaw=-45f;
        [SerializeField,Min(2)] float distance=10.5f;
        [SerializeField,Range(20,70)] float fieldOfView=38f;
        [SerializeField,Min(.01f)] float positionSmoothTime=.18f;
        [SerializeField,Min(.01f)] float rotationSharpness=12f;
        [SerializeField] Light keyLight;
        [SerializeField] Color keyLightColor=new(1f,.94f,.86f);
        [SerializeField,Range(0,4)] float keyLightIntensity=1.25f;
        [SerializeField,Range(0,1)] float shadowStrength=.72f;
        [SerializeField] Vector3 keyLightEuler=new(48f,-32f,0f);
        Camera cam; Vector3 velocity;
        void Awake(){cam=GetComponent<Camera>();cam.orthographic=false;cam.fieldOfView=fieldOfView;cam.allowHDR=true;cam.allowMSAA=true;cam.nearClipPlane=.15f;cam.farClipPlane=150f;ApplyLighting();SnapToTarget();}
        void LateUpdate(){if(!target)return;Vector3 focus=target.position+targetOffset;Quaternion rot=Quaternion.Euler(pitch,yaw,0);Vector3 pos=focus-rot*Vector3.forward*distance;transform.position=Vector3.SmoothDamp(transform.position,pos,ref velocity,positionSmoothTime);float t=1-Mathf.Exp(-rotationSharpness*Time.deltaTime);transform.rotation=Quaternion.Slerp(transform.rotation,rot,t);cam.fieldOfView=Mathf.Lerp(cam.fieldOfView,fieldOfView,t);}
        public void SetTarget(Transform t,bool snap=false){target=t;if(snap)SnapToTarget();}
        public void SetFraming(float d,float fov){distance=Mathf.Max(2,d);fieldOfView=Mathf.Clamp(fov,20,70);}
        public void SnapToTarget(){if(!target)return;Quaternion rot=Quaternion.Euler(pitch,yaw,0);transform.rotation=rot;transform.position=target.position+targetOffset-rot*Vector3.forward*distance;velocity=Vector3.zero;if(cam)cam.fieldOfView=fieldOfView;}
        void ApplyLighting(){if(!keyLight)return;keyLight.type=LightType.Directional;keyLight.color=keyLightColor;keyLight.intensity=keyLightIntensity;keyLight.shadows=LightShadows.Soft;keyLight.shadowStrength=shadowStrength;keyLight.transform.rotation=Quaternion.Euler(keyLightEuler);}
    }
}
