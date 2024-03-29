#INCLUDE ONCE "INC/RAYLIB.BI"

DECLARE FUNCTION BOXCOLLISION(SPOT AS VECTOR3, BOX AS VECTOR3, DIMENSIONS AS VECTOR3) AS BOOLEAN
DECLARE FUNCTION BOXSPHERECOLLISION(SPOT AS VECTOR3, RADIUS AS INTEGER, BOX AS VECTOR3, DIMENSIONS AS VECTOR3) AS BOOLEAN

CONST SCREEN_WIDTH = 256 * 4
CONST SCREEN_HEIGHT = 192 * 4
DIM AS SINGLE CAMERA_Y_OFF = 7
CONST CAMERA_Z_OFF = 15
CONST CAMERA_HEIGHT = 3
CONST MAX_SPEED = 20
CONST PLAYER_RADIUS = 0.8
CONST FALLING_SPEED = .75

INITWINDOW(SCREEN_WIDTH, SCREEN_HEIGHT, "RAYLIB FREEBASIC PLATFORMER TEST")
INITAUDIODEVICE()

BEGINDRAWING()
		DRAWTEXT("LOADING...",0,0,80,BLACK)
ENDDRAWING()

VAR I = 0
VAR J = 0
DIM AS VECTOR3 PLAYER_POS = VECTOR3(0,0,0)
DIM AS DOUBLE OLDTIME = 0
DIM AS DOUBLE GAMETIME = 0
DIM AS DOUBLE ROTATION = 0
DIM AS DOUBLE SIN_CAM = 0
DIM AS DOUBLE COS_CAM = 0
DIM AS DOUBLE TEMPX = 0
DIM AS DOUBLE TEMPZ = 0
VAR DEBOUNCE = 0
VAR ISJUMPING = FALSE
VAR ISFALLING = FALSE
VAR ISJUMPREADY = TRUE
VAR HANGTIME = 0
DIM JUMP_FLOOR AS SINGLE = 0
VAR COLLIDETEST = FALSE
VAR SPEED = 0
VAR CORRECTION_OFFSET = 0
VAR SOLVEDCOLLISION = FALSE
VAR JOYSTICKID = 0
VAR STRIG = 0
DIM X_AXIS AS SINGLE
DIM Y_AXIS AS SINGLE
DIM SHOULDER AS SINGLE
DIM CSTICK_X AS SINGLE
DIM CSTICK_Y AS SINGLE
DIM DPAD_X AS SINGLE
DIM DPAD_Y AS SINGLE
CONST FORWARDS = TRUE
CONST BACKWARDS = FALSE
VAR DIRECTION = FORWARDS
VAR ISHURT = 0
VAR IFRAMES = 0
VAR ISONGROUND = FALSE
VAR ISPAUSED = FALSE 

FOR I = 0 TO 10 
	GETJOYSTICK(I,STRIG)
	IF STRIG <> -1 THEN JOYSTICKID = I
NEXT I

VAR CHERRIES = 0
VAR LIVES = 3 
VAR ONEUP_THRESHOLD = 100

DIM AS CAMERA3D CAMERA
CAMERA.POSITION = VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + CAMERA_Y_OFF, PLAYER_POS.Z + CAMERA_Z_OFF)
CAMERA.TARGET = VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + CAMERA_HEIGHT, PLAYER_POS.Z)
CAMERA.UP = VECTOR3(0, 1, 0)
CAMERA.FOVY = 40
CAMERA.TYPE = CAMERA_PERSPECTIVE

DIM AS IMAGE CHECKERS = GENIMAGECHECKED(1000, 1000, 1, 1, RAYGREEN, DARKGREEN)
DIM AS TEXTURE2D CHERRY = LOADTEXTURE("CHERRY.PNG")
DIM AS TEXTURE2D FOE = LOADTEXTURE("IMP.PNG")

DIM AS TEXTURE2D TEXTURE = LOADTEXTUREFROMIMAGE(CHECKERS)

DIM AS MODEL FLOOR = LOADMODELFROMMESH(GENMESHPLANE(2, 2, 5, 5))
FLOOR.MATERIALS[0].MAPS[MAP_DIFFUSE].TEXTURE = TEXTURE

