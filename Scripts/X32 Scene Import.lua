local debug = false;

local drumsColor = 16810048; --reaper.ColorToNative(64, 128, 0);
local bandColor = 25182208; --reaper.ColorToNative(0, 64, 128);
local keysColor = 16842751; -- 255,255,0
local vocalsColor = 16809984; --reaper.ColorToNative(0, 128, 0);
local effectsColor = reaper.ColorToNative(234, 0, 234);

local recievesCategory = -1;
local sendsCategory = 0;
local hardwareCategory = 1;

local project = 0;
local projectPath = reaper.GetProjectPath("");
local masterTrack = reaper.GetMasterTrack(project);
local sceneFileName;

local trackSettings = {};
local fxSettings = {};
local drumTracks = {};
local vocalTracks = {};
local bandTracks = {};
local dcagroups = {};

local drumsTrack;
local bandTrack;
local vocalsTrack;
local vocalsDelayTrack;
local vocalsReverbTrack;
local bandReverbTrack;

local paramType = {};
paramType.freq = 0;
paramType.gain = 1;
paramType.q = 2;

function log(data)
	if type(data) == "table" then
		for _, item in pairs(data) do
			log(item);
		end
	else
		reaper.ShowConsoleMsg(data.."\n");
	end
end
function debug(data)
	if debug == true then
		log(data)
	end
end
function RemoveEmptyTracks()
	-- determine which tracks have no media files and can be removed. 
	local tracksToRemove = {};
	for i=0, reaper.CountTracks(project)-1, 1 do
		local track = reaper.GetTrack(project, i);
		local mediaItems = reaper.CountTrackMediaItems(track);
		if mediaItems == 0 then
			-- label track for removal
			table.insert(tracksToRemove, track);
		end
		TrackRemoveSends(track, true);
	end

	-- delete the marked tracks
	for _, track in pairs(tracksToRemove) do
		reaper.DeleteTrack(track);
	end

	for i=0, reaper.CountTracks(project)-1, 1 do
		local track = reaper.GetTrack(project, i);
		CategorizeTrackByColor(track);
	end
end
function TrackRemoveSends(track, removeMaster)
	-- main
	if removeMaster then
		local ok = reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 0);
	end
	-- disarm record
	local ok = reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0);
	for i=0, reaper.GetTrackNumSends(track, recievesCategory)-1, 1 do
		ok = reaper.RemoveTrackSend(track, recievesCategory, 0);
	end
	for i=0, reaper.GetTrackNumSends(track, sendsCategory)-1, 1 do
		ok = reaper.RemoveTrackSend(track, sendsCategory, 0);
	end
	for i=0, reaper.GetTrackNumSends(track, hardwareCategory)-1, 1 do
		ok = reaper.RemoveTrackSend(track, hardwareCategory, 0);
	end
end
function CategorizeTrackByColor(track)
	if reaper.GetTrackColor(track) == drumsColor then
		table.insert(drumTracks, track);
	elseif reaper.GetTrackColor(track) == vocalsColor then
		table.insert(vocalTracks, track);
	elseif reaper.GetTrackColor(track) == bandColor or reaper.GetTrackColor(track) == keysColor then
		table.insert(bandTracks, track);
	end
