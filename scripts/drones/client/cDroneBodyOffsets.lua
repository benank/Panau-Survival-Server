DroneBodyPiece = 
{
    Base = 1,
    LeftGun = 3,
    RightGun = 4,
    TopGun = 5
}

-- Offets for the actual positions of where the bullets come out
DroneGunOffsets = 
{
    [DroneBodyPiece.LeftGun] = {position = Vector3(-0.25, 0.35, -0.25), angle = Angle()},
    [DroneBodyPiece.RightGun] = {position = Vector3(0.25, 0.35, -0.25), angle = Angle()},
    [DroneBodyPiece.TopGun] = {position = Vector3(0, 0.35, -0.15), angle = Angle()},
}

DroneEffectOffset = {position = Vector3(0, 0, 0.05), angle = Angle(0, math.pi, 0)}

DroneMuzzleFlashOffset = {position = Vector3(), angle = Angle(-math.pi / 2, 0, 0)}

DroneRedBlipOffset = {position = Vector3(0, 0.4, 0)}

DroneBodyObjects = 
{
    [DroneBodyPiece.Base] = 
    {
        model = "lave.v023_customcar.eez/v023-base.lod",
        collision = "lave.v023_customcar.eez/v023_lod1-base_col.pfx"
    },
    [DroneBodyPiece.LeftGun] = 
    {
        model = "lave.v023_customcar.eez/v023-vhlmgl.lod",
        collision = "lave.v023_customcar.eez/v023_lod1-vhlmgl_col.pfx"
    },
    [DroneBodyPiece.RightGun] = 
    {
        model = "lave.v023_customcar.eez/v023-vhlmgr.lod",
        collision = "lave.v023_customcar.eez/v023_lod1-vhlmgr_col.pfx"   
    },
    [DroneBodyPiece.TopGun] = 
    {
        model = "lave.v023_customcar.eez/v023-vhlrkt.lod",
        collision = "lave.v023_customcar.eez/v023_lod1-vhlrkt_col.pfx"
    }
}

DroneBodyOffsets = 
{
    [DroneBodyPiece.Base] = {position = Vector3(), angle = Angle()},
    [DroneBodyPiece.LeftGun] = {position = Vector3(-0.25, 0.35, 0), angle = Angle()},
    [DroneBodyPiece.RightGun] = {position = Vector3(0.25, 0.35, 0), angle = Angle()},
    [DroneBodyPiece.TopGun] = {position = Vector3(0, 0.2, 0), angle = Angle()}
}