CONST CUBE_COUNT = 200
CONST CHERRY_COUNT = 200
CONST SPIKE_COUNT = 200
CONST FOE_COUNT = 200

DIM CHERRY_POSITIONS(CHERRY_COUNT) AS VECTOR3
CHERRY_POSITIONS(0) = VECTOR3(0,11,-30)
CHERRY_POSITIONS(1) = VECTOR3(30,21,0)
CHERRY_POSITIONS(2) = VECTOR3(0,31,30)
CHERRY_POSITIONS(3) = VECTOR3(-30,41,0)

DIM CHERRY_EXISTS(CHERRY_COUNT) AS BOOLEAN
CHERRY_EXISTS(0) = TRUE
CHERRY_EXISTS(1) = TRUE
CHERRY_EXISTS(2) = TRUE
CHERRY_EXISTS(3) = TRUE

DIM SPIKE_POSITIONS(CHERRY_COUNT) AS VECTOR3
DIM FOE_POSITIONS(CHERRY_COUNT) AS VECTOR3

DIM CUBE_POSITIONS(CUBE_COUNT) AS VECTOR3
CUBE_POSITIONS(0) = VECTOR3(0,0,-30)
CUBE_POSITIONS(1) = VECTOR3(30,0,0)
CUBE_POSITIONS(2) = VECTOR3(0,0,30)
CUBE_POSITIONS(3) = VECTOR3(-30,0,0)

DIM CUBE_DIMENSIONS(CUBE_COUNT) AS VECTOR3
CUBE_DIMENSIONS(0) = VECTOR3(10,20,10)
CUBE_DIMENSIONS(1) = VECTOR3(10,40,10)
CUBE_DIMENSIONS(2) = VECTOR3(10,60,10)
CUBE_DIMENSIONS(3) = VECTOR3(10,80,10)

DIM CUBE_COLORS(CUBE_COUNT) AS COLOR
CUBE_COLORS(0) = YELLOW
CUBE_COLORS(1) = DARKBLUE
CUBE_COLORS(2) = RAYRED
CUBE_COLORS(3) = VIOLET

IF CUBE_COUNT > 3 THEN
	FOR I = 4 TO CUBE_COUNT - 1
		RANDOMIZE 10538,5
		CUBE_POSITIONS(I) = VECTOR3(1000 - RND(1)*2000,0, 1000 -RND(1)*2000)
		
		CUBE_DIMENSIONS(I) = VECTOR3(RND(1) * 100,RND(1) * 50,RND(1) * 100)
		
		IF BOXSPHERECOLLISION(PLAYER_POS,PLAYER_RADIUS,CUBE_POSITIONS(I),CUBE_DIMENSIONS(I)) THEN I -= 1
		
		CUBE_COLORS(I) = COLOR(RND(1) * 255,RND(1) * 255,RND(1) * 255,255)
	NEXT I
END IF

FOR I = 4 TO CHERRY_COUNT 
	RANDOMIZE 10538,5
	
	TEMPX = 1000 - RND(1)*2000
	TEMPZ = 1000 -RND(1)*2000
	
	CORRECTION_OFFSET = 0
	
	FOR J = 0 TO CUBE_COUNT - 1
		DO WHILE BOXCOLLISION(VECTOR3(TEMPX,CORRECTION_OFFSET,TEMPZ),CUBE_POSITIONS(J),CUBE_DIMENSIONS(J))
			CORRECTION_OFFSET += 1
		LOOP
	NEXT J
	
	CHERRY_POSITIONS(I) = VECTOR3(TEMPX,CORRECTION_OFFSET + 1,TEMPZ)
	CHERRY_EXISTS(I) = TRUE
NEXT I


FOR I = 0 TO SPIKE_COUNT 
	RANDOMIZE 10538,5
	
	TEMPX = 1000 - RND(1)*2000
	TEMPZ = 1000 -RND(1)*2000
	
	CORRECTION_OFFSET = 0
	
	FOR J = 0 TO CUBE_COUNT - 1
		DO WHILE BOXCOLLISION(VECTOR3(TEMPX,CORRECTION_OFFSET,TEMPZ),CUBE_POSITIONS(J),CUBE_DIMENSIONS(J))
			CORRECTION_OFFSET += 1
		LOOP
	NEXT J

	SPIKE_POSITIONS(I) = VECTOR3(TEMPX,CORRECTION_OFFSET - 1,TEMPZ)