end
function AddGroupTracks()
	-- add drums track
	reaper.InsertTrackAtIndex(reaper.GetNumTracks(), true);
	drumsTrack = reaper.GetTrack(project, reaper.GetNumTracks()-1);
	reaper.SetTrackColor(drumsTrack, drumsColor);
	local ok, name = reaper.GetSetMediaTrackInfo_String(drumsTrack, "P_NAME", "Drums", true);

	-- Add Band Track
	reaper.InsertTrackAtIndex(reaper.GetNumTracks(), true);
	bandTrack = reaper.GetTrack(project, reaper.GetNumTracks()-1);
	reaper.SetTrackColor(bandTrack, bandColor);
	local ok, name = reaper.GetSetMediaTrackInfo_String(bandTrack, "P_NAME", "Band", true);
	
	-- Add Vocals Track
	reaper.InsertTrackAtIndex(reaper.GetNumTracks(), true);
	vocalsTrack = reaper.GetTrack(project, reaper.GetNumTracks()-1);
	reaper.SetTrackColor(vocalsTrack, vocalsColor);
	local ok, name = reaper.GetSetMediaTrackInfo_String(vocalsTrack, "P_NAME", "Vocals", true);

	-- Add Delay Effects Track  for vocals
	reaper.InsertTrackAtIndex(reaper.GetNumTracks(), true);
	vocalsDelayTrack = reaper.GetTrack(project, reaper.GetNumTracks()-1);
	reaper.SetTrackColor(vocalsDelayTrack, effectsColor);
	local ok, name = reaper.GetSetMediaTrackInfo_String(vocalsDelayTrack, "P_NAME", "Vox Delay", true);

	-- Add Reverb Effects Track for vocals
	reaper.InsertTrackAtIndex(reaper.GetNumTracks(), true);
	vocalsReverbTrack = reaper.GetTrack(project, reaper.GetNumTracks()-1);
	reaper.SetTrackColor(vocalsReverbTrack, effectsColor);
	local ok, name = reaper.GetSetMediaTrackInfo_String(vocalsReverbTrack, "P_NAME", "Vox Reverb", true);

	-- Add Reverb Effects Track for Band
	reaper.InsertTrackAtIndex(reaper.GetNumTracks(), true);
	bandReverbTrack = reaper.GetTrack(project, reaper.GetNumTracks()-1);
	reaper.SetTrackColor(bandReverbTrack, effectsColor);
	local ok, name = reaper.GetSetMediaTrackInfo_String(bandReverbTrack, "P_NAME", "Band Reverb", true);
end
function AddGroupSends()
	-- create Drum sends
	for _, track in pairs(drumTracks) do
		if track then
			local ok = reaper.CreateTrackSend(track, drumsTrack);
		end
	end

	-- create Band sends
	for _, track in pairs(bandTracks) do
		if track then
			local ok = reaper.CreateTrackSend(track, bandTrack);
		end
	end

	-- create Vocal sends
	for _, track in pairs(vocalTracks) do
		if track then
			local ok = reaper.CreateTrackSend(track, vocalsTrack);
		end
	end

	-- create vocals delay sends
	local ok = reaper.CreateTrackSend(vocalsTrack, vocalsDelayTrack);

	-- create vocals reverb sends
	local ok = reaper.CreateTrackSend(vocalsTrack, vocalsReverbTrack);

	-- create band reverb sends
	local ok = reaper.CreateTrackSend(drumsTrack, bandReverbTrack);
	local ok = reaper.CreateTrackSend(bandTrack, bandReverbTrack);

	-- set Main hardware out
	local ok = reaper.CreateTrackSend(masterTrack, nil);
	reaper.SetTrackSendInfo_Value(masterTrack, hardwareCategory, 0, "I_DSTCHAN", 0);
