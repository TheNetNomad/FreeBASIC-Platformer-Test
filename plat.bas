#include once "inc/raylib.bi"

CONST SCREEN_WIDTH = 256 * 4
CONST SCREEN_HEIGHT = 192 * 4
CONST CAMERA_Y_OFF = 2
CONST CAMERA_Z_OFF = 15
CONST CAMERA_HEIGHT = 3

INITWINDOW( SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib Platformer Test" )

DIM AS VECTOR3 PLAYER_POS = VECTOR3(0,0,0)
DIM AS DOUBLE OLDTIME = 0
DIM AS DOUBLE ROTATION = 0
DIM AS DOUBLE SIN_CAM = 0
DIM AS DOUBLE COS_CAM = 0
DIM AS DOUBLE TEMPX = 0
DIM AS DOUBLE TEMPZ = 0
DIM AS DOUBLE FORWARDX = 0
DIM AS DOUBLE FORWARDZ = 0
VAR DEBOUNCE = 0

DIM AS CAMERA3D CAMERA
CAMERA.POSITION = VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + CAMERA_Y_OFF, PLAYER_POS.Z + CAMERA_Z_OFF)
CAMERA.TARGET = VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + CAMERA_HEIGHT, PLAYER_POS.Z)
CAMERA.UP = VECTOR3(0, 1, 0)
CAMERA.FOVY = 40
CAMERA.TYPE = CAMERA_PERSPECTIVE

DIM AS IMAGE CHECKERS = GENIMAGECHECKED(1000, 1000, 1, 1, RAYGREEN, DARKGREEN)
DIM AS TEXTURE2D TEXTURE = LOADTEXTUREFROMIMAGE(CHECKERS)

DIM AS MODEL FLOOR = LOADMODELFROMMESH(GENMESHPLANE(2, 2, 5, 5))
FLOOR.MATERIALS[0].MAPS[MAP_DIFFUSE].TEXTURE = TEXTURE


MAIN:
	OLDTIME = GETTIME()

	BEGINDRAWING()
		CLEARBACKGROUND(SKYBLUE)
		BEGINMODE3D(CAMERA)
			DRAWSPHERE( VECTOR3( PLAYER_POS.X, PLAYER_POS.Y + 0.75, PLAYER_POS.Z), 0.8, RAYBLUE )
	
			DrawCube(VECTOR3(0,0,-20),10,5,10,BROWN)
			DrawCube(VECTOR3(0,0,20),10,5,10,RAYRED)
			DrawCube(VECTOR3(20,0,0),10,5,10,RAYBLUE)
			DrawCube(VECTOR3(-20,0,0),10,5,10,YELLOW)
			
			DRAWMODEL(FLOOR, Vector3(0,0,0), 1000, WHITE )
		ENDMODE3D()
		
		DrawText( str(rotation), 0,0,40, RAYRED )
		DrawText( str(PLAYER_POS.X), 0,40,40, RAYRED )
		DrawText( str(PLAYER_POS.Y), 0,80,40, RAYRED )
		DrawText( str(PLAYER_POS.Z), 0,120,40, RAYRED )
	ENDDRAWING()
	
	IF ISKEYDOWN(KEY_LEFT) THEN ROTATION =  -.1 ELSE IF ISKEYDOWN(KEY_RIGHT) THEN ROTATION =  .1 ELSE ROTATION = 0
	
	SIN_CAM = sin(ROTATION)
	COS_CAM = cos(ROTATION)

	TEMPX = CAMERA.POSITION.X - PLAYER_POS.X
	TEMPZ = CAMERA.POSITION.Z - PLAYER_POS.Z

	CAMERA.POSITION.X = (COS_CAM * TEMPX - SIN_CAM * TEMPZ) + PLAYER_POS.X
	CAMERA.POSITION.Y = PLAYER_POS.Y + CAMERA_Y_OFF
	CAMERA.POSITION.Z = (SIN_CAM * TEMPX + COS_CAM * TEMPZ) + PLAYER_POS.Z

	CAMERA.TARGET = VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + CAMERA_HEIGHT, PLAYER_POS.Z)
	
	TEMPX = PLAYER_POS.X - CAMERA.POSITION.X
	TEMPZ = PLAYER_POS.Z - CAMERA.POSITION.Z
		
	IF ISKEYDOWN(KEY_UP) THEN 
		PLAYER_POS.X += TEMPX/10
		PLAYER_POS.Z += TEMPZ/10
		CAMERA.POSITION.X += TEMPX/10
		CAMERA.POSITION.Z += TEMPZ/10
	END IF
	IF ISKEYDOWN(KEY_DOWN) THEN 		
		PLAYER_POS.X -= TEMPX/10
		PLAYER_POS.Z -= TEMPZ/10
		CAMERA.POSITION.X -= TEMPX/10
		CAMERA.POSITION.Z -= TEMPZ/10
	ENDIF 
	
REST:
	IF GETTIME() - OLDTIME < 1 / 60 THEN SLEEP 1:GOTO REST

IF NOT WINDOWSHOULDCLOSE() THEN GOTO MAIN

END:
CLOSEWINDOW()