NEXT I

FOR I = 0 TO FOE_COUNT 
	RANDOMIZE 10538,5
	
	TEMPX = 1000 - RND(1)*2000
	TEMPZ = 1000 -RND(1)*2000
	
	CORRECTION_OFFSET = 0
	
	FOR J = 0 TO CUBE_COUNT - 1
		DO WHILE BOXCOLLISION(VECTOR3(TEMPX,CORRECTION_OFFSET,TEMPZ),CUBE_POSITIONS(J),CUBE_DIMENSIONS(J))
			CORRECTION_OFFSET += 1
		LOOP
	NEXT J
	
	IF CORRECTION_OFFSET = 0 THEN CORRECTION_OFFSET = 1
	
	FOE_POSITIONS(I) = VECTOR3(TEMPX,CORRECTION_OFFSET + 1,TEMPZ)
NEXT I

DIM AS SOUND JUMPSFX = LOADSOUND("JUMPSFX.WAV")
DIM AS SOUND BONKSFX = LOADSOUND("BONKSFX.WAV")
DIM AS SOUND BUMPSFX = LOADSOUND("BUMPSFX.WAV")
DIM AS SOUND ONEUPSFX = LOADSOUND("ONEUPSFX.WAV")
DIM AS SOUND CHERRYSFX = LOADSOUND("CHERRYSFX.WAV")
'DIM AS SOUND BGM = LoadSound("BGM.WAV")

'PLAYSOUNDMULTI(BGM)