end
function LoadScene(filePath, fileName)
	log("Load Scene: "..filePath.."\\"..fileName)
	local file = io.open(filePath.."\\"..fileName);
	local ch, trackNum = "";
	for i = 1,32,1 do
		trackSettings[i] = {};
	end
	for i = 1,8,1 do
		fxSettings[i] = {};
		dcagroups[i] = {};
	end

	if file then
	    for line in file:lines() do
	    	-- replace spaces in strings between quotes with underscore like "Hello There" -> "Hello_There", this is for split to work properly
	    	line = line:gsub("(\"%w+)(%s+)(%w+\")", "%1_%3");
	    	
	        --local name, address, email = table.unpack(line:split(" ")) --unpack turns a table like the one given (if you use the recommended version) into a bunch of separate variables
	        --do something with that data
	        if string.match(line, "/ch/") and string.match(line, "/config") then
	        	debug(line);
	        	local trackInfo, name = table.unpack(line:split(" "));
	        	ch, trackNum = table.unpack(trackInfo:split("/"));
	        	trackNum = tonumber(trackNum);
	        	trackSettings[trackNum].trackNum = trackNum;
	        	trackSettings[trackNum].name = name:gsub("\"", ""):gsub("_", " ");
	        	debug(trackNum.." "..name);
	        end
	        if string.match(line, "/ch/") and string.match(line, "/preamp") then
	        	debug(line);
	        	local trackInfo, preampVolume, flipPolarityOn, lowCutOn, b, lowCutFreq = table.unpack(line:split(" "));
	        	trackSettings[trackNum].preampVolume = volumeFix(preampVolume);
	        	trackSettings[trackNum].flipPolarityOn = flipPolarityOn;
	        	trackSettings[trackNum].lowCutOn = lowCutOn;
	        	trackSettings[trackNum].lowCutFreq = frequencyFix(lowCutFreq);
	        end

	        -- main sends
	        if string.match(line, "/ch/") and string.match(line, "/mix ") then
	        	debug(line);
	        	local trackInfo, muteOn, volume, mainOn, pan, centerOn, centerVolume = table.unpack(line:split(" "));
	        	trackSettings[trackNum].mute = muteOn;
	        	trackSettings[trackNum].volume = volumeFix(volume);
	        	trackSettings[trackNum].masterSend = mainOn;
	        	trackSettings[trackNum].pan = panFix(pan);
	        	trackSettings[trackNum].centerOn = centerOn;
	        	trackSettings[trackNum].centerVolume = volumeFix(centerVolume);
	        end

	        -- gate settings
	        if string.match(line, "/ch/") and string.match(line, "/gate ") then
	        	debug(line);
	        	local trackInfo, gateOn, gateType, threshold, range, attack, hold, release, keyCh = table.unpack(line:split(" "));
	        	trackSettings[trackNum].gate = {};
	        	trackSettings[trackNum].gate.on = gateOn;
	        	trackSettings[trackNum].gate.type = gateType;
	        	trackSettings[trackNum].gate.threshold = volumeFix(threshold);
	        	trackSettings[trackNum].gate.range = range;
	        	trackSettings[trackNum].gate.attack = attack;
	        	trackSettings[trackNum].gate.hold = hold;
	        	trackSettings[trackNum].gate.release = release;
	        	trackSettings[trackNum].gate.keyChannel = keyCh;
	        end
	        -- gate filter
	        if string.match(line, "/ch/") and string.match(line, "/gate/filter") then
	        	debug(line);
	        	local trackInfo, gateFilterOn, gateFilterType, frequency = table.unpack(line:split(" "));
	        	trackSettings[trackNum].gate.filterOn = gateFilterOn;
	        	trackSettings[trackNum].gate.filterType = gateFilterType;
	        	trackSettings[trackNum].gate.filterFrequency = frequencyFix(frequency);
	        end

	        -- Compressor
			if string.match(line, "/ch/") and string.match(line, "/dyn ") then
				debug(line);
				local trackInfo, on, compressionType, gainType, envelope, threshold, ratio, knee, gain, attack, hold, release, position, keyCh, mix, autoOn = table.unpack(line:split(" "));
				trackSettings[trackNum].compression = {};
				trackSettings[trackNum].compression.on = on;
				trackSettings[trackNum].compression.type = compressionType;
				trackSettings[trackNum].compression.gainType = gainType;
				trackSettings[trackNum].compression.envelope = envelope;
				trackSettings[trackNum].compression.threshold = volumeFix(threshold);
				trackSettings[trackNum].compression.ratio = ratio;
				trackSettings[trackNum].compression.knee = kneeFix(knee);
				trackSettings[trackNum].compression.gain = volumeFix(gain);
				trackSettings[trackNum].compression.attack = attack;
				trackSettings[trackNum].compression.hold = hold;
				trackSettings[trackNum].compression.release = release;
				trackSettings[trackNum].compression.position = position;
				trackSettings[trackNum].compression.keyChannel = keyCh;
				trackSettings[trackNum].compression.mix = volumeFix(mix);
				trackSettings[trackNum].compression.auto = autoOn;
			end
			-- Compressor filter
			if string.match(line, "/ch/") and string.match(line, "/dyn/filter") then
				debug(line);
				local trackInfo, on, type, frequency = table.unpack(line:split(" "));
				trackSettings[trackNum].compression.filterOn = on;
				trackSettings[trackNum].compression.filterType = type;
				trackSettings[trackNum].compression.filterFrequency = frequencyFix(frequency);
			end

			-- EQ
			if string.match(line, "/ch/") and string.match(line, "/eq ") then
				debug(line);
				local trackInfo, on = table.unpack(line:split(" "));
				trackSettings[trackNum].eq = {};
				trackSettings[trackNum].eq.on = on;
				trackSettings[trackNum].eq.channels = {};
			end
			-- EQ channel
			if string.match(line, "/ch/") and string.match(line, "/eq/") then
				debug(line);
				local trackInfo, type, frequency, gain, q = table.unpack(line:split(" "));
				local ch, tn, eq, cn = table.unpack(trackInfo:split("/"));
				cn = tonumber(cn);
				trackSettings[trackNum].eq.channels[cn] = {};
				trackSettings[trackNum].eq.channels[cn].type = type;
				trackSettings[trackNum].eq.channels[cn].frequency = frequencyFix(frequency);
				trackSettings[trackNum].eq.channels[cn].gain = volumeFix(gain);
				trackSettings[trackNum].eq.channels[cn].q = bandwidthFix(q, type);
				--log("Track: "..tn.." cn: "..cn.." type: "..trackSettings[trackNum].eq.channels[cn].type.." freq: "..trackSettings[trackNum].eq.channels[cn].frequency.." gain: "..trackSettings[trackNum].eq.channels[cn].gain.." q: "..trackSettings[trackNum].eq.channels[cn].q);
			end

			-- capture FX
			if string.match(line, "/fx/") and not string.match(line, "/source") and not not string.match(line, "/par")  then
				debug(line);
				local trackInfo, fxType = table.unpack(line:split(" "));
				local fx, channel = table.unpack(trackInfo:split("/"));
				channel = tonumber(channel);
				fxSettings[channel].channel = channel;
				fxSettings[channel].type = fxType;
			end
			-- FX Source
			if string.match(line, "/fx/") and string.match(line, "/source")  then
				debug(line);
				local trackInfo, srcLeft, srcRight = table.unpack(line:split(" "));
				local fx, channel = table.unpack(trackInfo:split("/"));
				channel = tonumber(channel);
				fxSettings[channel].srcLeft = srcLeft;
				fxSettings[channel].srcRight = srcRight;
			end
			-- FX Parameters
			if string.match(line, "/fx/") and string.match(line, "/par")  then
				debug(line);
				local trackInfo = table.unpack(line:split(" "));
				local fx, channel = table.unpack(trackInfo:split("/"));
				channel = tonumber(channel);
				fxSettings[channel].params = {};
				fxSettings[channel].params[fxSettings[channel].type] = {};

				if fxSettings[channel].type == "4TAP" then
					local trackInfo, timeBase, gain, feedPercent, lowCut, hiCut, spread, factorA, gainA, factorB, gainB, factorC, gainC, xfeed, mono, dry = table.unpack(line:split(" "));

					fxSettings[channel].params[fxSettings[channel].type].timeBase = timeBase;
					fxSettings[channel].params[fxSettings[channel].type].gain = volumeFix(gain);
					fxSettings[channel].params[fxSettings[channel].type].feedPercent = feedPercent;
					fxSettings[channel].params[fxSettings[channel].type].lowCut = frequencyFix(lowCut);
					fxSettings[channel].params[fxSettings[channel].type].hiCut = frequencyFix(hiCut);
					fxSettings[channel].params[fxSettings[channel].type].spread = spread;
					fxSettings[channel].params[fxSettings[channel].type].factorA = factorA;
					fxSettings[channel].params[fxSettings[channel].type].gainA = volumeFix(gainA);
					fxSettings[channel].params[fxSettings[channel].type].factorB = factorB;
					fxSettings[channel].params[fxSettings[channel].type].gainB = volumeFix(gainB);
					fxSettings[channel].params[fxSettings[channel].type].factorC = factorC;
					fxSettings[channel].params[fxSettings[channel].type].gainC = volumeFix(gainC);
					fxSettings[channel].params[fxSettings[channel].type].xfeed = xfeed;
					fxSettings[channel].params[fxSettings[channel].type].mono = mono;
					fxSettings[channel].params[fxSettings[channel].type].dry = dry;
				elseif fxSettings[channel].type == "PLAT" then
					local trackInfo, preDelay, decay, size, dampFrequency, diff, level, lowCut, hiCut, bassMultiplier, xoverFrequency, modulationDepth, modulationSpeed = table.unpack(line:split(" "));

					fxSettings[channel].params[fxSettings[channel].type].preDelay = preDelay;
					fxSettings[channel].params[fxSettings[channel].type].decay = decay;
					fxSettings[channel].params[fxSettings[channel].type].size = size;
					fxSettings[channel].params[fxSettings[channel].type].dampFrequency = frequencyFix(dampFrequency);
					fxSettings[channel].params[fxSettings[channel].type].diff = diff;
					fxSettings[channel].params[fxSettings[channel].type].level = volumeFix(level);
					fxSettings[channel].params[fxSettings[channel].type].lowCut = frequencyFix(lowCut);
					fxSettings[channel].params[fxSettings[channel].type].hiCut = frequencyFix(hiCut);
					fxSettings[channel].params[fxSettings[channel].type].bassMultiplier = bassMultiplier;
					fxSettings[channel].params[fxSettings[channel].type].xoverFrequency = frequencyFix(xoverFrequency);
					fxSettings[channel].params[fxSettings[channel].type].modulationDepth = modulationDepth;
					fxSettings[channel].params[fxSettings[channel].type].modulationSpeed = modulationSpeed;
				end
			end

			-- DCA Groups
			-- /dca/1 ON  -5.6
			-- /dca/1/config "Drums" 11 GN
			-- /dca/2 ON  -6.4
			-- /dca/2/config "Band" 44 BLi
			-- /dca/3 ON  +1.5
			-- /dca/3/config "Vox" 43 GNi
			-- /dca/4 ON  +0.2
			if string.match(line, "/dca/") and not string.match(line, "/config") then 
				local trackInfo, on, volume = table.unpack(line:split(" "));
				local dca, groupNum = table.unpack(trackInfo:split("/"));
				groupNum = tonumber(groupNum);

				dcagroups[groupNum].on = on;
				dcagroups[groupNum].volume = volumeFix(volume);
			end

	        -- capture preamps
	        if string.match(line, "/headamp/") then
	        	local trackInfo, headPreampVolume, V48 = table.unpack(line:split(" "));
	        	local headamp, ampNum = table.unpack(trackInfo:split("/"));
	        	ampNum = tonumber(ampNum);

	        	-- head preamps range 32-63, a total of 32 channels 
	        	if ampNum-31 >= 1 and ampNum-31 <= 32 then
	        		debug(line);
	        		trackSettings[ampNum-31].headPreampVolume = volumeFix(headPreampVolume);
	        	end
	        end
	    end
	    log("Scene Import Complete!");
	else
		log("No Valid File!");
	end
