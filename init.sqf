
if(isClass(configfile >> "CfgPatches" >> "ace_interaction")) then {

	player addItem "ACE_Flashlight_XL50";

	if ((["PlayerMapTools", 1] call BIS_fnc_getParamValue) == 1) then {
		player addItem "ACE_MapTools";
	}
};

switch( ["PlayerBinoculars", 1] call BIS_fnc_getParamValue ) do {
	case 1: { player addWeapon "Binocular"; };
	case 2: { player addWeapon "Rangefinder" }; 
};

if((["PlayerCompass", 1] call BIS_fnc_getParamValue) == 1) then {
	player addItem "ItemCompass";
	player assignItem "ItemCompass";
};

MinDist = (["MinimumDistance", 250] call BIS_fnc_getParamValue);
MaxDist = (["MaximumDistance", 500] call BIS_fnc_getParamValue);

CourseNumber = ["Course", 0] call BIS_fnc_getParamValue;

//Ensure MaxDistance is at least MinimumDistance
if( MaxDist < MinDist ) then {
	MaxDist = MinDist;
};

//Add a little bit of "wiggle room"
MinDist = MinDist - (MinDist * 0.1);
MaxDist = MaxDist + (MaxDist * 0.1);


CheckpointMarker = switch( ["CheckpointMarker", 1] call BIS_fnc_getParamValue ) do {
	case 0: { "" };
	case 1: { "FlagMarker_01_F" };
	case 2: { "Flag_Blue_F" };
};

AdditionalMarker = switch( ["AdditionalMarker", 0] call BIS_fnc_getParamValue ) do {
	case 0: { "" };
	case 1: { "SmokeShellBlue_Infinite" };
	case 2: { "Chemlight_blue" };
	case 3: { "PortableHelipadLight_01_blue_F" };
};


NumberCheckpoints = switch( CourseNumber ) do {
	// If we're on a random course, use whatever number the player supplied
	case 0: { ["NumberCheckpoints", 10] call BIS_fnc_getParamValue };
	// Otherwise, count the number of map markers that define the selected course
	default {
		_c = -1; // Start at -1 to account for the starting location plus all checkpoints
		{
			_a = toArray _x;
			_a resize 8;
			_course = "";
			if (CourseNumber < 10) then {
				_course = format ["course0%1", CourseNumber]	
			}
			else {
				_course = format ["course%1", CourseNumber]	
			};
			if (toString _a == _course) then {
				_c = _c+1;
			};
		} forEach allMapMarkers;
		_c
	};
};

player createDiaryRecord ["Diary", ["Orienteering", "Welcome to Orienteering!<br/><br/>The goal is to reach all of the checkpoints in the fastest time.<br/>However, this isn't a sprint; you'll need to use key landmarks, terrain gradient, and compass bearings to find your way around the course.<br/>Take your time to survey your surroundings, plot the best route, and enjoy the scenery!"]];


startPos = getpos player;
checkpoints = [];
checkpointMarkers = [];
times = [];
travelMarkers = [];
travelCount = 0;
playersLastPos = getpos player;;

FNC_newCourse = {


	//TODO: PROMPT FOR RANDOM SEED

	
	// Setup initial player position
	startPos = switch( CourseNumber ) do {
		case 0: { [] call BIS_fnc_randomPos };
		default {
			if (CourseNumber < 10) then {
				getMarkerPos format ["course0%1", CourseNumber]	
			}
			else {
				getMarkerPos format ["course%1", CourseNumber]
			};
		}
	};

	times = [];

	//Clear any previous tasks and markers
	for "_i" from 0 to NumberCheckpoints-1 do {
		[format ["task%1", _i]] call BIS_fnc_deleteTask;
	};

	{
		deleteMarker _x;
	} forEach checkpointMarkers;

	// Track the player's position for later display
	playersLastPos = startPos;
	travelCount = 0;
	{
		deleteMarker _x;
	} forEach travelMarkers;


	// Setup the start marker
	if( (["ShowStart", 1] call BIS_fnc_getParamValue) == 1) then {
		deleteMarker "Start";
		_marker = createMarker ["Start", startPos]; 
	    _marker setMarkerText "Start"; 
	    _marker setMarkerType "hd_flag"; // Visible.
	};

	// Generate positions
	checkpoints = [];
	if ( CourseNumber == 0 ) then {
		prevPos = startPos;
		
		for "_i" from 0 to NumberCheckpoints-1 do {

			// If Traverse Mode is linear, only blacklist an area around the last point;
			// Otherwise blacklist and area around all points
			blacklist = switch (["TraverseMode", 1] call BIS_fnc_getParamValue) do { 
				case 0 : {  ["water", [prevPos, MinDist]] };
				// TODO: Don't recreate this every time inside the loop, store it elsewhere and expand it as needed
				case 1 : {  
					_a = ["water", [startPos, MinDist]];
					{
						_a pushBack [_x, MinDist];
					} forEach checkpoints;
					_a
				}; 
			};


			_pos = [[[prevPos, MaxDist]], blacklist] call BIS_fnc_randomPos;

			if (_pos isEqualTo [0, 0]) then {
				throw ("Invalid checkpoint position generated");
			};

			checkpoints pushBack _pos;
			prevPos = _pos;
		};
	};


	// I was really hoping to avoid this and use some method to seed the 
	// random generator for BIS_fnc_randomPos instead, but there doesn't seem to be a way to do it (easily)
	// So instead, there are some predefined courses using invisible map markers, with the following naming scheme:
	// course01_1, course01_2, course01_3...
	// course02_1, course02_2, course02_3...
	// etc.
	//TODO: This currently works for up to 99 predefined courses
	checkpoints = switch( CourseNumber ) do {
		case 0: { checkpoints };
		default {
			_chk = [];
			{
				_a = toArray _x;
				_a resize 9;

				_course = "";
				if (CourseNumber < 10) then {
					_course = format ["course0%1_", CourseNumber]	
				}
				else {
					_course = format ["course%1_", CourseNumber]	
				};

				if (toString _a == _course) then {
					_chk pushBack (getMarkerPos _x);
				};
			} forEach allMapMarkers;
			_chk
		};
	};

	// Setup main checkpoint markers
	if(CheckpointMarker != "") then {
		{
		   CheckpointMarker createVehicleLocal _x;
		} forEach checkpoints;
	};


	// Activate first checkpoint (or all checkpoints if TraversalMode is Any Order)
	if( (["TraverseMode", 1] call BIS_fnc_getParamValue) == 0) then {
		[0, checkpoints select 0] call FNC_activateCheckpoint;
		"task0" call BIS_fnc_taskSetCurrent;
	}
	else{
		for "_i" from 0 to NumberCheckpoints-1 do {
			[_i, checkpoints select _i] call FNC_activateCheckpoint;
		}
	};

	//Begin course
	["#DDDDDD"] spawn BIS_fnc_VRTimer;
	player setpos startPos;
};






