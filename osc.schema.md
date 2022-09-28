

# main osc control schema

## sound
```
/track/start (trackId: int)
/track/stop
```

## mirrors

```
[angle: (float) 360.0f = 1 full rotation, 0 = up, 180 = down]
[coord: (float) 0 = left / up, 1: right / down]
[objectId: either mirror or moving head]

/mirror/calibrate
/mirror/offset (mirror_id: int) (angle_offset: angle)

/mirror/global/rotation/angle (angle: angle)                      // global set rotation by angle
/mirror/rotation/angle (mirror_id: int) (angle: angle)            // set rotation by angle

/mirror/global/rotation/xy (x: coord) (y: coord)                  // global set rotation by xy coord in room
/mirror/rotation/xy (mirror_id: int) (x: coord) (y: coord)        // set rotation by xy coord in room

/mirror/global/rotation/object (object_id: int)                   // global set rotation by object id
/mirror/rotation/object (mirror_id: int) (object_id: int)         // set rotation by object id

/mirror/reflect/enable (mirror_id: int) (angle_from: angle)       // rotation calculated to reflect light from angle_from to angle or xy
/mirror/reflect/enable (mirror_id: int) (object_id: int)          // rotation calculated to reflect light from objectId to angle or xy
/mirror/reflect/disable                                           // disable reflection calculation
```

## smartphones

## led bars

## beamer
