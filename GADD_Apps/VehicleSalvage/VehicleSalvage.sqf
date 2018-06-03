/**
	Script Name: Salvage Vehicle Script
	Author: [GADD]Monkeynutz
	Description: Salvage Vehicle Script for Exile. Allows for Salvaging Vehicles that are destroyed and turns it into Junk Metal at the player's feet.
**/

private ["_SalvageVehicle_DISALLOW_DURING_COMBAT","_SalvageVehicle_TIME_TAKEN_TO_SALVAGE","_keyDown","mouseDown","_startTime","_duration","_sleepTime",
			"_progress","_uiControl","_percentage","_progressBarBackground","_progressBarMaxSize","_progressBar","_barColour","_junk"];

_SalvageVehicle_DISALLOW_DURING_COMBAT 	= true;		//BOOLEAN - Set to true to prevent people salvaging their vehicles during combat.
_SalvageVehicle_TIME_TAKEN_TO_SALVAGE 	= 10; 		//SCALAR - Set in seconds how long you wish for salvaging to take players. (Default = 10)

// Do not edit below this line unless you know what you are doing!

if (ExileClientActionDelayShown) exitWith { false };
ExileClientActionDelayShown = true;
ExileClientActionDelayAbort = false;

if (ExileClientPlayerIsInCombat && _SalvageVehicle_DISALLOW_DURING_COMBAT) exitWith
{
	["ErrorTitleAndText",["Vehicle Salvage!", "You cannot salvage a vehicle while in combat!"]] call ExileClient_gui_toaster_addTemplateToast;
	ExileClientActionDelayShown = false;
	ExileClientActionDelayAbort = false;	
};

["InfoTitleAndText",["Vehicle Salvage!", "Salvaging Vehicle!"]] call ExileClient_gui_toaster_addTemplateToast;

disableSerialization;
("ExileActionProgressLayer" call BIS_fnc_rscLayer) cutRsc ["RscExileActionProgress", "PLAIN", 1, false];

_keyDown = (findDisplay 46) displayAddEventHandler ["KeyDown","_this call ExileClient_action_event_onKeyDown"];
_mouseDown = (findDisplay 46) displayAddEventHandler ["MouseButtonDown","_this call ExileClient_action_event_onMouseButtonDown"];
_startTime = diag_tickTime;
_duration = _SalvageVehicle_TIME_TAKEN_TO_SALVAGE;
_sleepTime = _duration / 100;
_progress = 0;
_uiControl = uiNamespace getVariable "RscExileActionProgress";   
_percentage = _uiControl displayCtrl 4002;
_progressBarBackground = _uiControl displayCtrl 4001;  
_progressBarMaxSize = ctrlPosition _progressBarBackground;
_progressBar = _uiControl displayCtrl 4000;  
_barColour = [];
			
player playAction "Exile_Acts_RepairVehicle01_Animation01";
["switchMoveRequest", [netId player, "Exile_Acts_RepairVehicle01_Animation01"]] call ExileClient_system_network_send;
_percentage ctrlSetText "0%";
_progressBar ctrlSetPosition [_progressBarMaxSize select 0, _progressBarMaxSize select 1, 0, _progressBarMaxSize select 3];
_progressBar ctrlSetBackgroundColor [0, 0.78, 0.93, 1];
_progressBar ctrlCommit 0;
_progressBar ctrlSetPosition _progressBarMaxSize; 
_progressBar ctrlCommit _duration;
try
{
	while {_progress < 1} do
	{	
		if (ExileClientActionDelayAbort) then 
		{
			throw 1;
		};

		uiSleep _sleepTime; 
		_progress = ((diag_tickTime - _startTime) / _duration) min 1;
		_percentage ctrlSetText format["%1%2", round (_progress * 100), "%"];
	};
	throw 0;
}
catch
{
	
	switch (_exception) do 
	{
		case 0:
		{
			_barColour = [0.7, 0.93, 0, 1];
			deleteVehicle (_this select 0);

			[
				"SuccessTitleAndText", 
				["Vehicle Salvage!", "You have successfully Salvaged this Vehicle! Junk Metal fell on the floor!"]
			] call ExileClient_gui_toaster_addTemplateToast; 
			_junk = "groundweaponHolder" createVehicle position player;
			_junk addMagazineCargo ["Exile_Item_JunkMetal", 1];
			_junk setPosATL getPosATL player;
		};
		case 1: 	
		{ 
			[
				"ErrorTitleAndText", 
				["Vehicle Salvage!", "Salvaging Canceled!"]
			] call ExileClient_gui_toaster_addTemplateToast;
			_barColour = [0.82, 0.82, 0.82, 1];
		};
	};	
	player switchMove "";
	["switchMoveRequest", [netId player, ""]] call ExileClient_system_network_send;
	_progressBar ctrlSetBackgroundColor _barColour;
	_progressBar ctrlSetPosition _progressBarMaxSize;
	_progressBar ctrlCommit 0;
};

("ExileActionProgressLayer" call BIS_fnc_rscLayer) cutFadeOut 2; 
(findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyDown];
(findDisplay 46) displayRemoveEventHandler ["MouseButtonDown", _mouseDown];
ExileClientActionDelayShown = false;
ExileClientActionDelayAbort = false;