FNC_activateCheckpoint = {
	params ["_positionIndex", "_position"];

	// Create task
	_id = format ["task%1", _positionIndex];
	_title = format ["Checkpoint #%1", _positionIndex+1];
	_waypoint = createmarker [format ["marker%1", _positionIndex], _position];
	checkpointMarkers pushBack _waypoint;
	_task = [player, _id, ["", _title, _waypoint], _position] call BIS_fnc_taskCreate;

	// Create trigger
	_trg = createTrigger ["EmptyDetector", _position];
	_r = ["CheckpointRadius", 2] call BIS_fnc_getParamValue;
	_trg setTriggerArea [_r, _r, 0, false];
	_trg setTriggerActivation ["ANYPLAYER", "PRESENT", false];
	_trg setTriggerStatements ["this", format ["[%1] call FNC_completeCheckpoint;", _positionIndex], ""];


	// Activate additional marker
	if(AdditionalMarker != "") then{ AdditionalMarker createVehicleLocal _position; };
};


FNC_completeCheckpoint = {
	params ["_positionIndex"];

	// Complete task
	_id = format ["task%1", _positionIndex];
	[_id, "SUCCEEDED"] call BIS_fnc_taskSetState;


	// TODO: Clear Additional Markers (e.g. smoke/chemlights)?


	// Create map marker
	_marker = format ["marker%1", _positionIndex];
	_marker setMarkerText format ["#%1 (%2)", _positionIndex+1, str RscFiringDrillTime_current];
	_marker setMarkerType "hd_flag"; // Visible.


	// Record time
	times pushBack [_positionIndex, RscFiringDrillTime_current];

	// Plot path up until this point
	if ((["ShowPath", 1] call BIS_fnc_getParamValue) == 2) then {
		{
			_x setMarkerType "hd_dot";
		} forEach travelMarkers;
	};



	// Check for completeness if TraverseMode is Linear
	if(["TraverseMode", 1] call BIS_fnc_getParamValue == 0) then {
		// If the next positionIndex surpasses the number of checkpoints, then end the course
		if(_positionIndex + 1 >= NumberCheckpoints) then {
			call FNC_endCourse;
		}
		//Otherwise, activate the next checkpoint
		else{
			if(["TraverseMode", 1] call BIS_fnc_getParamValue == 0) then {
				[_positionIndex+1, checkpoints select _positionIndex+1] call FNC_activateCheckpoint;
			};
		};
	}
	// Check for completeness if TraverseMode is Any Order
	else {
		// If there are no remaining tasks, end the course
		completed = true;
		{
			if((_x call BIS_fnc_taskState) != "SUCCEEDED") then{
				completed = false;
				break;
			};
		} forEach (player call BIS_fnc_tasksUnit);

		if( completed ) then {
			call FNC_endCourse;
		};
	};
};

FNC_endCourse = {

	BIS_stopTimer = true;

	//Print path
	{
		_x setMarkerType "hd_dot";
	} forEach travelMarkers;


	//Print score, print seed, etc.
	scoreText = "Good work - you completed the course!\n\n";
	for "_i" from 0 to NumberCheckpoints-1 do {

		scoreText = scoreText + (format ["Checkpoint #%1: %2", ((times select _i) select 0)+1, (times select _i) select 1]) + "\n";
	};
	hint (scoreText + "\nCheck the map to review your path\nEnding mission in 15 seconds...");


	[] spawn {
		sleep 15;
		endText = "Good work - you completed the course!<br/><br/>";
		for "_i" from 0 to NumberCheckpoints-1 do {

			endText = endText + (format ["Checkpoint #%1: %2", ((times select _i) select 0)+1, (times select _i) select 1]) + "<br/>";
		};

		endText = endText + "<br/>" + (format ["Final time: %1", RscFiringDrillTime_current]) + "<br/>";

		"end1" setDebriefingText ["Course Complete", endText];
		"end1" call BIS_fnc_endMission;
		// TODO: Restart instead? Currently experiencing an issue with recreating the tasks (perhaps due to reusing the IDs?)
		//call FNC_newCourse;
	}	
};


// I don't know why, but spawn BIS_fnc_VRTimer won't work without this initial sleep. So...
[] spawn {
	sleep 0.1;
	call FNC_newCourse;
};


// Track the player's path for later display
[] spawn {
	while{true} do{
		if(player distance playersLastPos > 4) then{			
			_marker = createMarker [format ["travelMarker_%1", travelCount], player];
			travelMarkers append [_marker];
			travelCount = travelCount + 1;
			playersLastPos = getpos player;

		};
		sleep 2;
	};
};