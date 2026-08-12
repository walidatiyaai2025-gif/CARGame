# RT3D-002 next checkpoint

The next implementation checkpoint starts only from the first renderer candidate that passes the source-controlled admission policy.

Execution order:

1. evaluate stable-Flutter native renderer candidates against the scorecard;
2. admit exactly one dependency through normal dependency governance;
3. implement its adapter behind `Realtime3dScenePort`;
4. admit the smallest real licensed model set: vehicle, cargo, warehouse/target, ground and road;
5. bind cargo pick/drag/snap/return to real scene nodes;
6. add camera orbit/follow, PBR lighting and bounded shadows;
7. expose the native scene from normal application navigation;
8. run focused RT3D-002 CI plus the complete Flutter CI;
9. merge only from a green exact head;
10. promote that exact main source into the root retained APK for owner visual review.

Backend/cloud/analytics and unrelated gameplay-system expansion remain deferred while issue #222 is open and the owner-facing native visual APK gate is incomplete.