end
function dBFromVal(val) 
	return 20*math.log(val, 10);
end
function ValFromdB(dB_val) 
	return 10^(dB_val/20);
end
function frequencyFix(frequency)	;
	if string.match(frequency, "k") then
		frequency = string.gsub(frequency, "k", "").."0";
	end
	return frequency;
end
function volumeFix(volume)
	if volume == "-oo" then
		return 0;
	end
	return ValFromdB(tonumber(volume));
end
function kneeFix(knee)
	if knee == 0 then 
		return 0;
	elseif knee == 1 then
		return 5;
	elseif knee == 2 then
		return 10;
	elseif knee == 3 then
		return 15;
	elseif knee == 4 then
		return 20;
	elseif knee == 5 then
		return 24;
	end
	return 5;
end
function panFix(pan)
	pan = tonumber(pan);
	if pan < -100 then
		return -1;
	elseif pan > 100 then
		return 1;
	end
	return pan/100;
end
function bandwidthFix(q, eqType)
	if eqType == "LCut" or eqType == "HCut" then
		-- eq is weird curve for low cut and high cut when q value is used
		return 2;
	end
	return 1/q * 1.2;
end
function scandir(directory)
    local i, t, popen = 0, {}, io.popen;
    for filename in popen('dir "'..directory..'" /b'):lines() do
    	if filename and string.match(filename, ".scn") then
	        return filename;
		end
    end
