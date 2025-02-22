package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import haxe.Json;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import openfl.Assets;

using StringTools;

typedef MenuData =
{	
	menuItemsAlignement:String,
	menuItemsX:Null<Int>,
	backgroundSprite:String
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.1'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	public static var ghostedEngine:String = "Ghosted Engine pre-1.0";

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var menuJSON:MenuData;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var magenta:FlxSprite;

	var randomTxt:FlxText;

	var isTweening:Bool = false;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var bg:FlxSprite;

    var engineText:FlxText;
	var lastString:String = '';

	override function create()
	{
		Paths.clearUnusedMemory();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/menuOptions.json";
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "mods/images/menuOptions.json";
		}
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "assets/images/menuOptions.json";
		}
		//trace(path, FileSystem.exists(path));
		menuJSON = Json.parse(File.getContent(path));
		#else
		var path = Paths.getPreloadPath("images/menuOptions.json");
		menuJSON = Json.parse(Assets.getText(path)); 
		#end

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		//var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		if (menuJSON.backgroundSprite != null && menuJSON.backgroundSprite.length > 0 && menuJSON.backgroundSprite != "none") {
			bg = new FlxSprite(-80).loadGraphic(Paths.image(menuJSON.backgroundSprite));
		} else {
			bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		}
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		magenta.visible = false;
		add(magenta);
		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 0.95;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(menuJSON.menuItemsX, (i * 140)  + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			if (menuJSON.menuItemsAlignement == "center") { menuItem.screenCenter(X); } else if (menuJSON.menuItemsAlignement == "left") { menuItem.x = 100; }
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();

			/*FlxTween.tween(menuItem,{y: 60 + (i * 160)},1 + (i * 0.25) ,{ease: FlxEase.expoInOut, onComplete: function(flxTween:FlxTween) 
			{ 
				changeItem();
			}});*/
			//menuItem.y = 60 + (i * 160);

			/*var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.scale.set(scale, scale);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.updateHitbox();
			FlxTween.tween(menuItem,{y: 60 + (i * 160)},1 + (i * 0.25) ,{ease: FlxEase.expoInOut, onComplete: function(flxTween:FlxTween) 
			{ 
				changeItem();
			}});
			menuItem.y = 60 + (i * 160);*/
		}

		FlxG.camera.follow(camFollowPos, LOCKON, 0.025);

        var bottomPanel:FlxSprite = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, 0xFF000000);
		add(bottomPanel);

		bottomPanel.alpha = 0.5;
        bottomPanel.scrollFactor.set();

		var versionShit:FlxText = new FlxText(20, FlxG.height - 35, 1000, "Friday Night Funkin' v" + Application.current.meta.get('version'), 16);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		engineText = new FlxText(0, FlxG.height - 35, 1000, ghostedEngine, 16);
		engineText.scrollFactor.set();
		engineText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(engineText);
		engineText.x = (FlxG.width - engineText.width) - 20;

		randomTxt = new FlxText(20, FlxG.height - 80, 1000, "", 26);
		randomTxt.scrollFactor.set();
		randomTxt.setFormat("VCR OSD Mono", 26, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(randomTxt);

        versionShit.borderSize = 1.5;
		versionShit.borderQuality = 1;
		engineText.borderSize = 1.5;
		engineText.borderQuality = 1;

		randomTxt.borderSize = 2;

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

        FlxG.camera.zoom = 1.5;
		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.25, {ease: FlxEase.cubeOut});

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;
	var timer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (isTweening)
			{
				randomTxt.screenCenter(X);
				timer = 0;
			}
			else
			{
				randomTxt.screenCenter(X);
				timer += elapsed;
				if (timer >= 3)
				{
					changeText();
				}
			}
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(FlxG.camera, {zoom: 5}, 0.8, {ease: FlxEase.expoIn});
							FlxTween.tween(bg, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
							FlxTween.tween(magenta, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
							FlxTween.tween(bg, {alpha: 0}, 0.8, {ease: FlxEase.expoIn});
							FlxTween.tween(magenta, {alpha: 0}, 0.8, {ease: FlxEase.expoIn});
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										FlxTween.cancelTweensOf(FlxG.camera);
										FlxTween.tween(FlxG.camera, {zoom: 1.5}, 1, {ease: FlxEase.quadOut});
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										FlxTween.cancelTweensOf(FlxG.camera);
										FlxTween.tween(FlxG.camera, {zoom: 1.5}, 1, {ease: FlxEase.quadOut});
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (menuJSON.menuItemsX == 640 || menuJSON.menuItemsX == null) spr.screenCenter(X) else spr.x = menuJSON.menuItemsX;
		});
	}

	function changeText()
	{
		var selectedText:String = '';
		var textArray:Array<String> = CoolUtil.coolTextFile(Paths.txt('inGameText'));

		#if MODS_ALLOWED
		textArray.insert(0, Paths.mods('data/inGameText'));
		#end

		randomTxt.alpha = 1;
		isTweening = true;
		selectedText = textArray[FlxG.random.int(0, (textArray.length - 1))].replace('--', '\n');
		FlxTween.tween(randomTxt, {alpha: 0}, 1, {
			ease: FlxEase.linear,
			onComplete: function(shit:FlxTween)
			{
				if (selectedText != lastString)
				{
					randomTxt.text = selectedText;
					lastString = selectedText;
				}
				else
				{
					selectedText = textArray[FlxG.random.int(0, (textArray.length - 1))].replace('--', '\n');
					randomTxt.text = selectedText;
				}

				randomTxt.alpha = 0;

				FlxTween.tween(randomTxt, {alpha: 1}, 1, {
					ease: FlxEase.linear,
					onComplete: function(shit:FlxTween)
					{
						isTweening = false;
					}
				});
			}
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
	
	override function beatHit()
	{
		super.beatHit();
		if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 1 == 0)
			FlxG.camera.zoom += 0.015;
	}
}