MAIN:
	
	
	GETJOYSTICK(JOYSTICKID,STRIG,X_AXIS,Y_AXIS,SHOULDER,CSTICK_Y,CSTICK_X,,DPAD_X,DPAD_Y)
	
	IF DEBOUNCE = 0 AND BIT(STRIG,7) THEN
		DEBOUNCE = 20
		IF ISPAUSED THEN ISPAUSED = FALSE ELSE ISPAUSED = TRUE
		
		IF ISPAUSED THEN 
			BEGINDRAWING()
				DRAWTEXT("PAUSED",SCREEN_HEIGHT * (2.25/5),SCREEN_WIDTH * (1/3),80,BLACK)
			ENDDRAWING()
		
		END IF
	END IF
	
	IF DEBOUNCE > 0 THEN DEBOUNCE -= 1
	
	IF ISPAUSED THEN
		SLEEP 10
		GOTO REST
	END IF
	
	GAMETIME += GETTIME() - OLDTIME
	
	
	BEGINDRAWING()
		CLEARBACKGROUND(SKYBLUE)
		BEGINMODE3D(CAMERA)
			IF IFRAMES > 0 THEN 
				DRAWSPHERE(VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + 0.75, PLAYER_POS.Z), PLAYER_RADIUS, WHITE)
			ELSE
				DRAWSPHERE(VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + 0.75, PLAYER_POS.Z), PLAYER_RADIUS, RAYBLUE)
			END IF
	
			FOR I = 0 TO UBOUND(CUBE_POSITIONS)
				DRAWCUBEV(CUBE_POSITIONS(I),CUBE_DIMENSIONS(I),CUBE_COLORS(I))
				DRAWCUBEWIRESV(CUBE_POSITIONS(I),CUBE_DIMENSIONS(I),BLACK)
			NEXT I
			
			FOR I = 0 TO UBOUND(CHERRY_POSITIONS)
				IF CHERRY_EXISTS(I) THEN DRAWBILLBOARD(CAMERA, CHERRY, CHERRY_POSITIONS(I), 3, WHITE)
			NEXT I
			
			FOR I = 0 TO UBOUND(SPIKE_POSITIONS)
				DRAWCYLINDER(SPIKE_POSITIONS(I), 0, 1, 4, 10, LIGHTGRAY)
			NEXT I
			
			FOR I = 0 TO UBOUND(FOE_POSITIONS)
				DRAWBILLBOARD(CAMERA, FOE, FOE_POSITIONS(I), 4, WHITE)
			NEXT I
			
			DRAWMODEL(FLOOR, VECTOR3(0,0,0), 1000, WHITE)
		ENDMODE3D()
		DRAWRECTANGLE(0,0,SCREEN_WIDTH,40,BLACK)
		
		IF GAMETIME MOD 60 < 10 THEN 
			DRAWTEXT("TIME: " + STR(INT(GAMETIME / 60)) + ":0" + STR(GAMETIME MOD 60), SCREEN_WIDTH * (2/5),0,40, WHITE)
		ELSE	
			DRAWTEXT("TIME: " + STR(INT(GAMETIME / 60)) + ":" + STR(GAMETIME MOD 60), SCREEN_WIDTH * (2/5),0,40, WHITE)
		END IF
		
		DRAWTEXT("CHERRIES: " + STR(CHERRIES), 10,0,40, WHITE)
		DRAWTEXT("LIVES: " + STR(LIVES), SCREEN_WIDTH - 5 * 40,0,40, WHITE)
	ENDDRAWING()
	
	'IF NOT ISSOUNDPLAYING(BGM) THEN PLAYSOUNDMULTI(BGM)
	
	'GETJOYSTICK(0,STRIG,X_AXIS,Y_AXIS)
	
	IF (ISKEYDOWN(KEY_SPACE) OR (STRIG AND 15) > 0) AND (PLAYER_POS.Y = JUMP_FLOOR AND ISJUMPREADY) THEN 		
		ISJUMPING = TRUE
		HANGTIME = 10
		ISJUMPREADY = FALSE
		PLAYSOUNDMULTI(JUMPSFX)
	ENDIF 
	
	IF ISJUMPING THEN
		IF PLAYER_POS.Y < JUMP_FLOOR + 15 THEN 
			PLAYER_POS.Y += 1 
		ELSE
			IF HANGTIME = 0 THEN
				ISFALLING = TRUE
				ISJUMPING = FALSE
			ELSE
				HANGTIME -= 1
			END IF
		END IF
	ELSE 
		IF PLAYER_POS.Y > 0 THEN 
			COLLIDETEST = FALSE
			FOR I = 0 TO UBOUND(CUBE_DIMENSIONS)
				IF BOXSPHERECOLLISION(VECTOR3(PLAYER_POS.X, PLAYER_POS.Y - FALLING_SPEED, PLAYER_POS.Z),PLAYER_RADIUS,CUBE_POSITIONS(I),CUBE_DIMENSIONS(I)) THEN
					COLLIDETEST = TRUE
					JUMP_FLOOR = PLAYER_POS.Y
					IF ISFALLING AND ((NOT (ISKEYDOWN(KEY_UP) OR DPAD_Y = -1)  AND NOT (ISKEYDOWN(KEY_DOWN) OR DPAD_Y = 1) ) OR Y_AXIS < .9) THEN 
						IF SPEED > 5 THEN SPEED = 5
					END IF
					ISFALLING = FALSE
				END IF
			NEXT I
			
			
			IF COLLIDETEST = FALSE THEN PLAYER_POS.Y -= FALLING_SPEED
		ELSE 
			IF ISFALLING AND ((NOT (ISKEYDOWN(KEY_UP) OR DPAD_Y = -1)  AND NOT (ISKEYDOWN(KEY_DOWN) OR DPAD_Y = 1) ) OR Y_AXIS > -.9) THEN 
				IF SPEED > 5 THEN SPEED = 5
			END IF
			JUMP_FLOOR = 0
			ISFALLING = FALSE
		END IF
	END IF
	
	IF NOT ISJUMPING AND NOT ISFALLING THEN 
		IF NOT ISKEYDOWN(KEY_SPACE) AND (STRIG = 0 OR STRIG = -1) THEN ISJUMPREADY = TRUE
	END IF
	
	'PRINT STRIG 
	'IF ISFALLING AND PLAYER_POS.Y < JUMP_FLOOR THEN 
	IF PLAYER_POS.Y < JUMP_FLOOR THEN 
		IF CAMERA_Y_OFF < 25 THEN CAMERA_Y_OFF += .25
	ELSE 
		IF CAMERA_Y_OFF > 7 THEN IF CAMERA_Y_OFF < 8 THEN CAMERA_Y_OFF = 7 ELSE CAMERA_Y_OFF -= .5
	END IF
		
	IF X_AXIS <> -1000 AND CSTICK_X <> -1000 THEN
		IF ABS(X_AXIS) > ABS(CSTICK_X) THEN 
			ROTATION = X_AXIS/9
		ELSE
			ROTATION = CSTICK_X/9
		ENDIF
	ELSEIF X_AXIS <> -1000 THEN 
		ROTATION = X_AXIS/9
	END IF
	
	IF X_AXIS = -1000 OR (ABS(X_AXIS) < .1 AND ABS(CSTICK_X) < .1) THEN
		IF SHOULDER = -1000 OR ABS(SHOULDER) < .9 THEN
			IF (ISKEYDOWN(KEY_LEFT) OR DPAD_X = -1) THEN 
				ROTATION =  -.075 
			ELSEIF (ISKEYDOWN(KEY_RIGHT) OR DPAD_X = 1) THEN 
				ROTATION =  .075 
			ELSE 
				ROTATION = 0
			END IF
		ELSE
			IF SHOULDER > .9 THEN 
				ROTATION =  -.075 
			ELSEIF SHOULDER < -.9 THEN 
				ROTATION =  .075 
			ELSE 
				ROTATION = 0
			END IF
		END IF
	END IF 
	
	
	
	SIN_CAM = SIN(ROTATION)
	COS_CAM = COS(ROTATION)

	TEMPX = CAMERA.POSITION.X - PLAYER_POS.X
	TEMPZ = CAMERA.POSITION.Z - PLAYER_POS.Z

	CAMERA.POSITION.X = (COS_CAM * TEMPX - SIN_CAM * TEMPZ) + PLAYER_POS.X
	CAMERA.POSITION.Y = PLAYER_POS.Y + CAMERA_Y_OFF + (CSTICK_Y * 10)
	CAMERA.POSITION.Z = (SIN_CAM * TEMPX + COS_CAM * TEMPZ) + PLAYER_POS.Z

	CAMERA.TARGET = VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + CAMERA_HEIGHT, PLAYER_POS.Z)
	
	TEMPX = PLAYER_POS.X - CAMERA.POSITION.X
	TEMPZ = PLAYER_POS.Z - CAMERA.POSITION.Z
	
	'PRINT DPAD_X
	
	IF (ISKEYDOWN(KEY_UP) OR DPAD_Y = -1)  THEN
		IF DIRECTION = BACKWARDS THEN IF SPEED > 0 THEN SPEED -= 1 ELSE DIRECTION = FORWARDS
		
		IF DIRECTION = FORWARDS THEN
			IF SPEED = 0 THEN 
				SPEED = 5 
			ELSEIF SPEED < MAX_SPEED THEN 
				SPEED += 1
			END IF
		END IF
	ELSEIF (ISKEYDOWN(KEY_DOWN) OR DPAD_Y = 1)  THEN
		IF DIRECTION = FORWARDS THEN IF SPEED > 0 THEN SPEED -= 1 ELSE DIRECTION = BACKWARDS
		
		IF DIRECTION = BACKWARDS THEN
			IF SPEED = 0 THEN 
				SPEED = 5 
			ELSEIF SPEED < MAX_SPEED/2 THEN
				SPEED += 1
			END IF
		END IF
	END IF
	
	IF Y_AXIS <> -1000 THEN 
		IF Y_AXIS < -.1 THEN
			IF DIRECTION = BACKWARDS THEN IF SPEED > 0 THEN SPEED -= 1 ELSE DIRECTION = FORWARDS
			
			IF DIRECTION = FORWARDS THEN
				IF SPEED = 0 THEN 
					SPEED = 5 
				ELSEIF SPEED < ABS(Y_AXIS) * MAX_SPEED THEN 
					SPEED += 1
				'ELSE 	
				'	SPEED = ABS(Y_AXIS) * MAX_SPEED
				END IF
			END IF
		ELSEIF Y_AXIS > .1 THEN
			IF DIRECTION = FORWARDS THEN IF SPEED > 0 THEN SPEED -= 1 ELSE DIRECTION = BACKWARDS
			
			IF DIRECTION = BACKWARDS THEN
				IF SPEED = 0 THEN 
					SPEED = 5 
				ELSEIF SPEED < Y_AXIS * MAX_SPEED/2 THEN 
					SPEED += 1
				'ELSE 
				'	SPEED = Y_AXIS * MAX_SPEED
				END IF
			END IF
		END IF
	END IF
	
	IF (NOT (ISKEYDOWN(KEY_UP) OR DPAD_Y = -1)  AND NOT (ISKEYDOWN(KEY_DOWN) OR DPAD_Y = 1) ) AND (ABS(Y_AXIS) < .1 OR Y_AXIS = -1000) THEN
		IF SPEED > 0 AND NOT (ISJUMPING OR ISFALLING) THEN SPEED -= 1
	END IF
	
	
	
	COLLIDETEST = FALSE
	ISHURT = FALSE
	
	IF SPEED > 0 THEN
		IF DIRECTION = FORWARDS THEN
			FOR I = 0 TO SPEED
				
				FOR J = 0 TO UBOUND(CUBE_POSITIONS)
					IF BOXSPHERECOLLISION(VECTOR3(PLAYER_POS.X + TEMPX/200,PLAYER_POS.Y,PLAYER_POS.Z + TEMPZ/200), PLAYER_RADIUS, CUBE_POSITIONS(J), CUBE_DIMENSIONS(J)) = TRUE THEN COLLIDETEST = TRUE
				NEXT J
				
				FOR J = 0 TO UBOUND(SPIKE_POSITIONS)
					IF BOXSPHERECOLLISION(VECTOR3(PLAYER_POS.X + TEMPX/200,PLAYER_POS.Y,PLAYER_POS.Z + TEMPZ/200), PLAYER_RADIUS, SPIKE_POSITIONS(J), VECTOR3(1,4,1)) = TRUE THEN 
						COLLIDETEST = TRUE
						ISHURT = TRUE
					END IF
				NEXT J

				IF NOT COLLIDETEST THEN 
					PLAYER_POS.X += TEMPX/200
					PLAYER_POS.Z += TEMPZ/200
					CAMERA.POSITION.X += TEMPX/200
					CAMERA.POSITION.Z += TEMPZ/200
				ELSE
					IF NOT ISHURT THEN PLAYSOUNDMULTI(BUMPSFX)
					SPEED = 5
					DIRECTION = BACKWARDS
					EXIT FOR
				END IF
			NEXT I
		ELSE
			FOR I = 0 TO SPEED
				
				FOR J = 0 TO UBOUND(CUBE_POSITIONS)
					IF BOXSPHERECOLLISION(VECTOR3(PLAYER_POS.X - TEMPX/200,PLAYER_POS.Y,PLAYER_POS.Z - TEMPZ/200), PLAYER_RADIUS, CUBE_POSITIONS(J), CUBE_DIMENSIONS(J)) = TRUE THEN COLLIDETEST = TRUE
				NEXT J
				
				FOR J = 0 TO UBOUND(SPIKE_POSITIONS)
					IF BOXSPHERECOLLISION(VECTOR3(PLAYER_POS.X - TEMPX/200,PLAYER_POS.Y,PLAYER_POS.Z - TEMPZ/200), PLAYER_RADIUS, SPIKE_POSITIONS(J), VECTOR3(1,4,1)) = TRUE THEN 
						COLLIDETEST = TRUE
						ISHURT = TRUE
					END IF
				NEXT J

				IF NOT COLLIDETEST THEN 
					PLAYER_POS.X -= TEMPX/200
					PLAYER_POS.Z -= TEMPZ/200
					CAMERA.POSITION.X -= TEMPX/200
					CAMERA.POSITION.Z -= TEMPZ/200
				ELSE
					IF NOT ISHURT THEN PLAYSOUNDMULTI(BUMPSFX)
					SPEED = 5
					DIRECTION = FORWARDS
					EXIT FOR
				END IF
			NEXT I
		END IF 	
	END IF
	
	IF SPEED = 0 THEN
			FOR J = 0 TO UBOUND(CUBE_POSITIONS)
				IF BOXSPHERECOLLISION(VECTOR3(PLAYER_POS.X + TEMPX/200,PLAYER_POS.Y,PLAYER_POS.Z + TEMPZ/200), PLAYER_RADIUS, CUBE_POSITIONS(J), CUBE_DIMENSIONS(J)) = TRUE THEN COLLIDETEST = TRUE
			NEXT J
			
			FOR J = 0 TO UBOUND(SPIKE_POSITIONS)
				IF BOXSPHERECOLLISION(VECTOR3(PLAYER_POS.X + TEMPX/200,PLAYER_POS.Y,PLAYER_POS.Z + TEMPZ/200), PLAYER_RADIUS, SPIKE_POSITIONS(J), VECTOR3(1,4,1)) = TRUE THEN 
					COLLIDETEST = TRUE
					ISHURT = TRUE
				END IF
			NEXT J
	END IF 
	
	FOR I = 0 TO CHERRY_COUNT
		IF CHERRY_EXISTS(I) AND BOXSPHERECOLLISION(PLAYER_POS,PLAYER_RADIUS,CHERRY_POSITIONS(I),VECTOR3(10,10,10)) THEN 
			CHERRIES += 1
			CHERRY_EXISTS(I) = FALSE
			PLAYSOUNDMULTI(CHERRYSFX)
		END IF
	NEXT I
	
	FOR I = 0 TO FOE_COUNT
		'IF BOXSPHERECOLLISION(PLAYER_POS,PLAYER_RADIUS,FOE_POSITIONS(I),VECTOR3(3,5,3)) THEN ISHURT = TRUE:DIRECTION = DIRECTION XOR TRUE
		
		
		IF SQR((FOE_POSITIONS(I).X - PLAYER_POS.X) * (FOE_POSITIONS(I).X - PLAYER_POS.X) + (FOE_POSITIONS(I).Z - PLAYER_POS.Z) * (FOE_POSITIONS(I).Z - PLAYER_POS.Z)) < 50 THEN
			IF BOXSPHERECOLLISION(PLAYER_POS,PLAYER_RADIUS,FOE_POSITIONS(I),VECTOR3(3,5,3)) THEN 
				ISHURT = TRUE
				DIRECTION = DIRECTION XOR TRUE
			END IF
			
			TEMPX = FOE_POSITIONS(I).X + 0.1 * RND(1) + (PLAYER_POS.X - FOE_POSITIONS(I).X) / 30
			TEMPZ = FOE_POSITIONS(I).Z + 0.1 * RND(1) + (PLAYER_POS.Z - FOE_POSITIONS(I).Z) / 30
			
			COLLIDETEST = FALSE
			
			FOR J = 0 TO UBOUND(CUBE_POSITIONS)
				IF BOXSPHERECOLLISION(FOE_POSITIONS(I),1,CUBE_POSITIONS(J),CUBE_DIMENSIONS(J)) THEN
					COLLIDETEST = TRUE
				END IF
			NEXT J
			
			IF FOE_POSITIONS(I).Y > 2 THEN
				ISONGROUND = FALSE
				FOR J = 0 TO UBOUND(CUBE_POSITIONS)
					IF BOXCOLLISION(VECTOR3(TEMPX, FOE_POSITIONS(I).Y - 5, TEMPZ),CUBE_POSITIONS(J),CUBE_DIMENSIONS(J)) THEN
						ISONGROUND = TRUE
					END IF
				NEXT J
				
				IF ISONGROUND THEN
					IF NOT COLLIDETEST THEN 
						FOE_POSITIONS(I) = VECTOR3(TEMPX, FOE_POSITIONS(I).Y,TEMPZ)
					ELSE
						FOE_POSITIONS(I).X -=  (PLAYER_POS.X - FOE_POSITIONS(I).X) / 30
						FOE_POSITIONS(I).Z -=  (PLAYER_POS.Z - FOE_POSITIONS(I).Z) / 30
					END IF
				END IF 
			ELSE 
				IF NOT COLLIDETEST THEN 
					FOE_POSITIONS(I) = VECTOR3(TEMPX, FOE_POSITIONS(I).Y,TEMPZ)
				ELSE
					FOE_POSITIONS(I).X -=  (PLAYER_POS.X - FOE_POSITIONS(I).X) / 30
					FOE_POSITIONS(I).Z -=  (PLAYER_POS.Z - FOE_POSITIONS(I).Z) / 30
				END IF
			END IF 
			
			
		END IF
		
	NEXT I
	
	IF CHERRIES = ONEUP_THRESHOLD THEN LIVES += 1:ONEUP_THRESHOLD += 100:PLAYSOUNDMULTI(ONEUPSFX)
	
	IF IFRAMES > 0 THEN
		IFRAMES -= 1
	ELSE
		IF ISHURT THEN
			PLAYSOUNDMULTI(BONKSFX)
			IF CHERRIES > 0 AND CHERRIES < 10 THEN CHERRIES = 0 ELSE CHERRIES -= 10
			IFRAMES = 60
			IF CHERRIES < 0 THEN
				CHERRIES = 0
				LIVES -= 1
				IF LIVES < 0 THEN
					BEGINDRAWING()
						DRAWTEXT("GAME OVER",SCREEN_HEIGHT * (1/3),SCREEN_WIDTH * (1/3),80,BLACK)
					ENDDRAWING()
					
					SLEEP 10000
					
					GOTO UNLOAD
				END IF
				
				PLAYER_POS = VECTOR3(0,0,0)
				CAMERA.POSITION = VECTOR3(PLAYER_POS.X, PLAYER_POS.Y + CAMERA_Y_OFF, PLAYER_POS.Z + CAMERA_Z_OFF)
				FOR I = 0 TO UBOUND(CHERRY_EXISTS)
					CHERRY_EXISTS(I) = TRUE
				NEXT I
				
			END IF
		END IF
	END IF
	