end
function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end
function rangeToIdentity(value, min, max)
	-- converts min-max to 0-1 and adjusts value
	return (value-min) / (max-min);
end
function bandType(eqType)
	-- types: LCut, LShv, PEQ, VEQ, HShv, HCut
	-- Bandtype: -1=master gain, 0=lhipass, 1=loshelf, 2=band, 3=notch, 4=hishelf, 5=lopass.
	if eqType == "LCut" then
		return 0;
	elseif eqType == "LShv" then
		return 1;
	elseif eqType == "PEQ" then
		return 2;
	elseif eqType == "VEQ" then
		return 2;
	elseif eqType == "HShv" then
		return 4;
	elseif eqType == "HCut" then
		return 5;
	end
	return 2;
end
function updateBandTypeCount(bandTypeCount, eqType)
	bandTypeCount[bandType(eqType)] = bandTypeCount[bandType(eqType)] + 1; 
	return bandTypeCount;
end
function ApplySceneSettingsToTracks()
	for ch = 1, 32, 1 do
		local track = reaper.GetTrack(project, ch-1);
		--local ok, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", trackSettings[ch].name, true);
		ok = reaper.SetMediaTrackInfo_Value(track, "D_VOL", trackSettings[ch].volume);
		ok = reaper.SetMediaTrackInfo_Value(track, "D_PAN", trackSettings[ch].pan);

		-- gate
		if trackSettings[ch].gate.on == "ON" then
			local fxPos = reaper.TrackFX_AddByName(track, "ReaGate", false, -1);

			-- #0 threshold
			ok = reaper.TrackFX_SetParam(track, fxPos, 0, trackSettings[ch].gate.threshold);
			-- #1 attack
			ok = reaper.TrackFX_SetParam(track, fxPos, 1, rangeToIdentity(trackSettings[ch].gate.attack, 0, 500));
			-- #2 release
			ok = reaper.TrackFX_SetParam(track, fxPos, 2, rangeToIdentity(trackSettings[ch].gate.release, 0, 5000));
			-- #3 pre-open
			-- #4 hold
			ok = reaper.TrackFX_SetParam(track, fxPos, 4, rangeToIdentity(trackSettings[ch].gate.hold, 0, 1000));
			-- #5 low pass
			-- #6 high pass
			-- #7 SignIn ???
			-- #8 AudIn ???
			-- #9 Dry Volume
			-- #10 Wet Volume
			-- #11 Noise Volume
			-- #12 Hysteresis
			-- #13 Preview F
			-- #14 RMS Size
			-- #15 UseMidi
			-- #16 Midi Note
			-- #17 Midi Chan
			-- #18 Invert Wet / Duck
			if trackSettings[ch].gate.type == "DUCK" then
				ok = reaper.TrackFX_SetParam(track, fxPos, 18, 1);
			else
				ok = reaper.TrackFX_SetParam(track, fxPos, 18, 0);
			end

			-- parameter settings
			--local fxParamCount = reaper.TrackFX_GetNumParams(track, fxPos);
			--for i = 0, fxParamCount-1, 1 do
			--	local retval, minval, maxval = reaper.TrackFX_GetParam(track, fxPos, i);
			--	log("Gate Param# "..i..": "..retval.." min: "..minval.." max:"..maxval);
			--end
		end

		-- compression before eq
		local compPos;
		if trackSettings[ch].compression.position == "PRE" and trackSettings[ch].compression.on == "ON" then
			compPos = reaper.TrackFX_AddByName(track, "ReaComp", false, -1);
		end

		-- eq
		if trackSettings[ch].eq.on == "ON" then
			local fxPos = reaper.TrackFX_AddByName(track, "ReaEQ", false, -1);

			-- Bandtype: -1=master gain, 0=lhipass, 1=loshelf, 2=band, 3=notch, 4=hishelf, 5=lopass.
			-- Bandidx: 0=target first band matching bandtype, 1=target 2nd band matching bandtype, etc.
			-- Paramtype: 0=freq, 1=gain, 2=Q.

			-- parmname for TrackFX_SetNamedConfigParm
			-- INSERT_X - insert band at specified ID
			-- ADD - add band after last tab
			-- REMOVE_X - remove band
			-- BANDTYPE_X (current API is limited to 5 types)
			-- SHOWTABS - check
			-- TABCNT - return tabs count (when use with "Set", insert at the end needed tabs count to match TABCNT_X variable)
			local bandTypeCount = {};
			for band = 0, 5, 1 do
				bandTypeCount[band] = 0;
			end
			ok = reaper.TrackFX_SetPreset(track, fxPos, "X32 Import");
			if trackSettings[ch].lowCutOn == "ON" then
				ok = reaper.TrackFX_SetEQParam(track, fxPos, bandType("LCut"), 0, 0, trackSettings[ch].lowCutFreq, false);
				bandTypeCount = updateBandTypeCount(bandTypeCount, "LCut");
			end

			if trackSettings[ch].eq.channels and type(trackSettings[ch].eq.channels) == "table" then
				for b = 1, 4, 1 do
					--log("Track: "..ch.." b: "..b);
					--log(trackSettings[ch].eq);
					--log("type: "..trackSettings[ch].eq.channels[b].type);
					--log("freq: "..trackSettings[ch].eq.channels[b].frequency);
					--log("gain: "..trackSettings[ch].eq.channels[b].gain);
					--log("q: "..trackSettings[ch].eq.channels[b].q);
					local channels = trackSettings[ch].eq.channels;
					--log("Band #"..band); -- 
					--log("type: "..channels[b].type.." freq: "..channels[b].frequency);
					local bandMatch = bandTypeCount[bandType(channels[b].type)]; -- gets the current position id for a specific EQ Band type
					ok = reaper.TrackFX_SetEQParam(track, fxPos, bandType(channels[b].type), bandMatch, paramType.freq, channels[b].frequency, 	false);
					ok = reaper.TrackFX_SetEQParam(track, fxPos, bandType(channels[b].type), bandMatch, paramType.gain, channels[b].gain, 		false);
					ok = reaper.TrackFX_SetEQParam(track, fxPos, bandType(channels[b].type), bandMatch, paramType.q, 	channels[b].q, 			false);
					bandTypeCount = updateBandTypeCount(bandTypeCount, channels[b].type);
				end
			end
		end

		-- compression after eq
		if trackSettings[ch].compression.position == "POST" and trackSettings[ch].compression.on == "ON" then
			compPos = reaper.TrackFX_AddByName(track, "ReaComp", false, -1);
		end
		-- compression settings
		if trackSettings[ch].compression.on == "ON" then
			-- #0 Threshold
			ok = reaper.TrackFX_SetParam(track, compPos, 0, trackSettings[ch].compression.threshold);
			-- #1 Ratio
			ok = reaper.TrackFX_SetParam(track, compPos, 1, trackSettings[ch].compression.ratio);
			-- #2 Attack
			ok = reaper.TrackFX_SetParam(track, compPos, 2, rangeToIdentity(trackSettings[ch].compression.attack, 0, 500));
			-- #3 Release
			ok = reaper.TrackFX_SetParam(track, compPos, 3, rangeToIdentity(trackSettings[ch].compression.release, 0, 5000));
			-- #4 Pre-Comp
			-- #5 resvd
			-- #6 low pass
			-- #7 hi pass
			-- #8 signIn
			-- #9 AudIn
			-- #10 Dry volume
			-- #11 Wet volume
			ok = reaper.TrackFX_SetParam(track, compPos, 11, trackSettings[ch].compression.gain);
			-- #12 PreviewF
			-- #13 RMS Size
			-- #14 Knee
			ok = reaper.TrackFX_SetParam(track, compPos, 14, trackSettings[ch].compression.knee);
			-- #15 AutoMkUp
			-- #16 AutoRel
			-- #17 ClsAttk
			-- #18 AntiAIs
		end

		--log("Volume "..trackSettings[ch].name..": "..trackSettings[ch].volume);
	end

	log("Scene Settings Applied.");