REST:
	OLDTIME = GETTIME()
REST_WAIT:
	IF GETTIME() - OLDTIME < 1 / 60 THEN SLEEP 1:GOTO REST_WAIT

IF NOT WINDOWSHOULDCLOSE() THEN GOTO MAIN

UNLOAD:

UNLOADIMAGE(CHECKERS)
UNLOADTEXTURE(TEXTURE)
UNLOADTEXTURE(CHERRY)
UNLOADTEXTURE(FOE)
UNLOADMODEL(FLOOR)
UNLOADSOUND(JUMPSFX)
UNLOADSOUND(BONKSFX)
UNLOADSOUND(BUMPSFX)
UNLOADSOUND(ONEUPSFX)
UNLOADSOUND(CHERRYSFX)


CLOSEWINDOW()

FUNCTION BOXCOLLISION(SPOT AS VECTOR3, BOX AS VECTOR3, DIMENSIONS AS VECTOR3) AS BOOLEAN
	VAR FLAG = FALSE
	IF (BOX.X - (DIMENSIONS.X/2) < SPOT.X) AND (SPOT.X < BOX.X + (DIMENSIONS.X/2)) THEN
		IF (BOX.Y - (DIMENSIONS.Y/2) < SPOT.Y) AND (SPOT.Y < BOX.Y + (DIMENSIONS.Y/2)) THEN
			IF (BOX.Z - (DIMENSIONS.Z/2) < SPOT.Z) AND (SPOT.Z < BOX.Z + (DIMENSIONS.Z/2)) THEN
				FLAG = TRUE
			END IF 
		END IF 
	END IF 
	RETURN FLAG
END FUNCTION

FUNCTION BOXSPHERECOLLISION(SPOT AS VECTOR3, RADIUS AS INTEGER, BOX AS VECTOR3, DIMENSIONS AS VECTOR3) AS BOOLEAN
	VAR FLAG = FALSE
	
	IF (BOX.Y - (DIMENSIONS.Y/2) < SPOT.Y) AND (SPOT.Y < BOX.Y + (DIMENSIONS.Y/2)) THEN
	
		VAR DISTX = ABS(SPOT.X - BOX.X)
		VAR DISTZ = ABS(SPOT.Z - BOX.Z)
		
		IF DISTX > DIMENSIONS.X / 2 + RADIUS THEN RETURN FALSE
		IF DISTZ > DIMENSIONS.Z / 2 + RADIUS THEN RETURN FALSE
		
		IF DISTX <= DIMENSIONS.X/2 THEN RETURN TRUE
		IF DISTZ <= DIMENSIONS.Z/2 THEN RETURN TRUE
		
		VAR DX = DISTX - DIMENSIONS.X/2
		VAR DZ = DISTZ - DIMENSIONS.Z/2
		
		RETURN DX * DX + DZ * DZ <= RADIUS * RADIUS
	END IF 
	RETURN FLAG
END FUNCTION