end
function ApplySceneSettingsToGroups()
	-- apply dca group volume
	ok = reaper.SetMediaTrackInfo_Value(drumsTrack, "D_VOL", dcagroups[1].volume);
	ok = reaper.SetMediaTrackInfo_Value(bandTrack, "D_VOL", dcagroups[2].volume);
	ok = reaper.SetMediaTrackInfo_Value(vocalsTrack, "D_VOL", dcagroups[3].volume);
end
function sleep(n)
  local t = os.clock()
  while os.clock() - t <= n do
    -- nothing
  end
end
function AddGroupFX()
end

-- get Scene File from project folder
sceneFileName = scandir(projectPath);

-- load scene and apply settings to tracks
LoadScene(projectPath,sceneFileName);

ApplySceneSettingsToTracks();

-- remove sends for master track - to be added back later
TrackRemoveSends(masterTrack, false);
RemoveEmptyTracks();
AddGroupTracks();
AddGroupSends();
ApplySceneSettingsToGroups();



AddGroupFX();

-- Reference

	-- AES50 1-8 starts with /headamp/032

    -- Track         Name
	-- /ch/01/config "KICK" 1 GN 1

	-- Track         Vol  Flip Polarity Low cut     hertz - low cut
	-- /ch/01/preamp -0.5 OFF           ON      24  39
	-- /ch/06/preamp +0.0 OFF           OFF     24  20
	-- /ch/15/preamp +0.0 OFF           ON      24 110

	-- Track +31    Preamp Volume 48V
	-- /headamp/032 +21.0         ON
	-- /headamp/033 +23.0         ON

	--                     Main 
	-- Track      Mute Vol  LR Pan M/C  Center Volume
	-- /ch/04/mix OFF  -4.1 ON -50 ON   0.0
	-- /ch/05/mix OFF  -3.9 ON +50 ON   0.0
	-- /ch/07/mix ON   -oo OFF +0 OFF   -oo

	-- Track          Type Threshold Range Attack Hold Release keyCh
	-- /ch/01/gate ON GATE -51.5     9.0   0      14.1  77     0
	-- /ch/02/gate ON DUCK -34.5     20.0  0      70.9  576    1

	-- Track                 Type Frequency
	-- /ch/01/gate/filter ON 5.0  2k04
	-- /ch/02/gate/filter ON HC12 108.7
    
    --        Compression Gain
	-- Track         Type Type Envelope Threshold Ratio Knee Gain Attack Hold Release *Position keyCh Mix Auto
	-- /ch/01/dyn ON COMP PEAK LOG      -42.5     1.5   2    6.00 31     0.11  185    POST      0     100 OFF
	-- /ch/02/dyn ON EXP  PEAK LOG      -39.5     2.5   1    5.00 36     0.02  198    PRE       3     100 OFF
	-- *Position - POST is after EQ, PRE is before EQ

	-- Track                Type Frequency
	-- /ch/01/dyn/filter ON 3.0  120.5

	-- Track       Type Frequency Gain  Q
	-- /ch/03/eq ON
	-- /ch/01/eq/1 PEQ  71.8      +5.00 1.6
	-- /ch/01/eq/2 PEQ  153.5     -7.25 3.5
	-- /ch/01/eq/3 PEQ  306.2     -5.00 2.0
	-- /ch/01/eq/4 HCut 893.4     -1.75 1.2
	-- Types = LCut, LShv, PEQ, VEQ, HShv, HCut

	-- Sends
	-- /ch/02/mix OFF -10.0 ON +0 ON   0.0 - main send: see above
	-- Track/Bus     Mute Vol Pan Send From
	-- /ch/02/mix/01 ON   -oo +0  IN/LC 
	-- /ch/02/mix/02 ON   -oo
	-- /ch/02/mix/03 ON   -oo +0 <-EQ
	-- /ch/02/mix/04 ON   -oo
	-- /ch/02/mix/05 ON   -oo +0 EQ->
	-- /ch/02/mix/06 ON   -oo
	-- /ch/02/mix/07 ON   -oo +0 PRE
	-- /ch/02/mix/08 ON   -oo
	-- /ch/02/mix/09 ON  -9.5 +60 POST
	-- /ch/02/mix/10 ON  -9.5
	-- /ch/02/mix/11 ON   -oo +0 GRP
	-- /ch/02/mix/12 ON   -oo
	-- From Locations: 
	--   IN/LC - Input
	--   <-EQ - Pre-EQ
	--   EQ-> - Post-EQ
	--   Pre  - Pre Fader
	--   POST - Post Fader
	--   GRP  - Sub Group
	-- Pan only active for linked channels

	-- FX
	-- Track Name
	-- /fx/1 4TAP
	--              Source Channels
	-- /fx/1/source MIX13 MIX13
	-- Parameters time Base Gain Feed % Low Cut hz High Cut hz Spread FactorA GainA FactorB GainB FactorC GainC X-Feed Mono Dry unused...
	-- /fx/1/par  608       100  30.0   10         20k0        5      4/3     50    1       50    3/2     50    OFF    OFF  OFF 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
	-- plate reverb
	-- /fx/2 PLAT
	-- /fx/2/source MIX14 MIX14
	--           Pre Delay Decay Size Damphz Diff Level Low Cut Hi Cut Bass Multiplier XOver hz Mod Depth Mod Speed unused...
	-- /fx/2par 32        2.84  68   6k50   30   0.0   60      7k2    1.09            211.44   20        20        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

	-- DCA Groups
	-- /dca/1 ON  -5.6
	-- /dca/1/config "Drums" 11 GN
	-- /dca/2 ON  -6.4
	-- /dca/2/config "Band" 44 BLi
	-- /dca/3 ON  +1.5
	-- /dca/3/config "Vox" 43 GNi
	-- /dca/4 ON  +0.2
