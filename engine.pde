import java.util.HashSet;
import java.io.File;
import java.net.MalformedURLException;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.io.FileOutputStream;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.Toolkit;
import processing.video.Movie;
import org.freedesktop.gstreamer.*;
import java.util.TreeSet;
import java.io.InputStream;
import java.io.FileOutputStream;
import java.net.URL;
import java.util.zip.*;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.awt.datatransfer.StringSelection;
import java.awt.Toolkit;
import java.awt.datatransfer.Clipboard;
import gifAnimation.*;
import javax.sound.sampled.*;
import java.io.ByteArrayInputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.ShortBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.nio.file.Paths;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.nio.file.*;
import java.awt.Desktop;
import java.nio.file.attribute.*;
import java.util.ArrayList;
import java.util.List;
import com.sun.jna.Native;
import com.sun.jna.Structure;
// Timeway's engine code.
// TODO: add documentation lmao.

class Engine {
  //*****************CONSTANTS SETTINGS**************************
  // Info and versioning
  public final String NAME        = "Timeway";
  public final String AUTHOR      = "Teo Taylor";
  public final String VERSION     = "0.1.2";
  public final String VERSION_DESCRIPTION = 
    "- Added terrain customisation\n"+
    "- Fixed a buncha bugs.";
  // ***************************
  // How versioning works:
  // a.b.c
  // a is just gonna stay 0 most of the time unless something significant happens
  // b is a super major release where the system has a complete overhaul.
  // c is pretty much every release whether that's bug fixes or other things.
  // a, b, and c can go well over 10, 100, it can be any positive integer.

  // Paths
  public final String CONSOLE_FONT        = "data/engine/font/SourceCodePro-Regular.ttf";
  public final String IMG_PATH            = "data/engine/img/";
  public final String FONT_PATH           = "data/engine/font/";
  public final String DEFAULT_FONT_PATH   = "data/engine/font/Typewriter.vlw";
  public final String SHADER_PATH         = "data/engine/shaders/";
  public final String SOUND_PATH          = "data/engine/sounds/";
  public final String CONFIG_PATH         = "data/config.json";
  public final String KEYBIND_PATH        = "data/keybindings.json";
  public final String STATS_FILE          = "data/stats.json";
  public final String PATH_SPRITES_ATTRIB = "data/engine/spritedata/";
  public final String GLITCHED_REALM      = "data/engine/default/glitched_realm/";
  public final String CACHE_INFO          = "data/cache/cache_info.json";
  public final String CACHE_PATH          = "data/cache/";
  public final String WINDOWS_CMD         = "data/engine/shell/mywindowscommand.bat";
  public final String POCKET_PATH         = "data/pocket/";
  public final String TEMPLATES_PATH      = "data/engine/realmtemplates/";
  public       String DEFAULT_UPDATE_PATH = "";  // Set up by setup()

  // Static constants
  public static final float   KEY_HOLD_TIME       = 30.; // 30 frames
  public static final int     POWER_CHECK_INTERVAL = 5000;
  public static final String  CACHE_COMPATIBILITY_VERSION = "0.3";
  public static final String  CACHE_FILE_TYPE = "png";
  public static final boolean CACHE_MUSIC = true;
  

  // Dynamic constants (changes based on things like e.g. configuration file)
  public       PFont  DEFAULT_FONT;
  public       String DEFAULT_DIR;
  public       String DEFAULT_FONT_NAME = "Typewriter";


  public final String ENTRY_EXTENSION = "timewayentry";
  public final String[] SHORTCUT_EXTENSION = {"timewayshortcut"};


  //*************************************************************
  //**************ENGINE SETUP CODE AND VARIABLES****************
  // Core stuff
  public PApplet app;
  public String APPPATH = sketchPath().replace('\\', '/')+"/";
  
  // Modules
  public Console console;
  public SharedResourcesModule sharedResources;
  public SettingsModule settings;
  public DisplayModule display;
  public PowerModeModule power;
  public AudioModule sound;
  public FilemanagerModule file;
  public ClipboardModule clipboard;
  public UIModule ui;
  public InputModule input;


  
  
  

  // Screens
  public Screen currScreen;
  public Screen prevScreen;
  public boolean transitionScreens = false;
  public float transition = 0;
  public int transitionDirection = RIGHT;
  public boolean initialScreen = true;


  // Settings & config
  public boolean devMode = false;

  // Other / doesn't fit into any categories.
  public boolean wireframe;
  public SpriteSystemPlaceholder spriteSystemPlaceholder;
  public long lastTimestamp;
  public String lastTimestampName = null;
  public int timestampCount = 0;
  public boolean allowShowCommandPrompt = true;
  public boolean playWhileUnfocused = true;
  public HashMap<Long, Float> noiseCache = new HashMap<Long, Float>();
  public HashSet<Float> noiseCacheConflicts = new HashSet<Float>();
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class SharedResourcesModule {
    private HashMap<String, Object> sharedResourcesMap;
    
    public SharedResourcesModule() {
      sharedResourcesMap = new HashMap<String, Object>();
    }
    
    public void set(String resourceName, Object val) {
      sharedResourcesMap.put(resourceName, val);
    }
    
    public Object get(String resourceName) {
      Object o = sharedResourcesMap.get(resourceName);
      if (o == null) console.bugWarn("get: null object. Maybe use set or add a runnable argument to get?");
      return o;
    }
    
    public Object get(String resourceName, Object addIfAbsent) {
      Object o = sharedResourcesMap.get(resourceName);
      if (o == null) this.set(resourceName, addIfAbsent);
      o = sharedResourcesMap.get(resourceName);
      // If it's still null after running, send a warning
      if (o == null) console.bugWarn("get: You just passed a null object...?");
      return o;
    }
    
    public Object get(String resourceName, Runnable runIfAbsent) {
      Object o = sharedResourcesMap.get(resourceName);
      if (o == null) runIfAbsent.run();
      o = sharedResourcesMap.get(resourceName);
      // If it's still null after running, send a warning
      if (o == null) console.bugWarn("get: object still null after running runIfAbsent. Make sure to use set in your runnable!");
      return o;
    }
    
    public void remove(String resourceName) {
      sharedResourcesMap.remove(resourceName);
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class SettingsModule {
      private JSONObject settings;
      private JSONObject keybindings;
      private HashMap<String, Object> defaultSettings = new HashMap<String, Object>();
      private HashMap<String, Character> defaultKeybindings = new HashMap<String, Character>();
      
      public SettingsModule() {
        loadDefaultSettings();
        settings = loadConfig(APPPATH+CONFIG_PATH, defaultSettings);
        keybindings = loadConfig(APPPATH+KEYBIND_PATH, defaultKeybindings);
      }
      
      public char getKeybinding(String keybindName) {
        String s = keybindings.getString(keybindName);
        char k;
        if (s == null) {
          if (defaultKeybindings.get(keybindName) != null) k = defaultKeybindings.get(keybindName);
          else { console.bugWarnOnce("getKeybinding: unknown keyaction "+keybindName);
          return 0; }
        }
        else k = s.charAt(0);
        return k;
      }
      
      public boolean getBoolean(String setting) {
        boolean b = false;
        try {
          b = settings.getBoolean(setting);
        }
        catch (NullPointerException e) {
          if (defaultSettings.containsKey(setting)) {
            b = (boolean)defaultSettings.get(setting);
          } else {
            console.warnOnce("Setting "+setting+" does not exist.");
            return false;
          }
        }
        return b;
      }
    
      public float getFloat(String setting) {
        float f = 0.0;
        try {
          f = settings.getFloat(setting);
        }
        catch (RuntimeException e) {
          if (defaultSettings.containsKey(setting)) {
            f = (float)defaultSettings.get(setting);
          } else {
            console.warnOnce("Setting "+setting+" does not exist.");
            return 0.;
          }
        }
        return f;
      }
    
      public String getString(String setting) {
        String s = "";
        s = settings.getString(setting);
        if (s == null) {
          if (defaultSettings.containsKey(setting)) {
            s = (String)defaultSettings.get(setting);
          } else {
            console.warnOnce("Setting "+setting+" does not exist.");
            return "";
          }
        }
        return s;
      }
    
      public final int LEFT_CLICK = 1;
      public final int RIGHT_CLICK = 2;
      
      public void loadDefaultSettings() {
        defaultSettings = new HashMap<String, Object>();
        defaultSettings.putIfAbsent("fullscreen", false);
        defaultSettings.putIfAbsent("scrollSensitivity", 20.0);
        defaultSettings.putIfAbsent("dynamicFramerate", true);
        defaultSettings.putIfAbsent("lowBatteryPercent", 50.0);
        defaultSettings.putIfAbsent("autoScaleDown", false);
        defaultSettings.putIfAbsent("defaultSystemFont", "Typewriter");
        defaultSettings.putIfAbsent("homeDirectory", System.getProperty("user.home").replace('\\', '/'));
        defaultSettings.putIfAbsent("forcePowerMode", "NONE");
        defaultSettings.putIfAbsent("volumeNormal", 1.0);
        defaultSettings.putIfAbsent("volumeQuiet", 0.0);
        defaultSettings.putIfAbsent("fasterImageImport", false);
        defaultSettings.putIfAbsent("waitForGStreamerStartup", true);
        defaultSettings.putIfAbsent("enableExperimentalGifs", false);
        defaultSettings.putIfAbsent("cache_miss_no_music", true);
    
        defaultKeybindings = new HashMap<String, Character>();
        defaultKeybindings.putIfAbsent("CONFIG_VERSION", char(1));
        defaultKeybindings.putIfAbsent("moveForewards", 'w');
        defaultKeybindings.putIfAbsent("moveBackwards", 's');
        defaultKeybindings.putIfAbsent("moveLeft", 'a');
        defaultKeybindings.putIfAbsent("moveRight", 'd');
        defaultKeybindings.putIfAbsent("lookLeft", 'q');
        defaultKeybindings.putIfAbsent("lookRight", 'e');
        defaultKeybindings.putIfAbsent("menu", '\t');
        defaultKeybindings.putIfAbsent("menuSelect", '\t');
        defaultKeybindings.putIfAbsent("jump", ' ');
        defaultKeybindings.putIfAbsent("sneak", char(0x0F));
        defaultKeybindings.putIfAbsent("dash", 'r');
        defaultKeybindings.putIfAbsent("scaleUp", '=');
        defaultKeybindings.putIfAbsent("scaleDown", '-');
        defaultKeybindings.putIfAbsent("scaleUpSlow", '+');
        defaultKeybindings.putIfAbsent("scaleDownSlow", '_');
        defaultKeybindings.putIfAbsent("primaryAction", 'o');
        defaultKeybindings.putIfAbsent("secondaryAction", 'p');
        defaultKeybindings.putIfAbsent("inventorySelectLeft", ',');
        defaultKeybindings.putIfAbsent("inventorySelectRight", '.');
        defaultKeybindings.putIfAbsent("scaleDownSlow", '_');
        defaultKeybindings.putIfAbsent("showCommandPrompt", '/');
        defaultKeybindings.putIfAbsent("prevDirectory", char(8));
        for (int i = 0; i < 10; i++) defaultKeybindings.putIfAbsent("quickWarp"+str(i), str(i).charAt(0));
      }
      
      public JSONObject loadConfig(String configPath, HashMap defaultConfig) {
      File f = new File(configPath);
      JSONObject returnSettings = null;
      boolean newConfig = false;
      if (!f.exists()) {
        newConfig = true;
      } else {
        try {
          returnSettings = loadJSONObject(configPath);
        }
        catch (RuntimeException e) {
          console.warn("There's an error in the config file. Loading default settings.");
          newConfig = true;
        }
      }
  
      // New config
      if (newConfig) {
        console.log("Config file not found, creating one.");
        returnSettings = new JSONObject();
  
  
        for (String k : (Iterable<String>)defaultConfig.keySet()) {
          if (defaultConfig.get(k) instanceof Boolean)
            returnSettings.setBoolean(k, (boolean)defaultConfig.get(k));
          else if (defaultConfig.get(k) instanceof String)
            returnSettings.setString(k, (String)defaultConfig.get(k));
          else if (defaultConfig.get(k) instanceof Float)
            returnSettings.setFloat(k, (float)defaultConfig.get(k));
          else if (defaultConfig.get(k) instanceof Character) {
            String s = "";
            s += defaultConfig.get(k);
            returnSettings.setString(k, s);
          }
        }
  
        try {
          saveJSONObject(returnSettings, configPath);
        }
        catch (RuntimeException e) {
          console.warn("Failed to save config.");
        }
      }
      return returnSettings;
    }
  }
  
  


  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class PowerModeModule {
    
  // Power modes
    private PowerMode powerMode = PowerMode.HIGH;
    private boolean noBattery = false;
    private boolean sleepyMode = false;
    private boolean dynamicFramerate = true;
    private boolean powerSaver = false;
    private int lastPowerCheck = 0;
    
    public PowerMode getPowerMode() {
      return powerMode;
    }
    
    
    final int MONITOR = 1;
    final int RECOVERY = 2;
    final int SLEEPY = 3;
    final int GRACE  = 4;
    int fpsTrackingMode = MONITOR;
    float fpsScore = 1000.;
    float scoreDrain = 1.;
    float recoveryScore = 1.;
    
    PowerMode prevPowerMode = PowerMode.HIGH;
    int recoveryFrameCount = 0;
    int graceTimer = 0;
    int recoveryPhase = 1;
    float framerateBuffer[];
    private boolean forcePowerModeEnabled = false;
    private PowerMode forcedPowerMode = PowerMode.HIGH;
    private PowerMode powerModeBefore = PowerMode.NORMAL;
    
    final float BASE_FRAMERATE = 60;
    float targetFramerate = 60;
  
    // The score that seperates the stable fps from the unstable fps.
    // If you've got half a brain, it would make the most sense to keep it at 0.
    final float FPS_SCORE_MIDDLE = 0.;
  
    // Increase the score if the framerate is good but we're in the unstable zone.
    private final float UNSTABLE_CONSTANT = 7.;
  
    // Once we reach this score, we drop down to the previous frame.
    private final float FPS_SCORE_DROP = -3000;
  
    // If we gradually manage to make it to that score, we can go into RECOVERY mode to test what the framerate's like
    // up a level.
    private final float FPS_SCORE_RECOVERY = 500.;
  
    // We want to recover to a higher framerate only if we're able to achieve a pretty good framerate.
    // The higher you make RECOVERY_NEGLIGENCE, the more it will neglect the possibility of recovery.
    // For example, trying to achieve 60fps but actual is 40fps, the system will likely recover faster if
    // RECOVERY_NEGLIGENCE is set to 1 but very unlikely if it's set to something higher like 5.
    private final float RECOVERY_NEGLIGENCE = 1;
    
    private final int RECOVERY_PHASE_1_FRAMES = 20;
    private final int RECOVERY_PHASE_2_FRAMES = 120;   // 2 seconds
    
    public PowerModeModule() {
      setForcedPowerMode(settings.getString("forcePowerMode"));
    }
    
    public void setDynamicFramerate(boolean b) {
      dynamicFramerate = b;
    }
    
    
    public String getPowerModeString() {
      switch (powerMode) {
        case HIGH:
        return "HIGH";
        case NORMAL:
        return "NORMAL";
        case SLEEPY:
        return "SLEEPY";
        case MINIMAL:
        return "MINIMAL";
        default:
        console.bugWarn("getPowerModeString: Unknown power mode");
        return "";
      }
    }
    
    public void setForcedPowerMode(String p) {
      forcePowerModeEnabled = true;   // Temp set to true, if not enabled, it will reset to false.
      if (p.equals("HIGH"))
        forcedPowerMode = PowerMode.HIGH;
      else if (p.equals("NORMAL"))
        forcedPowerMode = PowerMode.NORMAL;
      else if (p.equals("SLEEPY"))
        forcedPowerMode = PowerMode.SLEEPY;
      else if (p.equals("MINIMAL")) {
        console.log("forcePowerMode set to MINIMAL, I wouldn't do that if I were you!");
        forcedPowerMode = PowerMode.MINIMAL;
      }
      // Anything else (e.g. "NONE")
      else {
        forcePowerModeEnabled = false;
      }
    }
    
    public void setForcedPowerMode(PowerMode p) {
      forcePowerModeEnabled = true;
      forcedPowerMode = p;
      if (p == PowerMode.MINIMAL) {
        console.log("forcePowerMode set to MINIMAL, I wouldn't do that if I were you!");
      }
    }
    
    public void disableForcedPowerMode() {
      forcePowerModeEnabled = false;
    }
    
    public void setPowerSaver(boolean b) {
      power.powerSaver = b;
      
      if (b)
        forcePowerModeEnabled = false;
      else {
        setPowerMode(PowerMode.NORMAL);
        forceFPSRecoveryMode();
      }
    }
    
    public boolean getPowerSaver() { return powerSaver; }
    
    public class NoBattery extends RuntimeException {
      public NoBattery(String message) {
        super(message);
      }
    }
  
    public void updateBatteryStatus() {
      //powerStatus = new Kernel32.SYSTEM_POWER_STATUS();
      //Kernel32.INSTANCE.GetSystemPowerStatus(powerStatus);
    }
  
    public int batteryPercentage() throws NoBattery {
      //String str = powerStatus.getBatteryLifePercent();
      String str = "100";
      str = str.substring(0, str.length()-1);
      try {
        int percent = Integer.parseInt(str);
        return percent;
      }
      catch (NumberFormatException ex) {
        throw new NoBattery("Battery not found..? ("+str+")");
      }
    }
  
    public boolean isCharging() {
      //return (powerStatus.getACLineStatusString().equals("Online"));
      return false;
    }
  
    public void updatePowerModeNow() {
      lastPowerCheck = millis();
    }
  
    public void setSleepy() {
      if (dynamicFramerate) {
        if (!isCharging() && !noBattery && !sleepyMode) {
          sleepyMode = true;
          powerModeBefore = getPowerMode();
          lastPowerCheck = millis()+POWER_CHECK_INTERVAL;
        }
      } else {
        sleepyMode = false;
      }
    }
  
    // You shouldn't call this every frame
    public void setAwake() {
      sleepyMode = false;
      if (getPowerMode() == PowerMode.SLEEPY) {
        putFPSSystemIntoGraceMode();
        setPowerMode(powerModeBefore);
      }
    }
  
    private int powerModeSetTimeout = 0;
    public void setPowerMode(PowerMode m) {
      // Really just a debugging message to keep you using it appropriately.
      //if (powerModeSetTimeout == 1)
      //  console.warnOnce("You shouldn't call setPowerMode on every frame, otherwise Timeway will seriously stutter.");
      //powerModeSetTimeout = 2;
      // Only update if it's not already set to prevent a whole load of bugs
      if (powerMode != m) {
        powerMode = m;
        switch (m) {
        case HIGH:
          frameRate(60);
          //console.log("Power mode HIGH");
          break;
        case NORMAL:
          frameRate(30);
          //console.log("Power mode NORMAL");
          break;
        case SLEEPY:
          frameRate(10);
          //console.log("Power mode SLEEPY");
          break;
        case MINIMAL:
          frameRate(1); //idk for now
          //console.log("Power mode MINIMAL");
          break;
        }
      }
    }
  
    // basically use when you expect a significant difference in fps from that point forward.
    public void forceFPSRecoveryMode() {
      fpsScore = FPS_SCORE_MIDDLE;
      fpsTrackingMode = RECOVERY;
      recoveryFrameCount = 0;
      // Record the next 5 frames.
      framerateBuffer = new float[5];
      recoveryPhase = 1;
    }
  
    // use before you expect a sudden delay, e.g. loading something during runtime or switching screens.
    // We basically are telling the fps system to pause its score tracking as the average framerate drops.
    public void putFPSSystemIntoGraceMode() {
      fpsTrackingMode = GRACE;
      graceTimer = 0;
    }
  
    // Similar to putFPSSystemIntoGraceMode() but reset the score.
    // Use when you expect a different average fps, e.g. switching screens.
    // We are telling the fps system to pause so the average framerate can fill up,
    // and then reset the score so it can fairly decide what fps the new scene/screen/whatever
    // should run in.
    public void resetFPSSystem() {
      putFPSSystemIntoGraceMode();
      fpsScore = FPS_SCORE_MIDDLE;
      scoreDrain = 1.;
      recoveryScore = 1.;
    }
    
    public void updatePowerMode() {
      // Just so we can provide a warning lol
      powerModeSetTimeout = max(0, powerModeSetTimeout-1);
  
      // Rules:
      // If plugged in or no battery, have it running at POWER_MODE_HIGH by default.
      // If on battery, the rules are as follows:
      // - POWER_MODE_HIGH    60fps
      // - POWER_MODE_NORMAL  30fps
      // - POWER_MODE_SLEEPY  15 fps
      // - POWER_MODE_MINIMAL loop is turned off
  
      // - POWER_MODE_HIGH if power is above 30% and average fps over 2 seconds is over 58
      // - POWER_MODE_NORMAL stays in 
      // - POWER_MODE_SLEEPY if 30% or below and window isn't focussed
      // - POWER_MODE_MINIMAL if minimised
      // 
      // Go into 1fps mode
  
      // If the window is not focussed, don't even bother doing anything lol.
  
      if (focused) {
        if (!focusedMode) {
          setPowerMode(prevPowerMode);
          focusedMode = true;
          putFPSSystemIntoGraceMode();
          sound.setNormalVolume();
        }
      } else {
        if (focusedMode) {
          prevPowerMode = powerMode;
          setPowerMode(PowerMode.MINIMAL);
          focusedMode = false;
          input.releaseAllInput();
          
          if (playWhileUnfocused)
            sound.setQuietVolume();
          else
            sound.setMasterVolume(0.);  // Mute
        }
        return;
      }
  
      if (millis() > lastPowerCheck) {
        lastPowerCheck = millis()+POWER_CHECK_INTERVAL;
  
        // If we specifically requested slow, then go right ahead.
        if (powerSaver || sleepyMode) {
          prevPowerMode = powerMode;
          fpsTrackingMode = SLEEPY;
          setPowerMode(PowerMode.SLEEPY);
        }
      }
      //if (!isCharging() && !noBattery && sleepyMode) {
      //  prevPowerMode = powerMode;
      //  fpsTrackingMode = SLEEPY;
      //  setPowerMode(PowerMode.SLEEPY);
      //  return;
      //}
      
      if (powerSaver || sleepyMode) return;
        
      // If forced power mode is enabled, don't bother with the powermode selection algorithm below.
      if (forcePowerModeEnabled) {
        if (powerMode != forcedPowerMode) setPowerMode(forcedPowerMode);
        return;
      }

        // How the fps algorithm works:
        /*
        There are 4 modes:
         MONITOR:
         - Use average framerate to determine framepoints.
         - If the framerate is below the minimum required framerate, exponentially drain the score
         until the framerate is stable or the drop zone has been reached.
         - If in the unstable zone, linearly recover the score.
         - If in the stable zone, increase the score by the recovery likelyhood (((30-framepoints)/30)**2) 
         but only if we're lower than HIGH power mode. Otherwise max out at the stable threshold.
         - If we reach the drop threshold, drop the power mode down a level and take note of the recovery likelyhood (((30-framepoints)/30)**2)
         and reset the score to the stable threshold.
         - If we reach the recovery threshold, enter fps recovery mode and go up a power level.
         RECOVERY:
         - Don't keep track of score.
         - Use the real-time fps to take a small average of the current frame.
         - Once the average buffer is filled, use the average fps to determine whether we stay in this power mode or drop back.
         - Framerate at least 58, 28 etc, stay in this mode and go back into monitor mode, and reset the score to the stable threshold.
         - Otherwise, update recovery likelyhood and drop back.
         SLEEPY:
         - If sleepy mode is enabled, the score is paused and we don't do any operations;
         Wait until sleepy mode is disabled.
         GRACE:
         - A grace period where the score is not changed for a certain amount of time to allow the average framerate to fill up.
         - Once the grace period ends, return to MONITOR mode.
         */
    
        float stableFPS = 30.;
        int n = 1;
        switch (powerMode) {
        case HIGH:
          stableFPS = 57.;
          n = 1;
          break;
        case NORMAL:
          stableFPS = 27;
          n = 2;
          break;
        case SLEEPY:
          stableFPS = 13.;
          n = 4;
          break;
          // We shouldn't need to come to this but hey, this is a 
          // switch statement.
        case MINIMAL:
          stableFPS = 1.;
          break;
        }
    
        if (fpsTrackingMode == MONITOR) {
          // Everything in monitor will take twice or 4 times long if the framerate is lower.
          for (int i = 0; i < n; i++) {
            if (frameRate < stableFPS) {
              //console.log("Drain");
              scoreDrain += (stableFPS-frameRate)/stableFPS;
              fpsScore -= scoreDrain;
              //console.log(str(scoreDrain*scoreDrain));
              //console.log(str(fpsScore));
            } else {
              scoreDrain = 0.;
              // If in stable zone...
              if (fpsScore > FPS_SCORE_MIDDLE) {
                //console.log("stable zone");
    
                if (powerMode != PowerMode.HIGH)
                  fpsScore += recoveryScore;
    
                //console.log(str(recoveryScore));
              }
              // If in unstable zone...
              else {
                fpsScore += UNSTABLE_CONSTANT;
              }
            }
    
            if (fpsScore < FPS_SCORE_DROP) {
              // The lower our framerate, the less likely (or rather longer it takes) to get back to it.
              recoveryScore = PApplet.pow((frameRate/stableFPS), RECOVERY_NEGLIGENCE);
              // Reset the score.
              fpsScore = FPS_SCORE_MIDDLE;
              scoreDrain = 0.;
    
              // Set the power mode down a level.
              switch (powerMode) {
              case HIGH:
                setPowerMode(PowerMode.NORMAL);
                break;
              case NORMAL:
                //setPowerMode(PowerMode.SLEEPY);
                // Because sleepy is a pretty low framerate, chances are we just hit a slow
                // spot and will speed up soon. Let's give ourselves a bit more recoveryScore
                // so that we're not stuck slow forever.
                //recoveryScore += 1;
                fpsScore = FPS_SCORE_MIDDLE;
                break;
              case SLEEPY:
                // Raise this to true to enable any other bits of the code to perform performance-saving measures.
                break;
              case MINIMAL:
                // This is not a power level we downgrade to.
                // We shouldn't downgrade here, but if for whatever reason we're glitched out
                // and stuck in this mode, get ourselves out of it.
                setPowerMode(PowerMode.SLEEPY);
                fpsScore = FPS_SCORE_MIDDLE;
                break;
              }
            }
    
            if (fpsScore > FPS_SCORE_RECOVERY) {
              //console.log("RECOVERY");
              switch (powerMode) {
              case HIGH:
                // We shouldn't reach this here, but if we do, cap the
                // score.
                fpsScore = FPS_SCORE_RECOVERY;
                n = 1;
                break;
              case NORMAL:
                setPowerMode(PowerMode.HIGH);
                n = 1;
                break;
              case SLEEPY:
                setPowerMode(PowerMode.NORMAL);
                n = 2;
                break;
              case MINIMAL:
                // This is not a power level we upgrade to.
                // We shouldn't downgrade here, but if for whatever reason we're glitched out
                // and stuck in this mode, get ourselves out of it.
                setPowerMode(PowerMode.SLEEPY);
                break;
              }
              fpsScore = FPS_SCORE_MIDDLE;
              fpsTrackingMode = RECOVERY;
              recoveryFrameCount = 0;
              // Record the next so and so frames.
              framerateBuffer = new float[RECOVERY_PHASE_1_FRAMES/n];
              recoveryPhase = 1;
            }
          }
        } else if (fpsTrackingMode == RECOVERY) {
          // Record the fps, as long as we're not waiting to go back into MONITOR mode.
          if (recoveryPhase != 3)
            framerateBuffer[recoveryFrameCount++] = display.getLiveFPS();
    
          // Once we're done recording...
          int l = framerateBuffer.length;
          if (recoveryFrameCount >= l) {
    
            // Calculate the average framerate.
            float total = 0.;
            for (int j = 0; j < l; j++) {
              total += framerateBuffer[j];
            }
            float avg = total/float(l);
            //console.log("Recovery average: "+str(avg));
    
            // If the framerate is at least 90%..
            if (recoveryPhase == 1 && avg/stableFPS >= 0.9) {
              //console.log("Recovery phase 1");
              // Move on to phase 2 and get a little more data.
              recoveryPhase = 2;
              recoveryFrameCount = 0;
              framerateBuffer = new float[RECOVERY_PHASE_2_FRAMES/n];
            }
    
            // If the framerate is at least the minimum stable fps.
            else if (recoveryPhase == 2 && avg >= stableFPS) {
              //console.log("Recovery phase 2");
              // Now wait a bit before going back to monitor.
              graceTimer = 0;
              recoveryFrameCount = 0;
              fpsTrackingMode = GRACE;
            }
            // Otherwise drop back to the previous power mode.
            else {
              switch (powerMode) {
              case HIGH:
                setPowerMode(PowerMode.NORMAL);
                break;
              case NORMAL:
                // For the sake of this system what with the new delta framerate, we don't go any lower than NORMAL.
                //setPowerMode(PowerMode.SLEEPY);
                break;
              case SLEEPY:
                // Minimum power level, do nothing here.
                // Hopefully framerates don't get that low.
                break;
              case MINIMAL:
                // This is not a power level we downgrade to.
                // We shouldn't downgrade here, but if for whatever reason we're glitched out
                // and stuck in this mode, get ourselves out of it.
                setPowerMode(PowerMode.SLEEPY);
                fpsScore = FPS_SCORE_MIDDLE;
                break;
              }
              recoveryScore = PApplet.pow((avg/stableFPS), RECOVERY_NEGLIGENCE);
              fpsTrackingMode = MONITOR;
            }
          }
        } else if (fpsTrackingMode == SLEEPY) {
        } else if (fpsTrackingMode == GRACE) {
          graceTimer++;
          if (graceTimer > (240/n))
            fpsTrackingMode = MONITOR;
        }  
        
        //console.log(fpsScore);
        //console.log(getPowerModeString());
    }
    
    public boolean getSleepyMode() {
      return sleepyMode;
    }
    
    public void setSleepyMode(boolean b) {
      sleepyMode = b;
    }
    
    //public Kernel32.SYSTEM_POWER_STATUS powerStatus;
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  private HashSet<String> loadedContent;
  
  public class DisplayModule {
    // Display system
    private float displayScale = 2.0;
    public PImage errorImg;
    public PShader errShader;
    private HashMap<String, DImage> systemImages = new HashMap<String, DImage>();;
    public HashMap<String, PFont> fonts = new HashMap<String, PFont>();;
    private HashMap<String, PShaderEntry> shaders = new HashMap<String, PShaderEntry>();;
    public  float WIDTH = 0, HEIGHT = 0;
    private int loadingFramesLength = 0;
    private int lastFrameMillis = 0;
    private int thisFrameMillis = 0;
    private int totalTimeMillis = 0;
    private float time = 0.;
    private float selectBorderTime = 0.;
    public boolean showCPUBenchmarks = false;
    private PGraphics currentPG;
    private boolean allAtOnce = false;
    private LargeImage white;
    private IntBuffer clearList;
    private int clearListIndex = 0;
    public boolean showMemUsage = false;
    
    public final float BASE_FRAMERATE = 60.;
    public final int CLEARLIST_SIZE = 4096;
    private float delta = 0.;
    
    private boolean showFPS = false;
    
    public long rendererTime = 0;
    public long logicTime  = 0;
    public long idleTime  = 0;
    private long lastTime = 0;
    
    public int RENDER_TIME = 1;
    public int LOGIC_TIME  = 2;
    public int IDLE_TIME   = 3;
    
    public int timeMode = LOGIC_TIME;
    
    private PGL pgl;
    
    // This variable limits LargeImages uploading to the GPU to one LargeImage upload/frame.
    private boolean uploadGPUOnce = true;
    
    class PShaderEntry {
      public PShaderEntry(PShader s, String p) {
        shader = s;
        filepath = p;
      }
      public PShader shader;
      public String filepath = "";
      public boolean compiled = false;
      public boolean success = false;
    }
    
    public void recordRendererTime() {
      long time = System.nanoTime();
      if (timeMode == LOGIC_TIME) {
        logicTime += time-lastTime;
      }
      lastTime = time;
      timeMode = RENDER_TIME;
    }
    
    public void recordLogicTime() {
      long time = System.nanoTime();
      if (timeMode == RENDER_TIME) {
        rendererTime += time-lastTime;
      }
      lastTime = time;
      timeMode = LOGIC_TIME;
    }
    
    public int getRendererTime() {
      return (int)rendererTime;
    }
    
    public int getLogicTime() {
      return (int)logicTime;
    }
    
    public void resetTimes() {
      lastTime = System.nanoTime();
      rendererTime = 0;
      logicTime = 0;
    }
    
    
    public void showBenchmarks() {
      app.pushMatrix();
      app.scale(displayScale);
      
      app.noStroke();
      
      int totalTime = (totalTimeMillis*1000000);
      
      float wi = WIDTH*0.8;
      
      try {
        app.fill(127);
        app.rect(WIDTH*0.1, 10, wi, 50);
        
        float logic = wi*(((float)logicTime/(float)totalTime));
        app.fill(color(0,255,0));
        app.rect(WIDTH*0.1, 10, logic, 50);
        app.fill(255);
        app.textAlign(LEFT, CENTER);
        app.text("logic", WIDTH*0.1+10, 30);
        
        float opengl = wi*((float)rendererTime/(float)totalTime);
        app.fill(color(0,0,255));
        app.rect(WIDTH*0.1+logic, 10, opengl, 50);
        app.fill(255);
        app.textAlign(LEFT, CENTER);
        app.text("opengl", WIDTH*0.1+logic+10, 30);
      }
      catch (ArithmeticException e) {}
      app.popMatrix();
    }
    
    
    public DisplayModule() {
        // Set the display scale; since I've been programming this with my Surface Book 2 at high density resolution,
        // the original display area is 1500x1000, so we simply divide this device's display resolution by 1500 to
        // get the scale.
        displayScale = width/1500.;
        WIDTH = width/displayScale;
        HEIGHT = height/displayScale;
        console.info("init: width/height set to "+str(WIDTH)+", "+str(HEIGHT));
        
        clearList = IntBuffer.allocate(CLEARLIST_SIZE);
    
        generateErrorImg();
        generateErrorShader();
        currentPG = g;
        
        resetTimes();
    }
    
    public void setShowFPS(boolean b) {
      showFPS = b;
    }
    
    public boolean showFPS() {
      return showFPS;
    }
    
    private void generateErrorImg() {
      errorImg = createImage(32, 32, RGB);
      errorImg.loadPixels();
      for (int i = 0; i < errorImg.pixels.length; i++) {
        errorImg.pixels[i] = color(255, 0, 255);
      }
      errorImg.updatePixels();
    }
    
    private void generateErrorShader() {
      String[] vertSrc = {
      "uniform mat4 transformMatrix;",
      "attribute vec4 position;",
      "attribute vec4 color;",
      "varying vec4 vertColor;",
      "void main() {",
      "  gl_Position = transformMatrix * position;",
      "  vertColor = color;",
      "}"};
      
      String[] fragSrc = {
      "#ifdef GL_ES",
      "precision mediump float;",
      "#endif",
      "uniform vec4 color;",
      "uniform float intensity;",
      "void main() {",
      "gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);",
      "}"};
      
      errShader = new PShader(app, vertSrc, fragSrc);
    }
    
    public float getScale() {
      return displayScale;
    }
    
    // Since loading essential content only really takes place at the beginning,
    // we can free some memory by clearing the temp info in loadedcontent.
    // Just make sure not to load all content again!
    public void clearLoadingVars() {
      loadedContent.clear();
      systemImages.clear();
    }
    
    public void loadShader(String path) {
      if (!file.exists(path)) {
        console.bugWarn("loadShader: "+path+" doesn't exist.");
        return;
      }
      String name = file.getIsolatedFilename(path);
      String ext  = file.getExt(path);
      
      
      // If we're loading a vertex shader, we also have to load the corresponding 
      // fragment shader.
      if (ext.equals("vert")) {
        String fragPath = file.getDir(path)+"/"+name+".frag";
        if (file.exists(fragPath)) {
          PShader s = app.loadShader(fragPath, path);
          PShaderEntry shaderentry = new PShaderEntry(s, path);
          shaders.put(name, shaderentry);
          return;
        }
        else {
          // File not found, continue to the normal fragment-only code.
          console.warn("loadShader: corresponding "+name+" fragment shader file not found.");
        }
      }
      
      PShader s = app.loadShader(path);
      PShaderEntry shaderentry = new PShaderEntry(s, path);
      shaders.put(name, shaderentry);
    }
  
    public DImage getImg(String name) {
      if (systemImages.get(name) != null) {
        return systemImages.get(name);
      } else {
        console.warnOnce("Image "+name+" doesn't exist.");
        
        // TODO: Make it actually return something.
        return null;
      }
    }
  
    public void defaultShader() {
      app.resetShader();
    }
    
    public void shader(String shaderName, Object... uniforms) {
      initShader(shaderName);
      app.shader(
        getShaderWithParams(shaderName, uniforms)
      );
    }
    
    public void reloadShaders() {
      HashMap<String, PShaderEntry> sh = new HashMap<String, PShaderEntry>(shaders);
      
      for (PShaderEntry s : sh.values()) {
        this.loadShader(s.filepath);
      }
    }
    
    public void largeImg(LargeImage largeimg, float x, float y, float w, float h) {
      largeImg(g, largeimg, x, y, w, h);
    }
    
    public void bind(LargeImage img) {
      bind(g, img);
    }
    
    public void uploadAllAtOnce(boolean tf) {
      allAtOnce = tf;
    }
    
    public void bind(PGraphics currentPG, LargeImage img) {
      if (img == null) {
        return;
      }
      
      pgl = currentPG.beginPGL();
      // If image data is in GPU, we can just bind it and continue about our day.
      if (img.inGPU) {
        // Bind the texture
        pgl.activeTexture(PGL.TEXTURE0);
        pgl.bindTexture(PGL.TEXTURE_2D, img.glTexID);
      }
      // Otherwise, creation of the LargeImage hasn't put the GPU into GPU mem yet (because of multithreading issues)
      // so we must generate the buffers and put em on the GPU.
      else if (uploadGPUOnce || allAtOnce) {
        // Create the texture buffer and put data into gpu mem.
        IntBuffer intBuffer = IntBuffer.allocate(1);
        pgl.genTextures(1, intBuffer);
        img.glTexID = intBuffer.get(0);
        pgl.activeTexture(PGL.TEXTURE0);
        pgl.bindTexture(PGL.TEXTURE_2D, img.glTexID);
        pgl.texImage2D(PGL.TEXTURE_2D, 0, PGL.RGBA, (int)img.width, (int)img.height, 0, PGL.RGBA, PGL.UNSIGNED_BYTE, img.texData);
        img.inGPU = true;
        uploadGPUOnce = false;
        
        //pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MAG_FILTER, PGL.LINEAR);
        //pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MIN_FILTER, PGL.LINEAR_MIPMAP_LINEAR);
      }
      else {
        // uploadGPUOnce is false which means a LargeImage has taken our turn to upload our shiz into the GPU
        // and we must wait for a chance next frame.
        // For now, just render white
        if (white == null && systemImages.get("white") != null) {
          white = createLargeImage(systemImages.get("white").pimage);
        }
        
        if (white != null) {
          pgl.activeTexture(PGL.TEXTURE0);
          pgl.bindTexture(PGL.TEXTURE_2D, white.glTexID);
        }
      }
      
      pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MAG_FILTER, PGL.NEAREST);
      pgl.texParameteri(PGL.TEXTURE_2D, PGL.TEXTURE_MIN_FILTER, PGL.NEAREST);
      currentPG.endPGL();
    }
    
    public void largeImg(PGraphics currentPG, LargeImage img, float x, float y, float w, float h) {
      
      bind(currentPG, img);
      
      display.shader(currentPG, "largeimg");
      currentPG.beginShape(QUADS);
      currentPG.vertex(x, y, 0, 0);
      currentPG.vertex(x+w, y, 1, 0);
      currentPG.vertex(x+w, y+h, 1, 1);
      currentPG.vertex(x, y+h, 0, 1);
      currentPG.endShape();
      
      currentPG.flush();
      
      
      // TODO: Figure out a way to not have to switch shaders so much.
      currentPG.resetShader();
    }
    
    
    
    LargeImage createLargeImage(PImage img) {
        IntBuffer data = IntBuffer.allocate(img.width*img.height);
        
        // Copy pimage data to the intbuffer.
        data.rewind();
        int l = img.width*img.height;
        img.loadPixels();
        for (int i = 0; i < l; i++) {
          int c = img.pixels[i];
          int a = c >> 24 & 0xFF;
          int r = c >> 16 & 0xFF;
          int g = c >> 8 & 0xFF;
          int b = c & 0xFF;
          data.put(i, ( a << 24 |  b << 16 | g << 8 | r));
        }
        data.rewind();
        
        // At this rate the LargeImage class is more like a data container than an object that does stuff.  
        // You may notice we haven't done any OpenGL operations to upload the texture to the GPU.
        // That's becauses this method could very well be (and most definitely is) running in a seperate thread
        // to the OpenGL thread which is baaaaaad. So we will upload it to the GPU later in the main thread.
        // For now let's set up the LargeImage object, because that's something we're allowed to do in seperate threads
        // at least.
        LargeImage largeimg = new LargeImage(data);
        
        // Lets skip creating a shape for now cus who's gonna use it.
        //largeimg.shape = currentPG.createShape();
        
        //largeimg.shape.beginShape(QUADS);
        //largeimg.shape.noStroke();
        //largeimg.shape.fill(255);
        //largeimg.shape.vertex(0, 0, largeimg.uvx1, largeimg.uvy1);
        //largeimg.shape.vertex(1, 0, largeimg.uvx2, largeimg.uvx1);
        //largeimg.shape.vertex(1, 1, largeimg.uvx2, largeimg.uvy2);
        //largeimg.shape.vertex(0, 1, largeimg.uvx1, largeimg.uvy2);
        //largeimg.shape.endShape();
        
        largeimg.width = img.width;
        largeimg.height = img.height;
        return largeimg;
    }
    
    public void destroyImage(LargeImage im) {
      // We have a potential memory leak here :(
      if (clearListIndex+1 > CLEARLIST_SIZE-1) return;
      
      // Add it to the list so it will be cleared by the main thread.
      clearList.put(clearListIndex++, im.glTexID);
      clearList.rewind();
    }
    
    public void initShader(String name) {
      PShaderEntry sh = shaders.get(name);
      
      // Switch to the shader to force it to compile:
      if (!sh.compiled) {
        try {
          sh.shader.init();
          sh.success = true;
        }
        catch (RuntimeException e) {
          console.warn("Shader "+name+" failed to compile: ");
          String[] err = PApplet.split(e.getMessage(), "\n");
          for (String line : err) {
            console.log(line);
          }
          sh.success = false;
        }
        sh.compiled = true;
      }
      
    }
    
    public void shader(PGraphics framebuffer, String shaderName, Object... uniforms) {
      initShader(shaderName);
      framebuffer.shader(
        getShaderWithParams(shaderName, uniforms)
      );
    }
    
    public PShader getShaderWithParams(String shaderName, Object... uniforms) {
      PShader sh = shaders.get(shaderName).shader;
      if (sh == null) {
        console.warnOnce("Shader "+shaderName+" not found!");
        return errShader;
      }
      if (!shaders.get(shaderName).success) return errShader;
      int l = uniforms.length;
      
      for (int i = 0; i < l; i++) {
        Object o = uniforms[i];
        if (o instanceof String) {
          if (i+1 < l) {
            if (!(uniforms[i+1] instanceof Float)) {
              console.bugWarn("Invalid arguments ("+shaderName+"), uniform name needs to be followed by value.1");
              //println((uniforms[i+1]));
              return sh;
            }
          } else {
            console.bugWarn("Invalid arguments ("+shaderName+"), uniform name needs to be followed by value.2");
            return sh;
          }
  
          int numArgs = 0;
          float args[] = new float[4];   // There can only ever be at most 4 args.
          for (int j = i+1; j < l; j++) {
            if (uniforms[j] instanceof Float) args[numArgs++] = (float)uniforms[j];
            else if (uniforms[j] instanceof String) break;
            else {
              console.bugWarn("Invalid uniform argument for shader "+shaderName+".");
              return sh;
            }
            if (numArgs > 4) {
              console.bugWarn("There can only be at most 4 uniform args ("+shaderName+").");
              return sh;
            }
          }
  
          String uniformName = (String)uniforms[i];
          switch (numArgs) {
          case 1:
            sh.set(uniformName, args[0]);
            break;
          case 2:
            sh.set(uniformName, args[0], args[1]);
            break;
          case 3:
            sh.set(uniformName, args[0], args[1], args[2]);
            break;
          case 4:
            sh.set(uniformName, args[0], args[1], args[2], args[3]);
            break;
          default:
            console.bugWarn("Uh oh, that might be a bug (useShader).");
            return sh;
          }
          i += numArgs;
        } else {
          console.bugWarn("Invalid uniform argument for shader "+shaderName+".");
        }
      }
      return sh;
    }
    
    public void setPGraphics(PGraphics p) {
      currentPG = p;
    }
    
    public void img(DImage image, float x, float y, float w, float h) {
      
      
      if (image == null) {
        app.image(errorImg, x, y, w, h);
        recordLogicTime();
        console.warnOnce("Image listed as 'loaded' but image doesn't seem to exist.");
        return;
      }
      if (image.width == -1 || image.height == -1) {
        app.image(errorImg, x, y, w, h);
        recordLogicTime();
        console.warnOnce("Corrupted image.");
        return;
      }
      // If image is loaded render.
      if (image.width > 0 && image.height > 0) {
        if (image.mode == 1) {
          app.image(image.pimage, x, y, w, h);
        }
        else if (image.mode == 2) {
          largeImg(currentPG, image.largeImage, x, y, w, h);
        }
        
        // Annnnd a wireframe
        if (wireframe) {
          recordRendererTime();
          app.stroke(sin(selectBorderTime)*127+127, 100);
          selectBorderTime += 0.1*getDelta();
          app.strokeWeight(3);
          app.noFill();
          
          app.beginShape(QUADS);
          app.vertex(x, y);
          app.vertex(x+w, y);
          app.vertex(x+w, y+h);
          app.vertex(x, y+h);
          app.endShape();
          
          app.noStroke();
        } else {
          app.noStroke();
        }
        
        
        
        return;
      } else {
        app.noStroke();
        return;
      }
    }
  
    public void img(String name, float x, float y, float w, float h) {
      if (systemImages.get(name) != null) {
        img(systemImages.get(name), x, y, w, h);
      } else {
        recordRendererTime();
        app.image(errorImg, x, y, w, h);
        recordLogicTime();
        console.warnOnce("Image "+name+" does not exist");
      }
    }
  
    public void img(String name, float x, float y) {
      DImage image = systemImages.get(name);
      if (image != null) {
        img(systemImages.get(name), x, y, image.width, image.height);
      } else {
        recordRendererTime();
        app.image(errorImg, x, y, errorImg.width, errorImg.height);
        recordLogicTime();
        console.warnOnce("Image "+name+" does not exist");
      }
    }
  
  
    public void imgCentre(String name, float x, float y, float w, float h) {
      DImage image = systemImages.get(name);
      if (image == null) {
        //img(errorImg, x-errorImg.width/2, y-errorImg.height/2, w, h);
      } else {
        img(image, x-w/2, y-h/2, w, h);
      }
    }
  
    public void imgCentre(String name, float x, float y) {
      DImage image = systemImages.get(name);
      if (image == null) {
        //img(errorImg, x-errorImg.width/2, y-errorImg.height/2, errorImg.width, errorImg.height);
      } else {
        img(image, x-image.width/2, y-image.height/2, image.width, image.height);
      }
    }
    
    // TODO: Allow all os system fonts
    // PFont.list()
    public PFont getFont(String name) {
      PFont f = display.fonts.get(name);
      if (f == null) {
        console.warnOnce("Couldn't find font "+name+"!");
        // Idk just use this font as a placeholder instead.
        return createFont("Monospace", 128);
      } else return f;
    }
    
    public float getLiveFPS() {
      float timeframe = 1000/BASE_FRAMERATE;
      return (timeframe/float(thisFrameMillis-lastFrameMillis))*BASE_FRAMERATE;
    }
    
    public void displayMemUsageBar() {
      pushMatrix();
      scale(getScale());
      display.recordRendererTime();
      long used = (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
      //float percentage = (float)used/(float)MAX_MEM_USAGE;
      long total = Runtime.getRuntime().totalMemory();
      float percentage = (float)used/(float)total;
      noStroke();
      
      float y = 0;
      
      fill(0, 0, 0, 127);
      rect(100, y+20, (WIDTH-200.), 50);
      
      if (percentage > 0.8) 
        fill(255, 140, 20); // Low mem
      else 
        fill(50, 50, 255);  // Normal
        
        
      rect(100, y+20, (WIDTH-200.)*percentage, 50);
      fill(255);
      textFont(DEFAULT_FONT, 30);
      textAlign(LEFT, CENTER);
      text("Mem: "+(used/1024)+" kb / "+(total/1024)+" kb", 105, y+45);
      display.recordLogicTime();
      popMatrix();
    }
    
    public void displayScreens() {
      if (transitionScreens) {
        power.setAwake();
        transition = ui.smoothLikeButter(transition);
  
        // Sorry for the code duplication!
        switch (transitionDirection) {
        case RIGHT:
          app.pushMatrix();
          prevScreen.screenx = ((WIDTH*transition)-WIDTH)*displayScale;
          prevScreen.display();
          app.popMatrix();
  
  
          app.pushMatrix();
          currScreen.screenx = ((WIDTH*transition)*displayScale);
          currScreen.display();
          app.popMatrix();
          break;
        case LEFT:
          app.pushMatrix();
          prevScreen.screenx = ((WIDTH-(WIDTH*transition))*displayScale);
          prevScreen.display();
          app.popMatrix();
  
  
          app.pushMatrix();
          currScreen.screenx = ((-WIDTH*transition)*displayScale);
          currScreen.display();
          app.popMatrix();
          break;
        }
  
        if (transition < 0.001) {
          transitionScreens = false;
          currScreen.startupAnimation();
          prevScreen.endScreenAnimation();
  
          // If we're just getting started, we need to get a feel for the framerate since we don't want to start
          // slow and choppy. Once we're done transitioning to the first (well, after the startup) screen, go into
          // FPS recovery mode.
          if (initialScreen) {
            initialScreen = false;
            power.setPowerMode(PowerMode.NORMAL);
            power.forceFPSRecoveryMode();
          }
          //prevScreen = null;
        }
      } else {
        currScreen.display();
      }
      display.recordLogicTime();
    }
    
    public void clip(float x, float y, float wi, float hi) {
      float s = getScale();
      app.clip(x*s, y*s, wi*s, hi*s);
    }
    
    public void update() {
      // Reset so that a new texture can be uploaded to gpu
      uploadGPUOnce = true;
      
      if (clearListIndex > 0) {
        pgl = app.beginPGL();
        clearList.rewind();
        pgl.deleteTextures(clearListIndex, clearList);
        clearList.rewind();
        app.endPGL();
        clearListIndex = 0;
      }
      
      
      
      
      totalTimeMillis = thisFrameMillis-lastFrameMillis;
      lastFrameMillis = thisFrameMillis;
      thisFrameMillis = app.millis();
      // Limit delta to 7.5.
      // This means the entire application starts running slow below 8fps
      // lol
      // But sudden lag frames won't be a problem
      delta = min(BASE_FRAMERATE/display.getLiveFPS(), 7.5);
      
      // Also update the time while we're at it.
      time += delta;
    }
    
    public float getDelta() {
      return delta;
    }
    
    // Frames since the beginning of the program, accounting for missed frames (always 1 second = 60 frames, even if running at 30fps)
    public float getTime() {
      return time;
    }
    
    public float getTimeSeconds() {
      return time/display.BASE_FRAMERATE;
    }
    
  
  }

















  public class UIModule {
    
    public float guiFade = 0;
    public SpriteSystemPlaceholder currentSpritePlaceholderSystem;
    public boolean spriteSystemClickable = false;
    public MiniMenu currMinimenu = null;
    
    
    
    
    
    
    
    
    public class MiniMenu {
        public SpriteSystemPlaceholder g;
        public float x = 0., y = 0.;
        public float width = 0., height = 0.;
        public float yappear = 1.;
        public boolean disappear = false;

        final public float APPEAR_SPEED = 0.1;
        final public color BACKGROUND_COLOR = color(0, 0, 0, 150);
        
        public MiniMenu() {
            power.setAwake();
            yappear = 1.;
            sound.playSound("fade_in");
        }
        
        public MiniMenu(float x, float y) {
          this();
          this.x = x;
          this.y = y;
        }
        
        public MiniMenu(float x, float y, float w, float h) {
          this(x, y);
          this.width = w;
          this.height = h;
        }

        public void close() {
            // Only bother closing if we're not in any current animation
            if (!disappear && yappear <= 0.01) {
                disappear = true;
                power.setSleepy();
                yappear = 1.;
                sound.playSound("fade_out");
            }
        }

        public void display() {
            app.noTint();
            // Sorry I'm lazy
            
            yappear *= PApplet.pow(1.-APPEAR_SPEED, display.getDelta());
            
            app.noStroke();
            app.fill(BACKGROUND_COLOR);

            // Cool menu appaer animation. Or disappear animation.
            if (!disappear) {
                float h = this.height-(this.height*yappear);
                app.rect(x, y, this.width, h);
                display.clip(x, y, this.width, h);
            }
            else {
                app.rect(x, y, this.width, this.height*yappear);
                display.clip(x, y, this.width, this.height*yappear);
                if (yappear <= 0.01) {
                    power.setSleepy();
                    currMinimenu = null;
                }
            }
            
            

            // If we click away from the minimenu, close the minimenu
            if ((mouseX() > x && mouseX() < x+this.width && mouseY() > y && mouseY() < y+this.height) == false) {

                if (input.primaryClick) {
                    close();
                }
            }
            //app.noClip();
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    public class OptionsMenu extends MiniMenu {
      private ArrayList<String> options = new ArrayList<String>();
      private ArrayList<Runnable> actions = new ArrayList<Runnable>();
      private String selectedOption = null;
      private static final float SIZE = 30.;
      private static final float SPACING = 10.;
      private static final float OFFSET_SPACING_X = 50.;
      private static final color HOVER_COLOR = 0xFFC200FF;
      
      // Keep track if the menu has been selected, and if it has, set this to
      // false so that our selected action is only performed once (might loop
      // during the closing animation of the MiniMenu)
      private boolean selectable = true;
      
      // Deprecated.
      //public OptionsMenu(String... opts) {
      //  super(mouseX(), mouseY());
        
      //  float maxWidth = 0.;
      //  float hi = 0.;        
      //  app.textFont(DEFAULT_FONT, SIZE);
      //  for (String op : opts) {
      //    options.add(op);
      //    float wi = app.textWidth(op);
      //    if (wi > maxWidth) maxWidth = wi;
      //    hi += SIZE+SPACING;
      //  }
        
      //  this.width = maxWidth+SPACING*2.+OFFSET_SPACING_X;
      //  this.height = hi+SPACING;
      //}
      
      public OptionsMenu(String[] opts, Runnable[] acts) {
        super(mouseX(), mouseY());
        
        float maxWidth = 0.;
        float hi = 0.;        
        app.textFont(DEFAULT_FONT, SIZE);
        
        if (opts.length != acts.length) {
          console.bugWarn("OptionsMenu: options and actions not equal length.");
        }
        else {
          for (int i = 0; i < opts.length; i++) {
            options.add(opts[i]);
            actions.add(acts[i]);
            float wi = app.textWidth(opts[i]);
            if (wi > maxWidth) maxWidth = wi;
            hi += SIZE+SPACING;
          }
        }
        
        
        this.width = maxWidth+SPACING*2.+OFFSET_SPACING_X;
        this.height = hi+SPACING;
      }
      
      public OptionsMenu(ArrayList<String> opts, ArrayList<Runnable> acts) {
        super(mouseX(), mouseY());
        
        float maxWidth = 0.;
        float hi = 0.;        
        app.textFont(DEFAULT_FONT, SIZE);
        
        options = opts;
        actions = acts;
        
        for (int i = 0; i < opts.size(); i++) {
          float wi = app.textWidth(opts.get(i));
          if (wi > maxWidth) maxWidth = wi;
          hi += SIZE+SPACING;
        }
        
        this.width = maxWidth+SPACING*2.+OFFSET_SPACING_X;
        this.height = hi+SPACING;
      }
      
      
      public void display() {
        super.display();
        if (selectedOption != null) 
          selectable = false;
        
        app.textFont(DEFAULT_FONT, SIZE);
        app.textAlign(LEFT, TOP);
        
        float yy = this.y+SPACING;
        for (int i = 0; i < options.size(); i++) {
          String op = options.get(i);
          float xx = this.x+OFFSET_SPACING_X+SPACING;
          if (mouseX() > this.x && mouseX() < this.x+this.width && mouseY() > yy && mouseY() < yy+SIZE+SPACING) {
            app.fill(HOVER_COLOR);
            if (input.primaryClick && selectable) {
              sound.playSound("select_any");
              actions.get(i).run();
              selectedOption = op;
              this.close();
            }
          }
          else app.fill(255);
          app.text(op, xx, yy);
          yy += SIZE+SPACING;
        }
      }
      
      public boolean optionSelected() {
        if (!selectable) return false;
        return (selectedOption != null);
      }
    }
    
    public void createOptionsMenu(String[] opts, Runnable[] acts) {
      currMinimenu = new OptionsMenu(opts, acts);
    }
    
    
    
    
    
    
    
    
    
    
    // BIG TODO: Obviously we want to pimp up this menu and add more colors.
    // This is probably one of the oldest yet most used code in Timeway that hasn't been updated in FOREVER.
    public class ColorPicker extends MiniMenu {
        public boolean selected = false;
        public color selectedColor;
        public Runnable runWhenPicked = null;
      
        public color[] colorArray = {
            //ffffff
            color(255, 255, 255),
            //909090
            color(144, 144, 144),
            //4d4d4d
            color(77, 77, 77),
            //000000
            color(0, 0, 0),
            //ffde96
            color(255, 222, 150),
            //ffc64b
            color(255, 198, 75),
            //ffae00
            color(255, 174, 0),
            //ffb4f6
            color(255, 180, 246),
            //ff89b9
            color(255, 137, 185),
            //ff5d5f
            color(255, 93, 95),
            //cab9ff
            color(202, 185, 255),
            //727aff
            color(114, 122, 255),
            //38a7ff
            color(56, 167, 255),
            
            color(189, 226, 149)
        };

        public int maxCols = 6;


        public ColorPicker(float x, float y, float width, float height, Runnable r) {
            super(x, y, width, height);
            runWhenPicked = r;
        }

        public void display() {
            // Super display to display the background
            super.display();
            //app.tint(255, 255.*yappear);


            // display all the colors in the colorArray, in a grid, with a new row every MAX_COLS

            float spacing = 20;
            float selSize = 5;

            // The width of each color box
            float boxWidth = (this.width/maxCols);
            // The height of each color box
            // The height of the box is the aspect ratio of the minimenu
            float boxHeight = boxWidth*(this.height/this.width);
            // Loop through each colour
            for (int i = 0; i < colorArray.length; i++) {
                // The x position of the color box
                // Give it a bit of space between each box
                float boxX = this.x+(i%maxCols)*boxWidth;
                // The y position of the color box
                float boxY = this.y+(spacing/2)+(i/maxCols)*boxHeight;
                // The color of the color box
                color boxColor = colorArray[i];

                boolean wasHovered = false;
                // If the mouse is hovering over the color box, tint it
                if (mouseX() > boxX-selSize && mouseX() < boxX+boxWidth+selSize && mouseY() > boxY-selSize && mouseY() < boxY+boxHeight+selSize) {
                    boxX -= selSize;
                    boxY -= selSize;
                    boxWidth += selSize*2;
                    boxHeight += selSize*2;
                    wasHovered = true;

                    // If clicked 
                    if (input.primaryClick && !disappear) {
                        selectedColor = colorArray[i];
                        
                        if (runWhenPicked != null) {
                          sound.playSound("select_color");
                          runWhenPicked.run();
                        }
                        
                        close();
                    }
                }

                // Display the color box
                app.fill(boxColor);
                app.rect((spacing/2)+boxX, boxY, boxWidth-spacing, boxHeight-(spacing/2));

                if (wasHovered) {
                    // Shrink the width n height back to what it was before
                    boxX += selSize;
                    boxY += selSize;
                    boxWidth -= selSize*2;
                    boxHeight -= selSize*2;
                }
            }

            //Remember to call noTint
            app.noTint();
        }
    }
    
    
    public void colorPicker(float x, float y, Runnable runWhenPicked) {
      currMinimenu = new ColorPicker(x, y, 300, 200, runWhenPicked);
    }
    
    public color getPickedColor() {
      if (!(currMinimenu instanceof ColorPicker)) {
        console.bugWarn("getPickedColor: currMinimenu is not a ColorPicker!");
        return 0;
      }
      return ((ColorPicker)currMinimenu).selectedColor;
    }
    
    
    public void displayMiniMenu() {
      // Display the minimenu in front of all the buttons.
      if (miniMenuShown()) {
          app.pushMatrix();
          app.scale(display.getScale());
          currMinimenu.display();
          app.noClip();
          app.popMatrix();
      }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    public UIModule() {
      
    }

  
    public void useSpriteSystem(SpriteSystemPlaceholder system) {
      this.currentSpritePlaceholderSystem = system;
      this.spriteSystemClickable = true;
      this.guiFade = 255.;
    }
  
    public boolean button(String name, String texture, String displayText) {
  
      if (this.currentSpritePlaceholderSystem == null) {
        console.bugWarn("You forgot to call useSpriteSystem()!");
        return false;
      }
  
      // This doesn't change at all.
      // I just wanna keep it in case it comes in useful later on.
      boolean guiClickable = true;
  
      // Don't want our messy code to spam the console lol.
      currentSpritePlaceholderSystem.suppressSpriteWarning = true;
  
      boolean hover = false;
  
      // Full brightness when not hovering
      app.tint(255, guiFade);
      app.fill(255, guiFade);
  
      // To click:
      // - Must not be in a minimenu
      // - Must not be in gui move sprite / edit mode.
      // - also the guiClickable thing.
      if (currentSpritePlaceholderSystem.buttonHover(name) && guiClickable && !currentSpritePlaceholderSystem.interactable && spriteSystemClickable) {
        // Slight gray to indicate hover
        app.tint(230, guiFade);
        app.fill(230, guiFade);
        hover = true;
      }
  
      // Display the button, will be affected by the hover color.
      currentSpritePlaceholderSystem.button(name, texture, displayText);
      app.noTint();
  
      // Don't have "the boy who called wolf", situation, turn back on warnings
      // for genuine troubleshooting.
      currentSpritePlaceholderSystem.suppressSpriteWarning = false;
  
      // Only when the button is actually clicked.
      return hover && input.primaryClick;
    }
    
    public void loadingIcon(float x, float y, float widthheight) {
      display.imgCentre("load-"+appendZeros(counter(max(display.loadingFramesLength, 1), 3), 4), x, y, widthheight, widthheight);
    }
  
    public void loadingIcon(float x, float y) {
      loadingIcon(x, y, 128);
    }
    
  
    public float smoothLikeButter(float i) {
  
      // I wanna emulate some of the cruddy performance from the old fps system
      // so we limit the display delta especially when we get sudden fps dips.
      // Max it at 4 because that was the minimum framerate we could do in SLEEPY mode,
      // 15fps!
      float d = min(display.getDelta(), 4.);
      i *= pow(0.9, d);
      
      
      // LMAO REALLY FUNNY GLITCH, COMMENT THE LINE ABOVE AND UNCOMMENT THIS ONE BELOW!!
      // Update: the glitch no longer works it just displays a black screen (how sad)
      //i *= 0.9*display.getDelta();
  
      if (i < 0.05) {
        return i-0.001;
      }
      return i;
    }
    
    public boolean miniMenuShown() {
      return (currMinimenu != null);
    }
  }



  


















  public class AudioModule {
    private Music streamMusic;
    private Music streamMusicFadeTo;
    
    private float musicFadeOut = 1.;
    public final float MUSIC_FADE_SPEED = 0.95;
    public final float PLAY_DELAY = 0.3;
    public HashMap<String, SoundFile> sounds;
    private AtomicBoolean musicReady = new AtomicBoolean(true);
    private boolean startupGStreamer = true;
    private boolean reloadMusic = false;
    private String reloadMusicPath = "";
    public       float  VOLUME_NORMAL = 1.;
    public       float  VOLUME_QUIET = 0.;
    public boolean CACHE_MISS_NO_MUSIC = false;
    public boolean WAIT_FOR_GSTREAMER_START = true;
    private HashMap<String, SoundFile> cachedMusicMap;   // Used as an alternative if gstreamer is still starting up.
    
    public final String MUSIC_CACHE_FILE = "music_cache.json";
    public final int MAX_MUSIC_CACHE_SIZE_KB = 1024*256;  // 256 MB
    public final String[] FORCE_CACHE_MUSIC = {
      "data/engine/music/pixelrealm_default_bgm.wav",
      "data/engine/music/pixelrealm_default_bgm_legacy.wav"
    };
    
    
    // So that we can use both SoundFile and Movie types without complicated code
    class Music {
      final int NONE = 0;
      final int CACHED = 1;
      final int STREAM = 2;
      int mode = 0;
      boolean cacheMiss = false;
      private Movie streamMusic;
      private SoundFile cachedMusic;
      String originalPath = "";
      float volume = 0.;
      
      // Load cached music
      public Music(String path) {
        originalPath = path;
        // If music is still loading, try and get cached entry
        if (loadingMusic()) {
          //console.log("Cache music mode");
          mode = CACHED;
          SoundFile m = cachedMusicMap.get(path);
          if (m != null) {
            //console.log("Cache hit "+path);
            cachedMusic = m;
            cachedMusic.amp(1.0);
          }
          // If cache miss, this just means we can't play any music until gstreamer has loaded.
          else {
            // 3 cases here:
            // - Don't play any music while gstreamer is still starting up
            // - Load music if gstreamer is starting up (slow, only if file is small enough)
            // - Play loading music if gstreamer is still starting up and file in question is too long.
            if (CACHE_MISS_NO_MUSIC) {
              mode = NONE;
            }
            else {
              // Perform size approximation.
              // FLAC files not in this list due to them not being supported by soundfile
              // therefore loading music will play in place.
              final String ext = file.getExt(path);
              boolean playDefaultLoadingMusic = true;
              
              final int COMPRESSED_MAX_SIZE = 1048576; // 1mb
              final int UNCOMPRESSED_MAX_SIZE = 15728640; // 10mb
              
              // Compressed file formats can take long to decompress,
              // so we'll only allow a minute or two at most.
              if (ext.equals("mp3") || ext.equals("ogg")) {
                File f = new File(path);
                // Fits compressed size
                //console.log("Is compressed file "+f.length());
                playDefaultLoadingMusic = (f.length() > COMPRESSED_MAX_SIZE);
              }
              
              // Uncompressed files are much faster to load.
              // Therefore we can have a much higher threashold for wav files
              else if (ext.equals("wav")) {
                File f = new File(path);
                playDefaultLoadingMusic = (f.length() > UNCOMPRESSED_MAX_SIZE);
              }
              
              // Determinining default music done
              // Load default music if it's available.
              if (playDefaultLoadingMusic) {
                //console.log("Playing default loading music");
                if (sounds.containsKey("loadingmusic")) {
                  cachedMusic = sounds.get("loadingmusic");
                  mode = CACHED;
                }
                else mode = NONE;
              }
              // Load and play the music.
              else {
                //console.log("Trying to directly load music ohno");
                cachedMusic = new SoundFile(app, path, false);  // Yes, on the main thread.
                mode = CACHED;
              }
            }
            // Later we can use it in the thing etc
          }
        }
        // Otherwise use gstreamer
        else {
          //console.log("Stream music mode");
          mode = STREAM;
          streamMusic = new Movie(app, path);
        }
      }
      
      public void play() {
        if (mode == CACHED) {
          if (!cachedMusic.isPlaying()) cachedMusic.play(); 
        } 
        else if (mode == STREAM) streamMusic.play();
      }
      
      public void stop() {
        if (mode == CACHED) cachedMusic.stop(); else if (mode == STREAM) streamMusic.stop();
      }
      
      public boolean available() {
        if (mode == CACHED)
          return true;
        else if (mode == STREAM) return streamMusic.available();
        return true;
      }
      
      public void read() {
        if (mode == STREAM) streamMusic.read();
      }
      
      public void volume(float vol) {
        volume = vol;
        if (mode == STREAM) streamMusic.volume(vol);
      }
      
      public float duration() {
        if (mode == CACHED) return cachedMusic.duration(); else if (mode == STREAM) return streamMusic.duration();
        return 0.;
      }
      
      public float time() {
        if (mode == CACHED) return cachedMusic.position(); else if (mode == STREAM) return streamMusic.time();
        return 0.;
      }
      
      public void jump(float pos) {
        if (mode == CACHED) cachedMusic.jump(pos); else if (mode == STREAM) streamMusic.jump(pos);
      }
      
      public boolean isPlaying() {
        if (mode == CACHED) return cachedMusic.isPlaying(); else if (mode == STREAM) return streamMusic.isPlaying();
        return true;
      }
      
      public void setReady() {
        if (mode == STREAM) streamMusic.playbin.setState(org.freedesktop.gstreamer.State.READY); 
      }
      
      public void playbinSetVolume(float vol) {
        volume = vol;
        if (mode == CACHED) {
          cachedMusic.amp(vol);
        }
        else if (mode == STREAM) {
          streamMusic.playbin.setVolume(vol*masterVolume);
          streamMusic.playbin.getState();
        }
      }
      
      // When gstreamer finally loads, switches seamlessly to gstreamer version.
      public void switchMode() {
        if (!loadingMusic() && mode != STREAM) {
          
          streamMusic = new Movie(app, originalPath);
          
          // Transfer cachedMusic properties over to streammusic
          if (streamMusic != null) {
            streamMusic.volume(this.volume);
            
            // If cachedmusic exists then cachedmusic.isplaying = streammusic.isplaying
            // Otherwise mode must be NONE so we just kickstart the streamMusic.
            if (cachedMusic != null) {
              if (cachedMusic.isPlaying())
                streamMusic.play();
              streamMusic.jump(cachedMusic.position());
            }
            else streamMusic.play();
            
            if (mode == CACHED) cachedMusic.stop();
          }
          
          mode = STREAM;
        }
      }
    }
    
    public AudioModule() {
      sounds = new HashMap<String, SoundFile>();
      cachedMusicMap = new HashMap<String, SoundFile>();
      VOLUME_NORMAL = settings.getFloat("volumeNormal");
      VOLUME_QUIET = settings.getFloat("volumeQuiet");
      CACHE_MISS_NO_MUSIC = settings.getBoolean("cache_miss_no_music");
      WAIT_FOR_GSTREAMER_START = settings.getBoolean("waitForGStreamerStartup");
      setMasterVolume(VOLUME_NORMAL);
      startupGStreamer = true;
    }
    
    public boolean cacheHit(String path) {
      return cachedMusicMap.containsKey(path);
    }
    
    public void setNormalVolume() {
      setMasterVolume(VOLUME_NORMAL);
    }
    
    public void setQuietVolume() {
      setMasterVolume(VOLUME_QUIET);
    }
    
    // Not including the size because we don't wanna overengineer it.
    class CachedEntry {
      public CachedEntry(String cpa, String opa, int pri, int s) {
        cachedpath = cpa;
        originalpath = opa;
        priority = pri;
        sizekb = s;
      }
      public int sizekb = 0;
      public String cachedpath = "";
      public String originalpath = "";
      public int priority = 0;
    }
    
    public void saveAsWav(SoundFile s, int sampleRate, String path) {
      AudioSample a = (AudioSample)s;
      
      // Only allow a maximum of a minute of audio data to be loaded
      int size = min(a.frames()*a.channels(), 60*a.channels()*sampleRate);
      float[] data = new float[size];
      a.read(data);
      
      int bitDepth = 16;
      int numChannels = a.channels();

      AudioFormat audioFormat = new AudioFormat(sampleRate, bitDepth, numChannels, true, false);
      byte[] audioData = floatArrayToByteArray(data, bitDepth);
      
      try {
          ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(audioData);
          AudioInputStream audioInputStream = new AudioInputStream(byteArrayInputStream, audioFormat, data.length / numChannels);
          AudioSystem.write(audioInputStream, AudioFileFormat.Type.WAVE, new File(path));
      } catch (IOException e) {
          e.printStackTrace();
      }
      
      updateMusicCache(path);
      
      // TODO: User may close application midway while creating wav which might end up
      // in Timeway not loading.
    }

    private byte[] floatArrayToByteArray(float[] floatArray, int bitDepth) {
        ByteBuffer byteBuffer = ByteBuffer.allocate(floatArray.length * (bitDepth / 8));
        ByteOrder order = ByteOrder.LITTLE_ENDIAN;
        
        byteBuffer.order(order);

        if (bitDepth == 16) {
            ShortBuffer shortBuffer = byteBuffer.asShortBuffer();
            short[] shortArray = new short[floatArray.length];
            float MAX = float(Short.MAX_VALUE);
            for (int i = 0; i < floatArray.length; i++) {
                shortArray[i] = (short) (floatArray[i] * MAX);
            }
            shortBuffer.put(shortArray);
        } else if (bitDepth == 32) {
            FloatBuffer floatBuffer = byteBuffer.asFloatBuffer();
            floatBuffer.put(floatArray);
        } else {
            throw new IllegalArgumentException("Unsupported bit depth: " + bitDepth);
        }


        return byteBuffer.array();
    }
    
    // This increases ever-so steadily.
    private float cacheTime = 0.;
    private final float MAX_CACHE_TIME = 60.*60.;
    private AtomicBoolean caching = new AtomicBoolean(false);
    
    private void updateMusicCache(final String path) {
      // FLAC is not supported by soundfile so don't bother caching that.
      if (file.getExt(path).equals("flac")) {
        return;
      }
      
      if (CACHE_MUSIC && cacheTime < MAX_CACHE_TIME) {
        
        boolean cacheLoaded = true;
        String cacheFilePath = APPPATH+CACHE_PATH+MUSIC_CACHE_FILE;
        JSONArray jsonarray = null;
        File f = new File(cacheFilePath);
        if (f.exists()) {
          try {
            jsonarray = app.loadJSONArray(cacheFilePath);
            if (jsonarray == null) {
              console.info("updateMusicCache: couldn't load music cache.");
              cacheLoaded = false;
            }
          }
          catch (RuntimeException e) {
            console.info("updateMusicCache: something's wrong with the music cache json.");
            cacheLoaded = false;
          }
        }
        else cacheLoaded = false;
        
        if (!cacheLoaded || jsonarray == null) {
          jsonarray = new JSONArray();
        }
        
        
        // If cache hasn't been found then the entry in the cache will automatically not be found lol.
        JSONObject obj;
        int score = int(MAX_CACHE_TIME-cacheTime);
        
        // Save these for later, we'll need the below down there in the code.
        String tempCacheFilePath = null;
        boolean createNewEntry = true;
        
        for (int i = 0; i < jsonarray.size(); i++) {
          obj = jsonarray.getJSONObject(i);
          if (obj.getString("originalPath", "").equals(path)) {
            // Add to the priority, but we don't want it to overflow, so max out if it reaches max integer value.
            int priority = (int)min(obj.getInt("priority", 0)+score, Integer.MAX_VALUE-MAX_CACHE_TIME*2);
            obj.setInt("priority", priority);
            
            // In case we need to re-create the cached file later.
            tempCacheFilePath = obj.getString("cachePath", "");
            
            //console.log("Priority: "+str(priority)+" "+str(score));
            // Write to the file
            try {
              saveJSONArray(jsonarray, cacheFilePath);
            }
            catch (RuntimeException e) {
              console.warn(e.getMessage());
              console.warn("Failed to write music cache file:");
            }
            
            // We've of course found an existing entry so no need to create a new one.
            // Tell that to the code below.
            createNewEntry = false;
          }
        }
        
        
        
        // Save the actual wav file as cache
        String cachedFileName = "";
        final String ext = file.getExt(path);
        // Sometimes the entry can exist but not the cached file.
        // We can easily just re-create the entry if it's missing.
        
        // If it's a wav, there's no need to do converstions into the cache.
        // Just tell it that the original path is the cached path.
        if (ext.equals("wav")) {
          cachedFileName = path;
        }
        // Otherwise, begin to load the compressed file, decompress it, and save as wav in cache folder.
        else {
          // 2 cases here:
          // - We're playing music that has never been cached before
          // - The music has a cache entry but the cache WAV file doesn't exist for some resason
          String temp = "";
          // Entry already exists but wav file doesn't
          if (!createNewEntry) {
            if (tempCacheFilePath != null && tempCacheFilePath.length() > 0) {
              temp = tempCacheFilePath;
              // Only bother creating the new file if it doesn't exist
              if ((new File(tempCacheFilePath)).exists()) return;  // Nothing more to do here.
            }
            else console.bugWarn("updateMusicCache: tempCacheFilePath read a non-existing json string or is null");
          }
          // Entry doesn't exist i.e. no cache whatsoever.
          else {
            temp = generateCachePath("wav");
          }
          final String cachedFileNameFinal = temp;
          cachedFileName = cachedFileNameFinal;
          
          // Kickstart the thread that will cache the file.
          Thread t1 = new Thread(new Runnable() {
            public void run() {
              // As soon as we're not caching anymore, take the opportunity and set to true.
              // Otherwise, wait wait wait
              while (!caching.compareAndSet(false, true)) {
                try {
                  Thread.sleep(10);
                }
                catch (InterruptedException e) {
                  // we don't care.
                }
              }
              
              try {
                println("Caching "+path+"...");
                SoundFile s = new SoundFile(app, path);
                int samplerate = s.sampleRate();
                // Bug fix: mp3 sampleRate() doesn't seem to be very accurate
                // for mp3 files
                // TODO: Read mp3/ogg header data and determine samplerate there.
                if (ext.equals("mp3")) {
                  samplerate = 48000;
                }
                saveAsWav(s, samplerate, cachedFileNameFinal);
                println("DONE SOUND CACHE "+path);
                
              }
              catch (RuntimeException e) {
                console.warn("Sound caching error.");
              }
              // Release so that another thread can begin its caching process.
              caching.set(false);
            }
          }
          );
          t1.start();
        }
        
        // Nothing more to do.
        if (!createNewEntry) return;
        
        // If we get to this point, entry doesn't exist in the cache file/cache file doesn't exist.
        obj = new JSONObject();
        obj.setString("cachePath", cachedFileName);
        obj.setString("originalPath", path);
        obj.setInt("priority", score);
        
        // Because we're still loading up the sound file in the background, best we can do here is
        // make an estimate on how large the file will be.
        // Here's the rules:
        // wav: filesize*2
        // mp3: filesize*20
        // ogg: filesize*20
        // flac: filesize*(10/7)
        // anything else: filesize*2
        int size = 0;
        int filesize = (int)(new File(path)).length();
        if (file.getExt(path).equals("wav")) size = filesize*2;
        else if (file.getExt(path).equals("mp3")) size = filesize*20;
        else if (file.getExt(path).equals("ogg")) size = filesize*20;
        else if (file.getExt(path).equals("flac")) size = filesize*(10/7);
        else size = filesize*2;
        obj.setInt("sizekb", size/1024);
        jsonarray.append(obj);
        try {
          saveJSONArray(jsonarray, cacheFilePath);
        }
        catch (RuntimeException e) {
          console.warn(e.getMessage());
          console.warn("Failed to write music cache file:");
        }
      }
    }
    
    // IMPORTANT NOTE: this does NOT run the loader code in a seperate thread. Make sure
    // to run this in a seperate thread otherwise you're going to experience stalling BIIIIIG time.
    public void loadMusicCache() {
      if (CACHE_MUSIC) {
        String cacheFilePath = APPPATH+CACHE_PATH+MUSIC_CACHE_FILE;
        File f = new File(cacheFilePath);
        if (f.exists()) {
          JSONArray jsonarray;
          try {
            jsonarray = app.loadJSONArray(cacheFilePath);
            if (jsonarray == null) {
              console.info("loadMusicCache: couldn't load music cache.");
              return;
            }
          }
          catch (RuntimeException e) {
            console.info("loadMusicCache: something's wrong with the music cache json.");
            return;
          }
          
          
          // Two parts below: 
          // 1. Decide which cached files will be loaded,
          // 2. Load the actual cache into ram
          
          // NOTE: this isn't perfect because the cache might not exist,
          // so full resources might not be used,
          // but honestly why bother with a rare edge case.
          // Not on my todo list anytime soon.
          
          int totalSizeKB = 0;
          
          ArrayList<CachedEntry> loadMusic = new ArrayList<CachedEntry>();
          
          // At this point all checks should have passed.
          // Load all music from the array
          int l = jsonarray.size();
          for (int i = 0; i < l; i++) {
            JSONObject obj = jsonarray.getJSONObject(i);
            if (obj != null) {
              // The path here is the path of the original file,
              // NOT the cached file. (remember we're passing it
              // thru tryGetSoundCache())
              String cachedpath = obj.getString("cachePath", "");
              String originalPath = obj.getString("originalPath", "");
              int sizekb = obj.getInt("sizekb", Integer.MAX_VALUE);
              
              // Priority is based on the time from the start of the application (when gstreamer starts initialising)
              // so that we know how important it is to load the file.
              // For example, if our music in our home directory realm is going to have a pretty big priority.
              // Meanwhile, some folder we rarely visit is going to have a miniscule priority.
              int priority = obj.getInt("priority", 0);
              
              // Validity check (mostly to check cache isn't corrupted):
              // - Actually has a path
              // - Total size isn't missing
              // - Priority isn't missing.
              if (cachedpath.length() > 0 && sizekb < MAX_MUSIC_CACHE_SIZE_KB && priority > 0) {
                f = new File(cachedpath);
                // Check: file exists
                if (f.exists()) {
                  // Check: size fits. If it doesn't, see if there's any possibility of
                  // evicting cached music with less priority.
                  if (totalSizeKB+sizekb < MAX_MUSIC_CACHE_SIZE_KB) {
                    console.info("loadMusicCache: Easy cache add.");
                    loadMusic.add(new CachedEntry(cachedpath, originalPath, priority, sizekb));
                    totalSizeKB += sizekb;
                  }
                  // Not enough space, see if there's others with less priority that we can evict.
                  else {
                    console.info("loadMusicCache: Not enough cache space, seeing if there's someone we can kick out.");
                    // Loop through the list, check if there's someone with lower priority we can kick out.
                    // Yes, technically squared big-o, but we're dealing with what? less than 10 cached entries at most?
                    // No biggie.
                    int ll = loadMusic.size();
                    for (int ii = 0 ; ii < ll; ii++) {
                      CachedEntry c = loadMusic.get(ii);
                      
                      // Our priority is higher and it fits if we evict the old one.
                      if (c.priority < priority && totalSizeKB-c.sizekb+sizekb < MAX_MUSIC_CACHE_SIZE_KB) {
                        // Replace old one with our entry.
                        console.info("loadMusicCache: Evicted lower priority cache for higher priority one.");
                        loadMusic.set(ii, new CachedEntry(cachedpath, originalPath, priority, sizekb));
                        totalSizeKB += sizekb;
                        // And of course break out so that we don't replace all the entries.
                        break;
                      }
                    }
                    // If we break out here then we couldn't find a spot, so sad :(
                    // Oh well huehue
                    
                    console.info("loadMusicCache: I couldn't find a space for me, aww :(");
                  }
                }
              }
            }
          }
          // End loop 1
          // Move on to actually loading the files lol.
          
          // Step 2 load the music.
          for (CachedEntry c : loadMusic) {
            // If this passes then we can load this file
            
            SoundFile music = new SoundFile(app, c.cachedpath, false); //tryLoadSoundCache(c.path, null);
            // If cache exists of the music.
            cachedMusicMap.put(c.originalpath, music);
            //console.log(c.originalpath);
          }
          
          
          // We're not done yet!
          // Step 3 load force-cached music
          for (String filename : FORCE_CACHE_MUSIC) {
            if (!(new File(filename).isAbsolute())) {
              filename = (APPPATH+filename).replaceAll("//", "/");
            }
            
            if (!file.exists(filename)) {
              console.bugWarn("loadMusicCache: constant FORCE_CACHE_MUSIC filename entry "+filename+" does not exist!");
            }
            
            SoundFile music = new SoundFile(app, filename, false);
            cachedMusicMap.put(filename, music);
          }
              
          
        }
        // If there's no cache file then don't bother lol.
      }
      else console.info("loadMusicCache: CACHE_MUSIC disabled, no loading cached music");
    }
    
    // Ugly code but secure
    public boolean loadingMusic() {
      boolean ready = musicReady.get();
      //if (gstreamerLoading && ready) gstreamerLoading = false;
      return !ready;
    }
    
    public SoundFile getSound(String name) {
      SoundFile sound = sounds.get(name);
      if (sound == null) {
        console.bugWarn("getsound: Sound "+name+" doesn't exist!");
        return null;
      } else return sound;
    }
  
    public void playSound(String name) {
      playSound(name, 1.0);
    }
    
    public void playSoundOnce(String name) {
      SoundFile s = getSound(name);
      if (s != null) {
        if (!s.isPlaying()) s.play();
      }
    }
    
    public void pauseSound(String name) {
      SoundFile s = getSound(name);
      if (s != null) {
        if (s.isPlaying()) s.pause();
      }
    }
    
    public void playSound(String name, float pitch) {
      SoundFile s = getSound(name);
      if (s != null) {
        if (s.isPlaying()) s.stop();
        s.play(pitch);
      }
    }
  
    public void loopSound(String name) {
      // Don't want loads of annoying loops
      SoundFile s = getSound(name);
      if (s != null) {
        if (!s.isPlaying())
          s.loop();
      }
    }
    
  
    public void setSoundVolume(String name, float vol) {
      SoundFile s = getSound(name);
      if (s != null) s.amp(vol);
    }
    
    private float masterVolume = 1.;
    public void setMasterVolume(float vol) {
      masterVolume = vol;
      Sound.volume(vol);
    }
  
  
    // Plays background music directly from the hard drive without loading it into memory, and
    // loops the music when the end of the audio has been reached.
    // This is useful for playing background music, but shouldn't be used for sound effects
    // or randomly accessed sounds.
    // This technically uses an unintended quirk of the Movie library, as passing an audio file
    // instead of a video file still plays the file streamed from the disk.
  
    public void streamMusic(final String path) {
      // If still loading
      if (loadingMusic()) {
        reloadMusic = true;
        reloadMusicPath = path;
      }
      
      
      
  
      if (startupGStreamer) {
        //console.log("startup gstreamer");
        // Start music and don't play anything (just want it to get past the inital delay of starting gstreamer.
        musicReady.set(false);
        Thread t1 = new Thread(new Runnable() {
          public void run() {
            Movie loadGstreamer = new Movie(app, path);
            loadGstreamer.play();
            loadGstreamer.stop();
    
            musicReady.set(true);
          }
        }
        );
        t1.start();
        startupGStreamer = false;
      }
      // Play as normal
      else {
        //console.log("streammusic "+path);
        //if ((loadingMusic() && !CACHE_MUSIC) == false) {
          Thread t1 = new Thread(new Runnable() {
          public void run() {
            streamMusic = loadNewMusic(path);
    
            if (streamMusic != null)
              streamMusic.play();
            }
          }
          );
          t1.start();
        //}
      }
    }
  
    private Music loadNewMusic(String path) {
      
      // Doesn't seem to throw an exception or report an error is the file isn't
      // found so let's do it ourselves.
      if (!file.exists(path)) {
        console.bugWarn("loadNewMusic: "+path+" doesn't exist!");
        return null;
      }
      
      Music newMusic = null;
  
      console.info("loadNewMusic: Starting "+path);
      try {
        // Automatically loads cached music if gstreamer has not started yet.
        newMusic = new Music(path);
      }
      catch (Exception e) {
        console.warn("Error while reading music: "+e.getClass().toString()+", "+e.getMessage());
      }
  
      if (newMusic == null) console.bugWarn("Couldn't read music; null returned");
      
      updateMusicCache(path);
  
      //  We're creating a new sound streamer, not a movie lmao.
      return newMusic;
    }
  
    public void stopMusic() {
      if (streamMusic != null) {
        streamMusic.stop();
        streamMusic = null;
      }
      if (streamMusicFadeTo != null) {
        streamMusicFadeTo.stop();
        streamMusicFadeTo = null;
      }
    }
  
    public void streamMusicWithFade(String path) {
      if (musicReady.get() == false) {
        reloadMusic = true;
        reloadMusicPath = path;
        updateMusicCache(path);
      }
  
      // Temporary fix
      if (musicFadeOut < 1.) {
        if (streamMusicFadeTo != null) {
          streamMusicFadeTo.stop();
        }
      }
  
      // If no music is currently playing, don't bother fading out the music, just
      // start the music as normal.
      if (streamMusic == null || isLoading()) {
        streamMusic(path);
        return;
      }
      
      streamMusicFadeTo = loadNewMusic(path);
      if (streamMusicFadeTo != null) {
        streamMusicFadeTo.volume(0.);
        streamMusicFadeTo.setReady();
      }
      musicFadeOut = 0.99;
    }
    
    // TODO: Doesn't work totally.
    public void fadeAndStopMusic() {
      if (musicFadeOut < 1.) {
        if (streamMusicFadeTo != null) {
          streamMusicFadeTo.stop();
          streamMusicFadeTo = null;
        }
        return;
      }
      musicFadeOut = 0.99;
    }
    
  
    public void processSound() {
      // Once gstreamer has loaded up, begin playing the music we actually want to play.
      if (reloadMusic && !loadingMusic()) {
        if (CACHE_MUSIC) {
          if (streamMusic != null) streamMusic.switchMode();
          if (streamMusicFadeTo != null) streamMusicFadeTo.switchMode();
          // We no longer need the cached music map. Just to be safe, don't null it
          // in case of nullpointerexception, but create a new one to clear the cache
          // stored in it
          cachedMusicMap = new HashMap<String, SoundFile>();
        }
        else {
          stopMusic();
          streamMusic(reloadMusicPath);
        }
        
        reloadMusic = false;
      }
      

      // Fade the music.
      boolean useNewLibraryVersion = false; // javaPlatform >= 17;
      
      if (musicFadeOut < 1.) {
        if (musicFadeOut > 0.005 && !useNewLibraryVersion) {
          // Fade the old music out
          float vol = musicFadeOut *= PApplet.pow(MUSIC_FADE_SPEED, display.getDelta());
          if (streamMusic != null)
            streamMusic.playbinSetVolume(vol);


          // Fade the new music in.
          if (streamMusicFadeTo != null) {
            streamMusicFadeTo.play();
            streamMusicFadeTo.volume((1.-vol)*masterVolume);
          } 
          
          
          //else 
          //  console.bugWarnOnce("streamMusicFadeTo shouldn't be null here.");
        } else {
          if (streamMusic != null)
            streamMusic.stop();
          if (streamMusicFadeTo != null) streamMusic = streamMusicFadeTo;
          if (useNewLibraryVersion) streamMusic.play();
          musicFadeOut = 1.;
        }
      }



      if (streamMusic != null) {
        // Don't wanna change the volume on cached music
        if (!loadingMusic())
          streamMusic.volume(masterVolume);
          
        if (streamMusic.available() == true) {
          streamMusic.read();
        }
        float error = 0.1;

        // PERFORMANCE ISSUE: streamMusic.time()
        
        // If the music has finished playing, jump to beginning to play again.
        if (streamMusic.time() >= streamMusic.duration()-error) {
          streamMusic.jump(0.);
          if (!streamMusic.isPlaying()) {
            streamMusic.play();
          }
        }
      }
      
      
      if (cacheTime <= MAX_CACHE_TIME) {
        
        if (display != null) {
          cacheTime += display.getDelta();
        }
      }
    }
    
    // End of the module
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class FilemanagerModule {
    Engine engine;
    
    public FilemanagerModule(Engine e) {
      engine = e;
      
      DEFAULT_DIR  = settings.getString("homeDirectory");
      {
        File f = new File(DEFAULT_DIR);
        if (!f.exists()) {
          console.warn("homeDirectory "+DEFAULT_DIR+" doesn't exist! You should check your config file.");
          DEFAULT_DIR = System.getProperty("user.home").replace('\\', '/');
        }
        currentDir  = DEFAULT_DIR;
      }
      
      if (DEFAULT_DIR.length() > 0)
        if (DEFAULT_DIR.charAt(DEFAULT_DIR.length()-1) == '/')  DEFAULT_DIR = DEFAULT_DIR.substring(0, DEFAULT_DIR.length()-1);
    }
    
    
    public boolean loading = false;
    public int MAX_DISPLAY_FILES = 2048; 
    public int numTimewayEntries = 0;
    public DisplayableFile[] currentFiles;
    public String fileSelected = null;
    public boolean fileSelectSuccess = false;
    public boolean selectingFile = false;
    public Object objectToSave;
    public 
    
    
    void selectOutput(String promptMessage) {
      if (true) {
        fileSelectSuccess = false;
        app.selectOutput(promptMessage, "outputFileSelected");
        selectingFile = true;
      }
      // TODO: Pixelrealm file chooser.
    }
    
    void selectOutput(String promptMessage, PImage imageToSave) {
      this.selectOutput(promptMessage);
      objectToSave = imageToSave;
    }
    
    void outputFileSelected(File selection) {
      selectingFile = false;
      if (selection == null) {
        fileSelected = null;
        fileSelectSuccess = false;
      }
      else {
        fileSelected = selection.getAbsolutePath();
        fileSelectSuccess = true;
      }
      
      if (objectToSave != null && fileSelectSuccess) {
        if (objectToSave instanceof PImage) {
          Thread t = new Thread(new Runnable() {
              public void run() {
                  PImage imageToSave = (PImage)objectToSave;
                  imageToSave.save(fileSelected);
                  objectToSave = null;
              }
          });
          t.start();
        }
        else {
          console.bugWarn("outputFileSelected: I don't know how to save "+objectToSave.getClass().toString()+"!");
        }
      }
    }
    
    public boolean mv(String oldPlace, String newPlace) {
      try {
        File of = new File(oldPlace);
        File nf = new File(newPlace);
        if (nf.exists()) {
           return false;
        }
        if (of.exists()) {
          of.renameTo(nf);
          // If the file is cached, move the cached file too to avoid stalling and creating duplicate cache
          moveCache(oldPlace, newPlace);
        } else if (!of.exists()) {
          return false;
        }
      }
      catch (SecurityException e) {
        console.warn(e.getMessage());
        return false;
      }
      return true;
    }
    
    public boolean copy(String src, String destination) {
      if (!exists(src)) {
        console.bugWarn("copy: "+src+" doesn't exist!");
        return false;
      }
      
      
      try {
        Path copied = Paths.get(destination);
        Path originalPath = (new File(src)).toPath();
        Files.copy(originalPath, copied, StandardCopyOption.REPLACE_EXISTING);
      }
      catch (IOException e) {
        console.warn(e.getMessage());
        return false;
      }
      return true;
    }
  
    public void backupMove(String path) {
      String name = getFilename(path);
      String newPath = APPPATH+CACHE_PATH+"_"+name+"_"+getLastModified(path).replaceAll("[\\.:]", "-")+".txt";
      if (!mv(path, newPath)) {
        console.log(newPath);
        // If a file doesn't back up, it's not the end of the world.
        console.warn("Couldn't back up "+path+".");
      }
    }
  
    public void backupAndSaveJSON(JSONObject json, String path) {
      File f = new File(path);
      if (f.exists())
        backupMove(path);
          
      app.saveJSONObject(json, path);
    }
    
    
  
    // TODO: change this so that you can modify the default dir.
    // TODO: Make it follow the UNIX file system with compatibility with windows.
    public String currentDir;
    public class DisplayableFile {
      public String path;
      public String filename;
      public String fileext;
      public String icon = null;
      // TODO: add other properties.
      
      
      public boolean exists() {
        return (new File(path)).exists();
      }
      
      public boolean isDirectory() {
        if (!exists()) {
          console.bugWarn("isDirectory: "+path+" doesn't exist!");
          return false;
        }
        return (new File(path)).isDirectory();
      }
    }
  
    // Returns the extention WITHOUT the "." dot
    public String getExt(String fileName) {
      int dotIndex = fileName.lastIndexOf(".");
      // If it's a dir, return a dot "."
      if (dotIndex == -1) {
        // Return a dot to resemble that this is a directory.
        // We choose a dot because no extention can possibly be a ".".
        return ".";
      }
      return fileName.substring(dotIndex+1, fileName.length());
    }
  
    public String getDir(String path) {
      try {
        String str = path.substring(0, path.lastIndexOf('/', path.length()-2));
        return str;
      }
      catch (StringIndexOutOfBoundsException e) {
        return path;
      }
    }
    
    public boolean isDirectory(String path) {
      return (new File(path)).isDirectory();
    }
    
    // TODO: optimise to be safe and for use with MacOS and Linux.
    public String getPrevDir(String dir) {
      int i = dir.lastIndexOf("/", dir.length()-2);
      if (i == -1) {
        console.bugWarn("getPrevDir: At root dir, make sure to use atRootDir in your code!");
        return dir;
      }
      return dir.substring(0, i);
    }
    
    public String directorify(String dir) {
      if (dir.charAt(dir.length()-1) != '/')  dir += "/";
      return dir;
    }
    
    public String getMyDir() {
      String dir = getDir(APPPATH);
      return directorify(dir);
    }
    
    public String anyFileWithExt(String pathWithoutExt, String[] exts) {
      for (String ext : exts) {
        // Because we like to keep our code secure, let's do a bit of error checking (what opengl suffers from lol)
        if (ext.charAt(0) != '.') ext = "."+ext;
        
        File f = new File(pathWithoutExt+ext);
        if (f.exists()) {
          return pathWithoutExt+ext;
        }
      }
      return null;
    }
    
    // Yes.
    public boolean exists(String path) {
      File f = new File(path);
      return f.exists();
    }
    
    public boolean isImage(String path) {
      String ext = getExt(path);
      if (ext.equals("png")
        || ext.equals("jpg")
        || ext.equals("jpeg")
        || ext.equals("bmp")
        || ext.equals("gif")
        || ext.equals("ico")
        || ext.equals("webm")
        || ext.equals("tiff")
        || ext.equals("tif"))
        return true;
      else
        return false;
    }
    
    public String anyImageFile(String pathWithoutExt) {
      String[] SUPPORTED_IMG_TYPES = { ".png", ".bmp", ".jpg", ".jpeg", ".gif" };
      return anyFileWithExt(pathWithoutExt, SUPPORTED_IMG_TYPES);
    }
    
    public String anyMusicFile(String pathWithoutExt) {
      String[] SUPPORTED_MUSIC_TYPES = { ".wav", ".mp3", ".flac", ".ogg" };
      return anyFileWithExt(pathWithoutExt, SUPPORTED_MUSIC_TYPES);
    }
  
    public String getFilename(String path) {
      int index = path.lastIndexOf('/', path.length()-2);
      if (index != -1) {
        if (path.charAt(path.length()-1) == '/') {
          path = path.substring(0, path.length()-1);
        }
        return path.substring(index+1);
      } else
        return path;
    }
    
    // Returns filename without the extension.
    public String getIsolatedFilename(String path) {
      int index = path.lastIndexOf('/', path.length()-2);
      String filenameWithExt = "";
      if (index != -1) {
        if (path.charAt(path.length()-1) == '/') {
          path = path.substring(0, path.length()-1);
        }
        filenameWithExt = path.substring(index+1);
      } else
        filenameWithExt = path;
      
      // Now strip off the ext.
      index = filenameWithExt.indexOf('.');
      String result = filenameWithExt.substring(0, index);
      //console.log(result);
      return result;
    }
  
    public boolean atRootDir(String dirName) {
      // This will heavily depend on what os we're on.
      if (platform == WINDOWS) {
  
        // for windows, let's do a dirty way of checking for 3 characters
        // such as C:/
        return (dirName.length() <= 3);
      }
  
      // Shouldn't be reached
      return false;
    }
  
  
  
    public String typeToIco(FileType type) {
      switch (type) {
      case FILE_TYPE_UNKNOWN:
        return "unknown_128";
      case FILE_TYPE_IMAGE:
        return "image_128";
      case FILE_TYPE_VIDEO:
        return "media_128";
      case FILE_TYPE_MUSIC:
        return "media_128";
      case FILE_TYPE_MODEL:
        return "unknown_128";
      case FILE_TYPE_DOC:
        return "doc_128";
      case FILE_TYPE_TIMEWAYENTRY:
        return "timeway_entry_64";
      default:
        return "unknown_128";
      }
    }
  
    public String extIcon(String ext) {
      return typeToIco(extToType(ext));
    }
  
    public FileType extToType(String ext) {
      if (ext.equals("png")
        || ext.equals("jpg")
        || ext.equals("jpeg")
        || ext.equals("bmp")
        || ext.equals("gif")
        || ext.equals("ico")
        || ext.equals("webm")
        || ext.equals("tiff")
        || ext.equals("tif")) return FileType.FILE_TYPE_IMAGE;
  
      if (ext.equals("doc")
        || ext.equals("docx")
        || ext.equals("txt")
        || ext.equals("pdf")) return FileType.FILE_TYPE_DOC;
        
      if (ext.equals(ENTRY_EXTENSION))
        return FileType.FILE_TYPE_TIMEWAYENTRY;
  
      if (ext.equals("mp3")
        || ext.equals("wav")
        || ext.equals("flac")
        || ext.equals("ogg"))  return FileType.FILE_TYPE_MUSIC;
  
      if (ext.equals("mp4")
        || ext.equals("m4v")
        || ext.equals("mov")) return FileType.FILE_TYPE_VIDEO;
        
      if (ext.equals("obj")) return FileType.FILE_TYPE_MODEL;
      
      // For backwards compat, we may have different portal shortcut extensions.
      for (String s : SHORTCUT_EXTENSION) {
        if (ext.equals(s)) return FileType.FILE_TYPE_SHORTCUT;
      }
  
      return FileType.FILE_TYPE_UNKNOWN;
    }
  
    // A function of conditions for a file to be hidden,
    // for now files are only hidden if they have '.' at the front.
    private boolean fileHidden(String filename) {
      if (filename.length() > 0) {
        if      (filename.charAt(0) == '.') return true;
        else if (filename.equals("desktop.ini")) return true;
      }
      return false;
    }
  
    // Opens the dir and populates the currentFiles list.
    public void openDir(String dirName) {
      loading = true;
      dirName = dirName.replace('\\', '/');
      numTimewayEntries = 0;
      File dir = new File(dirName);
      if (!dir.isDirectory()) {
        console.warn(dirName+" is not a directory!");
        return;
      }
  
      // Start at one because the first element is the back element
      int index = 1;
  
      // Make the dir have one extra slot for back.2
      // TODO: add runtime loading of files and remove the MAX_DISPLAY_FILES limit.
      try {
        int l = dir.listFiles().length + 1;
        if (l > MAX_DISPLAY_FILES) l = MAX_DISPLAY_FILES+1;
        if (atRootDir(dirName)) {
          // if we're at the root dir, then nevermind about that one extra slot;
          // there's no need to go back when we're already at the root dir.
          l = dir.listFiles().length;
          if (l > MAX_DISPLAY_FILES) l = MAX_DISPLAY_FILES;
          index = 0;
        }
  
        currentFiles = new DisplayableFile[l];
  
        // Add the back option to the list
        if (!atRootDir(dirName)) {
          // Assuming we're not at the root dir (therefore possible to go back),
          // add the back option to our dir
          currentFiles[0] = new DisplayableFile();
          currentFiles[0].path = getDir(dirName);
          currentFiles[0].filename = "[Prev dir]";
          currentFiles[0].fileext = "..";            // It should be impossible for any files to have this file extention.
        }
  
        final int MAX_NAME_SIZE = 40;
  
        for (File f : dir.listFiles()) {
          if (index < l) {
            // Cheap fix, sorryyyyyy
            try {
              if (!fileHidden(f.getName())) {
                currentFiles[index] = new DisplayableFile();
                currentFiles[index].path = f.getAbsolutePath();
                currentFiles[index].filename = f.getName();
                if (currentFiles[index].filename.length() > MAX_NAME_SIZE) currentFiles[index].filename = currentFiles[index].filename.substring(0, MAX_NAME_SIZE)+"...";
                currentFiles[index].fileext = getExt(f.getName());
  
                // Get icon
                if (f.isDirectory()) currentFiles[index].icon = "folder_128";
                else currentFiles[index].icon = extIcon(currentFiles[index].fileext);
  
                // Just a piece of code plonked in for the entries part
                if (currentFiles[index].fileext.equals(ENTRY_EXTENSION)) numTimewayEntries++;
                index++;
              }
            }
            catch (NullPointerException e1) {
            }
            catch (ArrayIndexOutOfBoundsException e2) {
            }
          }
        }
        currentDir = dirName;
        if (currentDir.charAt(currentDir.length()-1) != '/')  currentDir += "/";
        loading = false;
      }
      catch (NullPointerException e) {
        console.warn("Null dir, perhaps refused permissions?");
      }
    }
  
    //public boolean isLoading() {
    //  return loading;
    //}
  
    public void openDirInNewThread(final String dirName) {
      loading = true;
      Thread t = new Thread(new Runnable() {
        public void run() {
          openDir(dirName);
        }
      }
      );
      t.start();
    }
    
    public int countFiles(String path) {
        File folder = new File(path);
        if (!folder.exists() || !folder.isDirectory())
            return 1;
            
        int count = 0;
        File[] files = folder.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isFile()) {
                    count++;
                } else if (file.isDirectory()) {
                    count += countFiles(file.getAbsolutePath()); // Recursively count files in subfolders
                }
            }
        }
        return count;
    }
  
    // NOTE: Only opens files, NOT directories (yet).
    public void open(String filePath) {
      String ext = getExt(filePath);
      // Stuff to open with our own app (timeway)
      if (ext.equals(ENTRY_EXTENSION)) {
        currScreen.requestScreen(new Editor(engine, filePath));
      }
  
      // Anything else which is opened by a windows app or something.
      // TODO: use xdg-open in linux.
      // TODO: figure out how to open apps with MacOS.
      else {
        if (Desktop.isDesktopSupported()) {
          // Open desktop app with this snippet of code that I stole.
          try {
            Desktop desktop = Desktop.getDesktop();
            File myFile = new File(filePath);
            try {
              desktop.open(myFile);
            }
            catch (IllegalArgumentException fileNotFound) {
              console.log("This file or dir no longer exists!");
              refreshDir();
            }
          } 
          catch (IOException ex) {
            console.warn("Couldn't open file IOException");
          }
        } else {
          console.warn("Couldn't open file, isDesktopSupported=false.");
        }
      }
    }
  
    public void open(DisplayableFile file) {
      String path = file.path;
      if (file.isDirectory()) {
        openDirInNewThread(path);
      } else {
        // Stuff to open with our own app (timeway)
        if (file.fileext.equals(ENTRY_EXTENSION)) {
          currScreen.requestScreen(new Editor(engine, path));
        }
  
        // Anything else which is opened by a windows app or something.
        // TODO: use xdg-open in linux.
        // TODO: figure out how to open apps with MacOS.
        else {
          if (Desktop.isDesktopSupported()) {
            // Open desktop app with this snippet of code that I stole.
            try {
              Desktop desktop = Desktop.getDesktop();
              File myFile = new File(path);
              try {
                desktop.open(myFile);
              }
              catch (IllegalArgumentException fileNotFound) {
                console.log("This file or dir no longer exists!");
                refreshDir();
              }
            } 
            catch (IOException ex) {
            }
          } else {
            console.warn("Couldn't open file, isDesktopSupported=false.");
          }
        }
      }
    }
  
    public void refreshDir() {
      openDirInNewThread(currentDir);
    }
    
        // NOTE: VERY INACCURATE
    private int countApproxGifFrames(FileInputStream inputStream) throws IOException {
            int count = 0;
    
            // Read GIF header
            byte[] header = new byte[6];
            inputStream.read(header);
            
            int i_1 = 0;
    
            while (true) {
                // Read the block type
                int blockType = inputStream.read();
    
                if (blockType == 0x3B) {
                    // Reached the end of the GIF file
                    break;
                } else if (blockType == 0x21) {
                    // Extension block
                    int extensionType = inputStream.read();
                    if (extensionType == 0xF9) {
                        count++;
                    } else {
                        // Skip other extension blocks
                        while (true) {
                            int blockSize = inputStream.read();
                            if (blockSize == 0) {
                                break; // Block terminator found
                            }
                            inputStream.skip(blockSize); // Skip this block
                        }
                    }
                } else {
                    // Image Data block
                    int i_2 = 0;
                    while (true) {
                        int blockSize = inputStream.read();
                        if (blockSize == 0) {
                            break; // Block terminator found
                        }
                        inputStream.skip(blockSize); // Skip image data sub-blocks
                        
                        i_2++;
                        if (i_2 > 5000) {
                          break;
                        }
                    }
                    //count++;
                }
                
                
                i_1++;
                if (i_1 > 5900) {
                  break;
                }
            }
    
            return count*2;
        }
        
    
    private int[] extractGifDimensions(FileInputStream inputStream) throws IOException {
            int[] dimensions = new int[2];
    
            // Read GIF header and Logical Screen Descriptor
            byte[] headerAndLSD = new byte[13];
            inputStream.read(headerAndLSD);
    
            // Extract width and height from the Logical Screen Descriptor
            dimensions[0] = (headerAndLSD[6] & 0xFF) | ((headerAndLSD[7] & 0xFF) << 8);
            dimensions[1] = (headerAndLSD[8] & 0xFF) | ((headerAndLSD[9] & 0xFF) << 8);
    
            return dimensions;
        }
    
    // WARNING: may provide VERY inaccurate results. This is largely an approximation.
    // It should mainly be used to check if it's possible to fit it in memory, because it will
    // most likely over-estimate.
    // Please note that it may also take a while to get the size depending on the file size.
    // Therefore, you should run this in a seperate thread.
    public int getGifUncompressedSize(String filePath) {
      FileInputStream inputStream;
      try {
          inputStream = new FileInputStream(filePath);
          int numFrames = countApproxGifFrames(inputStream);
          
          inputStream.close();
          inputStream = new FileInputStream(filePath);
          int[] widthheight = extractGifDimensions(inputStream);
          int wi = widthheight[0];
          int hi = widthheight[1];
          return wi*hi*4*numFrames;
      }
      catch (IOException e) {
          return Integer.MAX_VALUE;
      }
      catch (RuntimeException e) {
        return Integer.MAX_VALUE;
      }
    }
    
    public int[] getPNGImageDimensions(String filePath) throws IOException {
        File file = new File(filePath);
        byte[] data = new byte[24]; // PNG header size is 24 bytes
        FileInputStream stream;
        try {
            stream = new FileInputStream(file);
            stream.read(data);
            stream.close();
        }
        catch (IOException e) {
          // idk
          int[] someValue = {0, 0};
          return someValue;
        }

        // Check if the file is a PNG image
        if (isPNG(data)) {
            int width = getIntFromBytes(data, 16);
            int height = getIntFromBytes(data, 20);
            int[] dimensions = { width, height };
            return dimensions;
        } else {
            throw new IOException("Not a valid PNG image");
        }
    }

    private boolean isPNG(byte[] data) {
        // Check PNG signature (first 8 bytes)
        return data.length >= 8 &&
                data[0] == (byte) 0x89 &&
                data[1] == (byte) 0x50 &&
                data[2] == (byte) 0x4E &&
                data[3] == (byte) 0x47 &&
                data[4] == (byte) 0x0D &&
                data[5] == (byte) 0x0A &&
                data[6] == (byte) 0x1A &&
                data[7] == (byte) 0x0A;
    }

    private int getIntFromBytes(byte[] data, int offset) {
        return ((data[offset] & 0xFF) << 24) |
               ((data[offset + 1] & 0xFF) << 16) |
               ((data[offset + 2] & 0xFF) << 8) |
               (data[offset + 3] & 0xFF);
    }

    
    public int getPNGUncompressedSize(String path) {
      try {
        int[] widthheight = getPNGImageDimensions(path);
        int wi = widthheight[0];
        int hi = widthheight[1];
        return wi*hi*4;
      }
      catch (IOException e) {
        return Integer.MAX_VALUE;
      }
    }
    
    private int readUnsignedShort(InputStream inputStream) throws IOException {
        int byte1 = inputStream.read();
        int byte2 = inputStream.read();

        if ((byte1 | byte2) < 0) {
            throw new IOException("End of stream reached");
        }

        return (byte1 << 8) + byte2;
    }



    private int[] getJPEGImageDimensions(String filePath) throws IOException {
        File file = new File(filePath);
        FileInputStream stream;
            stream = new FileInputStream(file);
            byte[] data = new byte[2];
            stream.read(data);
            if (isJPEG(data)) {
                // Skip to the SOF0 marker (0xFFC0)
                while (true) {
                    int marker = readUnsignedShort(stream);
                    int length = readUnsignedShort(stream);
                    if (marker >= 0xFFC0 && marker <= 0xFFCF && marker != 0xFFC4 && marker != 0xFFC8) {
                        // Found SOF marker, read dimensions
                        stream.skip(1); // Skip precision byte
                        int hi = readUnsignedShort(stream);
                        int wi = readUnsignedShort(stream);
                        int[] dimensions = {wi, hi};
                        stream.close();
                        return dimensions;
                    } else {
                        // Skip marker segment
                        stream.skip(length - 2);
                    }
                }
            } else {
              stream.close();
                throw new IOException("Not a valid JPEG image");
            }
    }

    private boolean isJPEG(byte[] data) {
        return data.length >= 2 &&
                data[0] == (byte) 0xFF &&
                data[1] == (byte) 0xD8;
    }

    public int getJPEGUncompressedSize(String path) {
      try {
        int[] widthheight = getJPEGImageDimensions(path);
        int wi = widthheight[0];
        int hi = widthheight[1];
        return wi*hi*4;
      }
      catch (IOException e) {
        return Integer.MAX_VALUE;
      }
    }
    
    private int[] getBmpDimensions(String filePath) throws IOException {
        int[] dimensions = new int[2];
        FileInputStream fileInputStream;
        try {
            fileInputStream = new FileInputStream(filePath);
            // BMP header contains width and height information at specific offsets
            fileInputStream.skip(18); // Skip to width bytes
            dimensions[0] = readLittleEndianInt(fileInputStream); // Read width (little-endian)
            dimensions[1] = readLittleEndianInt(fileInputStream); // Read height (little-endian)
            return dimensions;
        }
        catch (IOException e) {
          // idk
          int[] someValue = {0, 0};
          return someValue;
        }
    }

    private int readLittleEndianInt(FileInputStream inputStream) throws IOException {
        byte[] buffer = new byte[4];
        inputStream.read(buffer);
        // Convert little-endian bytes to an integer
        return (buffer[3] & 0xFF) << 24 | (buffer[2] & 0xFF) << 16 | (buffer[1] & 0xFF) << 8 | (buffer[0] & 0xFF);
    }
    
    public int getBMPUncompressedSize(String path) {
      try {
          int[] dimensions = getBmpDimensions(path);
          int wi = dimensions[0];
          int hi = dimensions[1];
          return wi*hi*4;
      } catch (IOException e) {
          return Integer.MAX_VALUE;
      }
    }
    
    // WARNING: might take time to calculate. You should run this in a seperate thread.
    public int getImageUncompressedSize(String path) {
      String ext = getExt(path);
      if (ext.equals("png")) {
        return getPNGUncompressedSize(path);
      }
      else if (ext.equals(engine.ENTRY_EXTENSION)) {
        return 0;
      }
      else if (ext.equals("jpg") || ext.equals("jpeg")) {
        return getJPEGUncompressedSize(path);
      }
      else if (ext.equals("gif")) {
        return getGifUncompressedSize(path);
      }
      else if (ext.equals("bmp")) {
        return getBMPUncompressedSize(path);
      }
      else {
        console.bugWarn("getImageUncompressedSize: file format ("+ext+" is not an image format.");
        return Integer.MAX_VALUE;
      }
    }
  }
  
  AtomicBoolean loadedEverything = new AtomicBoolean(false);
  
  
  // *************************************************************
  // *********************Begin engine code***********************
  // *************************************************************
  public Engine(PApplet p) {
    // PApplet & engine init stuff
    app = p;
    app.background(0);
    loadedContent = new HashSet<String>();
    
    console = new Console();
    console.info("Hello console");
    
    settings = new SettingsModule();
    input = new InputModule();
    file = new FilemanagerModule(this);
    sharedResources = new SharedResourcesModule();
    display = new DisplayModule();
    power = new PowerModeModule();
    ui = new UIModule();
    sound = new AudioModule();
    clipboard = new ClipboardModule();
    
    power.putFPSSystemIntoGraceMode();
    
    // First, load the essential stuff.
    
    loadAsset(APPPATH+SOUND_PATH+"intro.wav");
    loadAsset(APPPATH+IMG_PATH+"logo.png");
    loadAllAssets(APPPATH+IMG_PATH+"loadingmorph/");
    // Find out how many images there are in loadingmorph
    File f = new File(APPPATH+IMG_PATH+"loadingmorph/");
    display.loadingFramesLength = f.listFiles().length;
    loadAsset(APPPATH+DEFAULT_FONT_PATH);
    
    // Load in seperate thread.
    loadedEverything.set(false);
    Thread t1 = new Thread(new Runnable() {
      public void run() {
          loadEverything();
          loadedEverything.set(true);
        }
      }
    );
    t1.start();

    //println("Running in seperate thread.");
    // Config file
    getUpdateInfo();
    


    power.setDynamicFramerate(settings.getBoolean("dynamicFramerate"));
    DEFAULT_FONT_NAME = settings.getString("defaultSystemFont");
    
    DEFAULT_FONT = display.getFont(DEFAULT_FONT_NAME);

    // Init loading screen.
    currScreen = new Startup(this);
  }


  public Runnable doWhenPromptSubmitted = null;
  public String promptText;
  public boolean inputPromptShown = false;
  public String lastInput = "";

  public void beginInputPrompt(String prompt, Runnable doWhenSubmitted) {
    input.keyboardMessage = "";
    inputPromptShown = true;
    input.addNewlineWhenEnterPressed = false;
    promptText = prompt;
    doWhenPromptSubmitted = doWhenSubmitted;
  }

  public void displayInputPrompt() {
    if (inputPromptShown) {
      // this is such a placeholder lol
      app.noStroke();

      app.fill(255);
      app.textAlign(CENTER, CENTER);
      app.textFont(DEFAULT_FONT, 60);
      app.text(promptText, display.WIDTH/2, display.HEIGHT/2-100);
      app.textSize(30);
      app.text(input.keyboardMessage, display.WIDTH/2, display.HEIGHT/2);
      
      if (keyCode == UP) {
        keyCode = 0;
        if (lastInput.length() > 0) {
          input.keyboardMessage = lastInput;
        }
      }
      
      if (input.ctrlDown && input.keys[int('v')] == 2) {
        //input.keyboardMessage = input.keyboardMessage.substring(0, input.keyboardMessage.length()-1);
        if (clipboard.isString()) {
          input.keyboardMessage += clipboard.getText();
        }
      }

      if (input.enterOnce) {
        inputPromptShown = false;
        //if (input.keyboardMessage.length() <= 0) return;
        // Remove enter character at end
        if (input.keyboardMessage.length() > 0) {
          int ll = max(input.keyboardMessage.length()-1, 0);   // Don't allow it to go lower than 0
          if (input.keyboardMessage.charAt(ll) == '\n') input.keyboardMessage = input.keyboardMessage.substring(0, ll);
        }
        doWhenPromptSubmitted.run();
        lastInput = input.keyboardMessage;
      }
    }
  }


  public AtomicBoolean operationComplete = new AtomicBoolean(false);
  public String updateError = "";
  public AtomicInteger completionPercent = new AtomicInteger(0);

  public void downloadFile(String url, String outputFileName) {
    operationComplete.set(false);
    InputStream in;
    try {
      in = (new URL(url)).openStream();
    }
    catch (MalformedURLException e1) {
      console.warn(e1.getMessage());
      updateError = "URL is malformed, this might be an issue on the server side.";
      operationComplete.set(true);
      return;
    }
    catch (IOException e2) {
      console.log("Use /update to attempt the update again.");
      updateError = "Couldn't open update stream, check your connection.";
      operationComplete.set(true);
      return;
    }
    
    
    ReadableByteChannel rbc = Channels.newChannel(in);
    FileOutputStream fos = null;
    try {
      fos = new FileOutputStream(outputFileName);
    }
    catch (FileNotFoundException e1) {
      console.warn(e1.getMessage());
      console.log("Use /update to attempt the update again.");
      updateError = "An unknown error occured on the client side";
      operationComplete.set(true);
      return;
    }
    try {
      fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
    }
    catch (IOException e) {
      console.log("Use /update to attempt the update again.");
      console.warn("exception warning:"+e.getMessage());
      updateError = "Something happened while streaming from the server, check your connection.";
      operationComplete.set(true);
    }
    try { fos.close(); }
    catch (IOException e) {
      console.warn(e.getMessage());
      updateError = "Couldn't save the download to disk, maybe permissions denied?";
      operationComplete.set(true);
      return;
    }
    operationComplete.set(true);
  }

  public void unzip(String zipFilePath, String destDirectory) {
    completionPercent.set(0);
    operationComplete.set(false);

    File destDir = new File(destDirectory);
    if (!destDir.exists()) {
      destDir.mkdirs();
    }


    byte[] buffer = new byte[1024];
    int numberFilesExtracted = 0;
    try {
      FileInputStream fis = new FileInputStream(zipFilePath);
      ZipInputStream zipInputStream = new ZipInputStream(fis);

      // Get size of the zip file
      ZipFile zipFile = new ZipFile(zipFilePath);
      int zipSize = zipFile.size();
      zipFile.close();
      
      boolean success = true;
      ZipEntry zipEntry = zipInputStream.getNextEntry();
      while (zipEntry != null) {
        String fileName = zipEntry.getName();
        File newFile = new File(destDirectory + File.separator + fileName);

        // Create all non-existing parent directories for the new file
        new File(newFile.getParent()).mkdirs();

        if (!zipEntry.isDirectory()) {
          try {
            FileOutputStream fos = new FileOutputStream(newFile);
            int length;
            while ((length = zipInputStream.read(buffer)) > 0) {
              fos.write(buffer, 0, length);
            }
            fos.close();
            numberFilesExtracted++;
            completionPercent.set(int((float(numberFilesExtracted)/float(zipSize))*100.));
          }
          catch (Exception e) {
            console.warn("Couldn't uncompress file: "+newFile+", "+e.getMessage());
            success = false;
          }
        }
        zipInputStream.closeEntry();
        zipEntry = zipInputStream.getNextEntry();
      }
      zipInputStream.close();
      if (!success)
        updateError = "Something went wrong with extracting individual files.";
      operationComplete.set(true);
    }
    catch (Exception e) {
      console.warn("An error occured with extracting the files, "+e.getMessage());
      e.printStackTrace();
      updateError = "An error occured with extracting the files...";
      operationComplete.set(true);
    }
  }
  
  public void runOSCommand(String cmd) {
    switch (platform) {
      case WINDOWS:
        String[] cmds = new String[1];
        cmds[0] = cmd;
        app.saveStrings(APPPATH+WINDOWS_CMD, cmds);
        delay(100);
        file.open(APPPATH+WINDOWS_CMD);
      break;
      default:
      console.bugWarn("runOSCommand: support for os not implemented!");
    }
  }

  private int updatePhase = 0;
  // 0 - Not updating at all.
  // 1 - Downloading
  // 2 - Unzipping
  private int checkPercentageInterval = 0;
  private int downloadPercent = 0;
  private String downloadPath;

  private void runUpdate() {

    // Download
    if (updatePhase == 1) {

      // Get the download size so we can show a nice progress bar.
      // The size of the download will of course depend on the type of platform we're on.
      // i.e. windows downloads are a lot larger than macos downloads because we include the whole
      // java 8 package.
      int fileSize = 1;
      String plat = "";
      switch (platform) {
      case WINDOWS:
        plat = "windows-download-size";
        break;
      case LINUX:
        plat = "linux-download-size";
        break;
      case MACOS:
        plat = "macos-download-size";
        break;
      }

      // Get size
      if (updateInfo != null) fileSize = updateInfo.getInt(plat, 1)*1024;  // Time 1024 because download size is in kilobytes
      else console.bugWarn("runUpdate: why is updateInfo null?!");

      // Every 0.5 secs, update the download percentage
      checkPercentageInterval++;
      if (checkPercentageInterval > (int)(30./display.getDelta())) {
        checkPercentageInterval = 0;

        // Because we can't really check how many bytes we've downloaded without making
        // it suuuuuuper slow, let's just do it using a botch'd approach. Scan the file on
        // the drive that's currently being downloaded.
        File dw = new File(this.downloadPath);
        downloadPercent = int(((float)dw.length()/(float)fileSize)*100.);
      }
      // Render the UI
      pushMatrix();
      scale(display.getScale());
      noStroke();
      color c = color(127);
      float x1 = display.WIDTH/2;
      float y1 = 0;
      float hi = 128;
      float wi = 128*2;
      // TODO have some sort of fabric function instead of this mess.
      display.shader("fabric", "color", float((c>>16)&0xFF)/255., float((c>>8)&0xFF)/255., float((c)&0xFF)/255., 1., "intensity", 0.1);
      rect(x1-wi, y1, wi*2, hi);
      display.defaultShader();
      ui.loadingIcon(x1-wi+64, y1+64);

      fill(255);
      textAlign(LEFT, TOP);
      textFont(DEFAULT_FONT, 30);
      text("Downloading...", x1-wi+128, y1+10, wi*2-128, hi);
      textSize(20);
      text("You can continue using Timeway while updating.", x1-wi+128, y1+50, wi*2-128, hi);
      // Process bar
      fill(0, 127);
      rect(x1-wi+128+10, y1+hi-15, (float(downloadPercent)/100.)*((wi*2)-128-30), 3);
      textAlign(RIGHT, BOTTOM);
      textSize(18);
      text(str(downloadPercent)+"%", x1+wi-5, y1+hi-5);

      popMatrix();
      // If finished downloading move on to extracting the files.
      if (operationComplete.get() == true) {
        // Check no error has occured...
        if (updateError.length() == 0) {
          updatePhase = 2;
          
          Thread t1 = new Thread(new Runnable() {
            public void run() {
                try {
                  unzip(downloadPath, file.getMyDir());
                }
                catch (Exception e) {
                  console.warn("An error occured while downloading update...");
                }
                
                // Once unzipped we no longer need the zip file
                File f = new File(downloadPath);
                // f exists just for safety...
                if (f.exists()) f.delete();
                else console.bugWarn("runUpdate: why is the download zip missing??");
              }
            }
          );
          updateError = "";
          t1.start();
        }
        else {
          updatePhase = 666;
        }
      }
      
    } else if (updatePhase == 2) {
      pushMatrix();
      scale(display.getScale());
      noStroke();
      color c = color(127);
      float x1 = display.WIDTH/2;
      float y1 = 0;
      float hi = 128;
      float wi = 128*2;
      // TODO have some sort of fabric function instead of this mess.
      display.shader("fabric", "color", float((c>>16)&0xFF)/255., float((c>>8)&0xFF)/255., float((c)&0xFF)/255., 1., "intensity", 0.1);
      rect(x1-wi, y1, wi*2, hi);
      display.defaultShader();
      ui.loadingIcon(x1-wi+64, y1+64);

      fill(255);
      textAlign(LEFT, TOP);
      textFont(DEFAULT_FONT, 30);
      text("Extracting...", x1-wi+128, y1+10, wi*2-128, hi);
      textSize(20);
      text("Timeway will restart in the new version shortly.", x1-wi+128, y1+50, wi*2-128, hi);
      
      downloadPercent = completionPercent.get();
      // Process bar
      fill(0, 127);
      rect(x1-wi+128+10, y1+hi-15, (float(downloadPercent)/100.)*((wi*2)-128-30), 3);
      textAlign(RIGHT, BOTTOM);
      textSize(18);
      text(str(downloadPercent)+"%", x1+wi-5, y1+hi-5);
      
      popMatrix();
      
      
      if (operationComplete.get()) {
        delay(1000);
        if (updateError.length() == 0) {
          String exeloc = "";
          switch (platform) {
            case WINDOWS:
              exeloc = updateInfo.getString("windows-executable-location", "");
              break;
            case LINUX:
              exeloc = updateInfo.getString("linux-executable-location", "");
              break;
            case MACOS:
              exeloc = updateInfo.getString("macos-executable-location", "");
              break;
          }
          // TODO: move files from old version
          String newVersion = file.getMyDir()+exeloc;
          File f = new File(newVersion);
          if (f.exists()) {
            updatePhase = 0;
            //Process p = Runtime.getRuntime().exec(newVersion);
            String cmd = "start \"Timeway\" /d \""+file.getDir(newVersion).replaceAll("/", "\\\\")+"\" \""+file.getFilename(newVersion)+"\"";
            console.log(cmd);
            runOSCommand(cmd);
            delay(500);
            exit();
          }
          else {
            console.warn("New version of Timeway could not be found, please close Timeway and open new version manually.");
            console.log("The new version should be somewhere in "+newVersion);
            updatePhase = 0;
          }
        }
        else {
          updatePhase = 666;
        }
      }
    }
    else if (updatePhase == 666) {
      pushMatrix();
      scale(display.getScale());
      noStroke();
      color c = color(127);
      float x1 = display.WIDTH/2;
      float y1 = 0;
      float hi = 128;
      float wi = 128*2;
      // TODO have some sort of fabric function instead of this mess.
      display.shader("fabric", "color", float((c>>16)&0xFF)/255., float((c>>8)&0xFF)/255., float((c)&0xFF)/255., 1., "intensity", 0.1);
      rect(x1-wi, y1, wi*2, hi);
      display.defaultShader();
      
      display.imgCentre("error", x1-wi+64, y1+64);
      
      fill(255);
      textAlign(LEFT, TOP);
      textFont(DEFAULT_FONT, 30);
      text("An error occurred...", x1-wi+128, y1+10, wi*2-128, hi);
      textSize(20);
      text(updateError, x1-wi+128, y1+50, wi*2-128, hi);
      
      popMatrix();
    }
  }
  
  public String getExeFilename() {
    switch (platform) {
      case WINDOWS:
      return "Timeway.exe";
      case LINUX:
      console.bugWarn("getExeFilename(): Not implemented for Linux");
      break;
      case MACOS:
      console.bugWarn("getExeFilename(): Not implemented for MacOS");
      break;
    }
    return "";
  }
  
  public void restart() {
    String cmd = "";
    
    // TODO: make restart work while in Processing (dev mode)
    switch (platform) {
      case WINDOWS:
      cmd = "start \"Timeway\" /d \""+file.getMyDir().replaceAll("/", "\\\\")+"\" \""+getExeFilename()+"\"";
      break;
      case LINUX:
      console.bugWarn("restart(): Not implemented for Linux");
      return;
      case MACOS:
      console.bugWarn("restart(): Not implemented for MacOS");
      return;
    }
    runOSCommand(cmd);
    delay(500);
    exit();
  }


  void beginUpdate(final String downloadUrl, final String downloadPath) {
    this.downloadPath = downloadPath;

    // Phase 1: download zip file
    updatePhase = 1;

    // Run in a seperate thread obviously
    Thread t1 = new Thread(new Runnable() {
      public void run() {
        // Delete the old file as it may be leftover from an attempted update.
        File old = new File(downloadPath);
        if (old.exists()) old.delete();
        try {
          downloadFile(downloadUrl, downloadPath);
        }
        catch (Exception e) {
          updateError = "An unknown error occured while downloading update...";
          console.warn("An error occured while downloading update...");
        }
      }
    }
    );
    updateError = "";
    
    t1.start();
  }

  public boolean commandPromptShown = false;
  public void showCommandPrompt() {
    commandPromptShown = true;

    // Execute our command when the command is submitted.
    Runnable r = new Runnable() {
      public void run() {
        commandPromptShown = false;
        runCommand(input.keyboardMessage);
      }
    };

    beginInputPrompt("Enter command", r);
    input.keyboardMessage = "/";
  }

  private boolean commandEquals(String input, String expected) {
    int ind = input.indexOf(' ');
    if (ind <= -1) {
      ind = input.length();
    } else {
      if (ind >= input.length())  return false;
    }
    return (input.substring(0, ind).equals(expected));
  }


  public void runCommand(String command) throws RuntimeException {
    // TODO: have a better system for commands.
    if (command.equals("/powersaver")) {
      if (!power.getPowerSaver()) {
        power.setPowerSaver(true);
        console.log("Power saver enabled.");
      }
      else {
        power.setPowerSaver(false);
        console.log("Power saver disabled.");
      }
    } else if (commandEquals(command, "/forcepowermode")) {
      // Count the number of characters, add one.
      // That's how you deal with substirng.
      String arg = "";
      if (command.length() > 16)
        arg = command.substring(16);

      power.setForcedPowerMode(arg);
      if (arg.equals("HIGH") || arg.equals("NORMAL") || arg.equals("SLEEPY") || arg.equals("MINIMAL")) console.log("Forced power mode set to "+arg);
      else console.log("Unknown power mode "+arg);
    } else if (commandEquals(command, "/disableforcepowermode")) {
      console.log("Disabled forced powermode.");
      power.disableForcedPowerMode();
    } else if (commandEquals(command, "/benchmark")) {
      int runFor = 180;
      String arg = "";
      if (command.length() > 11) {
        arg = command.substring(11);
        console.log(arg);
        runFor = int(arg);
      }

      beginBenchmark(runFor);
    } else if (commandEquals(command, "/debuginfo")) {
      // Toggle debug info
      console.debugInfo = !console.debugInfo;
      if (console.debugInfo) console.log("Debug info enabled.");
      else console.log("Debug info disabled.");
    } else if (commandEquals(command, "/update")) {
      shownUpdateScreen = false;
      showUpdateScreen = false;
      getUpdateInfo();
      // Force delay
      while (!updateInfoLoaded.get()) { delay(10); }
      processUpdate();
      if (showUpdateScreen) {
        currScreen.requestScreen(new Updater(this, this.updateInfo));
        console.log("An update is available!");
      }
      else console.log("No updates available.");
    } 
    else if (commandEquals(command, "/throwexception")) {
      console.log("Prepare for a crash!");
      throw new RuntimeException("/throwexception command");
    }
    else if (commandEquals(command, "/restart")) {
      console.log("Restarting Timeway...");
      restart();
    }
    else if (commandEquals(command, "/backgroundmusic") || commandEquals(command, "/backmusic")) {
      playWhileUnfocused = !playWhileUnfocused;
      if (playWhileUnfocused) console.log("Background music (while focused) enabled.");
      else console.log("Background music (while focused) disabled.");
    }
    else if (commandEquals(command, "/enablebackgroundmusic") || commandEquals(command, "/enablebackmusic")) {
      playWhileUnfocused = true;
      console.log("Background music (while focused) disabled.");
    }
    else if (commandEquals(command, "/disablebackgroundMusic") || commandEquals(command, "/disablebackMusic")) {
      playWhileUnfocused = false;
      console.log("Background music (while focused) disabled.");
    }
    else if (commandEquals(command, "/showfps")) {
      if (display.showFPS()) {
        display.setShowFPS(false);
        console.log("FPS hidden.");
      }
      else {
        display.setShowFPS(true);
        console.log("FPS shown.");
      }
    }
    else if (commandEquals(command, "/cpubenchmark")) {
      if (display.showCPUBenchmarks) {
        display.showCPUBenchmarks = false;
        console.log("CPU benchmarks hidden.");
      }
      else {
        display.showCPUBenchmarks = true;
        console.log("CPU benchmarks shown.");
      }
    }
    else if (commandEquals(command, "/stopmusic")) {
      console.log("Music stopped");
      sound.stopMusic();
    }
    else if (commandEquals(command, "/reloadshaders")) {
      display.reloadShaders();
      console.log("Shaders reloaded.");
    }
    else if (commandEquals(command, "/memusage")) {
      display.showMemUsage = !display.showMemUsage;
      if (display.showMemUsage) console.log("Memory usage bar shown.");
      else console.log("Memory usage bar hidden.");
    }
    // No commands
    else if (command.length() <= 1) {
      // If empty, do nothing and close the prompt.
    } else if (currScreen.customCommands(command)) {
      // Do nothing, we just don't want it to return "unknown command" for a custom command.
    } else {
      console.log("Unknown command.");
    }
  }


  public final int MAX_TIMESTAMPS = 1024;
  public boolean benchmark = false;
  public int timestampIndex = 0;
  public boolean finalBenchmarkFrame = false;
  public long[] benchmarkArray = new long[MAX_TIMESTAMPS];
  public long benchmarkFrames = 0;
  public ArrayList<String> benchmarkResults = new ArrayList<String>();
  public long benchmarkRunFor;

  public void beginBenchmark(int runFor) {
    benchmarkResults = new ArrayList<String>();
    benchmarkFrames = 0;
    benchmarkArray = new long[MAX_TIMESTAMPS];
    finalBenchmarkFrame = false;
    benchmark = true;
    this.benchmarkRunFor = (long)runFor;
    console.log("Benchmark started");
  }

  public void runBenchmark() {
    if (benchmark) {
      timestampIndex = 0;
      benchmarkFrames++;
      if (benchmarkFrames >= benchmarkRunFor) {
        if (!finalBenchmarkFrame) finalBenchmarkFrame = true;  // Order the timestamps to finalise the results
        else {
          console.log("Benchmark ended");
          benchmark = false;
          currScreen.requestScreen(new Benchmark(this));
        }
      }
    }
  }

  // Debugging function
  public void timestamp() {
    timestamp("t"+str(timestampCount++));
  }

  // custom fps function that gets the fps depending on the
  // time between the last frame and the current frame.


  // This is a debug function used for measuring performance at certain points.
  public void timestamp(String name) {
    if (!benchmark) {
      long nanoCapture = System.nanoTime();
      if (lastTimestampName == null) {
        //String out = name+" timestamp captured.";
        //if (console != null) console.info(out);
        //else println(out);
      } else {
        //String out = lastTimestampName+" - "+name+": "+str((nanoCapture-lastTimestamp)/1000)+"microseconds";
        //if (console != null) console.info(out);
        //else println(out);
      }
      lastTimestampName = name;
      lastTimestamp = nanoCapture;
    } else {
      long nanoCapture = System.nanoTime();
      benchmarkArray[timestampIndex++] += (nanoCapture-lastTimestamp)/1000;
      lastTimestamp = nanoCapture;

      if (finalBenchmarkFrame) {
        // Calculate the average for that timestamp.
        long results = benchmarkArray[timestampIndex-1] /= benchmarkFrames;
        String mssg = lastTimestampName+" - "+name+": "+str(results)+"microseconds";
        benchmarkResults.add(mssg);
        lastTimestampName = name;
      }
    }
  }

  public final String UPDATE_INFO_URL = "https://teojt.github.io/updates/timeway_update.json";

  JSONObject updateInfo = null;
  public boolean shownUpdateScreen = false;
  AtomicBoolean updateInfoLoaded = new AtomicBoolean(false);
  public boolean showUpdateScreen = false;
  public void getUpdateInfo() {
    Thread t = new Thread(new Runnable() {
      public void run() {
        try {
          updateInfo = loadJSONObject(UPDATE_INFO_URL);
        }
        catch (Exception e) {
          console.warn("Couldn't get update info");
        }
        updateInfoLoaded.set(true);
      }
    }
    );
    updateInfoLoaded.set(false);
    t.start();
  }



  public void processUpdate() {
    if (!shownUpdateScreen && updateInfoLoaded.get()) {
      shownUpdateScreen = true;
      boolean update = true;
      try {
        update &= updateInfo.getString("type", "").equals("update");
        update &= !updateInfo.getString("version", "").equals(this.VERSION);
        JSONArray compatibleVersion = updateInfo.getJSONArray("compatible-versions");

        boolean compatible = false;
        for (int i = 0; i < compatibleVersion.size(); i++) {
          compatible |= compatibleVersion.getString(i).equals(this.VERSION);
        }
        compatible |= updateInfo.getBoolean("update-if-incompatible", false);
        compatible |= updateInfo.getBoolean("update-if-uncompatible", false);    // Oops I made a typo at one point

        update &= compatible;

        // Check if there's a release available for the platform Timeway is running on.
        String downloadURL = "";
        switch (platform) {
        case WINDOWS:
          downloadURL = updateInfo.getString("windows-download", "[none]");
          break;
        case LINUX:
          downloadURL = updateInfo.getString("linux-download", "[none]");
          break;
        case MACOS:
          downloadURL = updateInfo.getString("macos-download", "[none]");
          break;
        }
        update &= !(downloadURL.equals("[none]") || downloadURL.equals("null"));

        // Priority
        // 0: optional  (no prompt)
        // 1: standard  (prompt)
        // 2: kinda important  (show even if updates repressed)
        // 3: important  (update automatically without permission, even if updates are repressed, DO NOT USE UNLESS EMERGENCY)
        update &= (updateInfo.getInt("priority", 1) > 0);
      }
      catch (Exception e) {
        console.warn("A problem occured with trying to get update info.");
        showUpdateScreen = false;
        return;
      }

      showUpdateScreen = update;
    }
  }
  

  public void loadEverything() {
    // load everything else.
    loadAllAssets(APPPATH+IMG_PATH);
    loadAllAssets(APPPATH+FONT_PATH);
    loadAllAssets(APPPATH+SHADER_PATH);
    loadAllAssets(APPPATH+SOUND_PATH);
    
    // gstreamer takes time to start, cache the music so that we can use it while gstreamer starts up.
    sound.loadMusicCache();
  }

  
  // Literally copied right from sketchiepad.
  // Probably gonna be hella messy code.
  // But oh well.
  class Console {

    private ConsoleLine[] consoleLine;
    int timeout = 0;
    final static int messageDelay = 60;
    final static int totalLines = 60;
    final static int displayLines = 20;
    private int initialPos = 0;
    private boolean force = false;
    public boolean debugInfo = false;
    PFont consoleFont;
    public BasicUI basicui;
    private boolean enableBasicUI = false;

    private class ConsoleLine {
      private int interval = 0;
      private int pos = 0;
      private String message;
      private color messageColor;

      public ConsoleLine() {
        messageColor = color(255, 255);
        interval = 0;
        this.message = "";
        this.pos = initialPos;
        basicui = new BasicUI();
      }

      //public void enableUI() {
      //  enableBasicUI = true;
      //}

      //public void disableUI() {
      //  enableBasicUI = false;
      //}

      public void move() {
        this.pos++;
      }

      public int getPos() {
        return this.pos;
      }

      //public boolean isBusy() {
      //  return (interval > 0);
      //}

      //public void kill() {
      //  interval = 0;
      //}

      public void message(String message, color messageColor) {
        this.pos = 0;
        this.interval = 200;
        this.message = message;
        this.messageColor = messageColor;
      }

      public void display() {
        if (display != null) display.recordRendererTime();
        
        app.textFont(consoleFont);
        if (force) {
          if (interval > 0) {
            interval--;
          }

          int ypos = pos*32;
          noStroke();
          fill(0);
          int recWidth = int(display.WIDTH/2.);
          if (recWidth < textWidth(this.message)) {
            recWidth = (int)textWidth(this.message)+10;
          }
          app.rect(0, ypos, recWidth, 32);
          app.textSize(24);
          app.textAlign(LEFT);
          app.fill(this.messageColor);
          app.text(message, 5, ypos+20);
        } else {
          if (interval > 0 && pos < displayLines) {
            interval--;
            int ypos = pos*32;
            app.noStroke();
            if (interval < 60) {
              fill(0, 4.25*float(interval));
            } else {
              fill(0);
            }
            int recWidth = int(display.WIDTH/2.);
            if (recWidth < app.textWidth(this.message)) {
              recWidth = (int)app.textWidth(this.message)+10;
            }
            app.rect(0, ypos, recWidth, 32);
            app.textSize(24);
            app.textAlign(LEFT);
            if (interval < 60) {
              app.fill(this.messageColor, 4.25*float(interval));
            } else {
              app.fill(this.messageColor);
            }
            app.text(message, 5, ypos+20);
          }
        }
        if (display != null) display.recordLogicTime();
      }
    }

    public Console() {
      this.consoleLine = new ConsoleLine[totalLines];
      this.generateConsole();
      
      boolean createFontFailed = false;
      try {
        consoleFont = createFont(APPPATH+CONSOLE_FONT, 24);
      }
      catch (NullPointerException e) {
        createFontFailed = true;
      }
      if (createFontFailed) consoleFont = null;
      if (consoleFont == null) {
        consoleFont = createFont("Monospace", 24);
      }
      if (consoleFont == null) {
        consoleFont = createFont("Courier", 24);
      }
      if (consoleFont == null) {
        consoleFont = createFont("Ariel", 24);
      }
    }

    private void generateConsole() {
      for (int i = 0; i < consoleLine.length; i++) {
        consoleLine[i] = new ConsoleLine();
        this.initialPos++;
      }
    }

    public void enableDebugInfo() {
      this.debugInfo = true;
      this.info("Extra debug info enabled.");
    }
    public void disableDebugInfo() {
      this.debugInfo = false;
    }

    //private void killLines() {
    //  for (int i = 0; i < totalLines; i++) {
    //    this.consoleLine[i].kill();
    //  }
    //}

    public void display(boolean doDisplay) {
      if (doDisplay) {
        //pushMatrix();
        //scale
        //popMatrix();
        for (int i = 0; i < totalLines; i++) {
          this.consoleLine[i].display();
        }
      }
      if (this.timeout > 0) {
        this.timeout--;
      }
      force = false;
    }

    public void force() {
      this.force = true;
    }

    public void consolePrint(Object message, color c) {
      int l = totalLines;
      int i = 0;
      int last = 0;

      String m = "";
      if (message instanceof String) {
        m = (String)message;
      } else if (message instanceof Integer) {
        m = str((Integer)message);
      } else if (message instanceof Float) {
        m = str((Float)message);
      } else if (message instanceof Boolean) {
        m = str((Boolean)message);
      } else {
        m = message.toString();
      }

      while (i < l) {
        if (consoleLine[i].getPos() == (l - 1)) {
          last = i;
        }
        consoleLine[i].move();
        i++;
      }
      consoleLine[last].message(m, c);
      println(message);
    }


    public void log(Object message) {
      this.consolePrint(message, color(255));
    }
    public void warn(String message) {
      this.consolePrint("WARNING "+message, color(255, 200, 30));
      if (enableBasicUI) {
        this.basicui.showWarningWindow(message);
      }
    }
    public void bugWarn(String message) {
      this.consolePrint("BUG WARNING "+message, color(255, 102, 102));
    }
    public void error(String message) {
      this.consolePrint("ERROR "+message, color(255, 30, 30));
    }
    public void info(Object message) {
      if (this.debugInfo)
        this.consolePrint(message, color(127));
    }
    public void logOnce(Object message) {
      if (this.timeout == 0)
        this.consolePrint(message, color(255));
      this.timeout = messageDelay;
    }
    public void warnOnce(String message) {
      if (this.timeout == 0)
        this.warn(message);
      this.timeout = messageDelay;
    }
    public void bugWarnOnce(String message) {
      if (this.timeout == 0)
        this.bugWarn(message);
      this.timeout = messageDelay;
    }
    public void errorOnce(String message) {
      if (this.timeout == 0)
        this.error(message);
      this.timeout = messageDelay;
    }
    public void infoOnce(Object message) {
      if (this.timeout == 0)
        this.info(message);
      this.timeout = messageDelay;
    }
  }



  // BasicUI class part of the console class.
  // Might go unused. It was part of the sketchypad
  // project in order to provide warnings to dumb people.
  class BasicUI {


    public BasicUI() {
    }

    private boolean displayingWindow = false;
    private float offsetX = 0, offsetY = 0;
    private float radius = 30;
    private String message = "hdasklfhwea ewajgf awfkgwe fehwafg eawhjfgew ajfghewafg jehwafgghaf hewafgaehjfgewa fg aefhjgew fgewafg egaf ghewaf egwfg ewgfewa fhgewf e wgfgew afgew fg egafwe fg egwhahjfgsd asdnfv eahfhedhajf gweahj fweghf";

    private void warningWindow() {
      offsetX = sin(frameCount)*radius;
      offsetY = cos(frameCount)*radius;

      radius *= 0.90;

      stroke(0);
      strokeWeight(4);
      fill(200);
      rect(200+offsetX, 300+offsetY, display.WIDTH-400, display.HEIGHT-500);
      fill(color(255, 127, 0));
      rect(200+offsetX, 200+offsetY, display.WIDTH-400, 100);

      noStroke();

      textAlign(CENTER, CENTER);
      textSize(62);
      fill(255);
      text("WARNING!!", display.WIDTH/2+offsetX, 240+offsetY);

      textAlign(LEFT, LEFT);

      textSize(24);
      fill(0);
      text(message+"\n\n[press x to dismiss]", 220+offsetX, 320+offsetY, width-440, height-500);
    }

    public void showWarningWindow(String m) {
      //sndNope.play();
      message = m;
      radius = 50;
      displayingWindow = true;
    }

    public boolean displayingWindow() {
      return displayingWindow;
    }

    public void stopDisplayingWindow() {
      displayingWindow = false;
    }  

    public void display() {
      if (displayingWindow) {
        warningWindow();
      }
    }
  }


  //*******************************************
  //****************ENGINE CODE****************
  //*******************************************
  public void loadAsset(String path) {
    // Make it windows compatible by converting all backslashes to
    // a normal slash.
    path = path.replace('\\', '/');

    // get extension
    String ext = path.substring(path.lastIndexOf(".")+1);

    // Get file name without the extension
    String name = path.substring(path.lastIndexOf("/")+1, path.lastIndexOf("."));

    //println(name);

    // We don't need to bother with content that's already been loaded.
    if (loadedContent.contains(name)) {
      return;
    }
    // if extension is image
    if (ext.equals("png") || ext.equals("jpg") || ext.equals("gif") || ext.equals("bmp")) {
      // load image and add it to the systemImages hashmap.
      if (display.systemImages.get(name) == null) {
        display.systemImages.put(name, new DImage(app.loadImage(path)));
        loadedContent.add(name);
      } else {
        console.warn("Image "+name+" already exists, skipping.");
      }
    } else if (ext.equals("otf") || ext.equals("ttf")) {       // Load font.
      display.fonts.put(name, app.createFont(path, 32));
    } else if (ext.equals("vlw")) {
      display.fonts.put(name, app.loadFont(path));
    } else if (ext.equals("glsl") || ext.equals("vert")) {
      display.loadShader(path);
    } else if (ext.equals("frag")) {
      // Don't load anything since .vert also loads corresponding .frag
    } else if (ext.equals("wav") || ext.equals("ogg") || ext.equals("mp3")) {
      sound.sounds.put(name, new SoundFile(app, path));
    } else {
      console.warn("Unknown file type "+ext+" for file "+name+", skipping.");
    }
  }

  public void loadAllAssets(String path) {
    // Get list of all assets in current dir
    File f = new File(path);
    File[] assets = f.listFiles();
    
    if (assets != null) {
      // Loop through all assets
      for (int i = 0; i < assets.length; i++) {
        // If asset is a directory
        if (assets[i].isFile()) {
          // Load asset
          loadAsset(assets[i].getAbsolutePath());
        }
        // If asset is a file
        else if (assets[i].isDirectory()) {
          // Load all assets in that directory
          loadAllAssets(assets[i].getAbsolutePath());
        }
      }
    }
    else console.warn("Missing assets, was the files tampered with?");
  }

  

  private float counter = 0.;

  public int counter(int max, int interval) {
    return (int)((counter)/interval) % (max);
  }

  public String appendZeros(int num, int length) {
    String str = str(num);
    while (str.length() < length) {
      str = "0"+str;
    }
    return str;
  }

  public boolean isLoading() {
    // Report loading if standard assets (images etc) are still being loaded
    if (loadedEverything.get() == false) return true;
    
    // If caching's turned off wait for GStreamer.
    if (!CACHE_MUSIC) {
      if (sound.loadingMusic()) return true;
    }
    else {
      // Otherwise, proceed right ahead if-
      // The home dir's .pixelrealm-bgm is cached
      // The default music/legacy default music is being played (these are automatically cached.
      // If we're not using the default music and the home realm with the .pixelrealm file isn't cached,
      // we have no choice but to wait (or start with silence but this isn't desireable so lets just report that its still loading) 
      
      boolean cacheHit = false;
      cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".wav");
      cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".ogg");
      cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".mp3");
      cacheHit |= sound.cacheHit(APPPATH+PixelRealm.REALM_BGM_DEFAULT);
      cacheHit |= sound.cacheHit(APPPATH+PixelRealm.REALM_BGM_DEFAULT_LEGACY);
      if (sound.loadingMusic() && !cacheHit)
        return true;
    }
    
    return false;
  }

  public String getLastModified(String path) {
    Path file = Paths.get(path);

    if (!file.toFile().exists()) {
      return null;
    }

    BasicFileAttributes attr;
    try {
      attr = Files.readAttributes(file, BasicFileAttributes.class);
    }
    catch (IOException e) {
      console.warn("Couldn't get date modified time: "+e.getMessage());
      return null;
    }

    return attr.lastModifiedTime().toString();
  }

  public int calculateChecksum(PImage image) {
    // To prevent a really bad bug from happening, only actually calculate the checksum if the image is bigger than say,
    // 64 pixels lol.
    if (image.width > 64 || image.height > 64) {
      int checksum = 0;
      int w = image.width;
      int h = image.height;

      int gapx = int(image.width*0.099);
      int gapy = int(image.height*0.099);

      for (int y = 0; y < h; y+=gapy) {
        for (int x = 0; x < w; x+=gapx) {
          int pixel = image.get(x, y);
          int red = (pixel >> 16) & 0xFF; // Extract red component
          int green = (pixel >> 8) & 0xFF; // Extract green component
          int blue = pixel & 0xFF; // Extract blue component

          // Add the pixel values to the checksum
          checksum += red + green + blue;
        }
      }

      return checksum;
    } else return 0;
  }

  public JSONObject cacheInfoJSON = null;

  // Whenever cache is written, it would be inefficient to open and close the file each time. So, have a timeout
  // timer which when it expires, the file is written and saved and closed.
  public int cacheInfoTimeout = 0;

  public void openCacheInfo() {
    boolean createNewInfoFile = false;

    File cacheFolder = new File(APPPATH+CACHE_PATH);
    if ((cacheFolder.exists() && cacheFolder.isDirectory()) == false) {
      console.info("openCacheInfo: cache folder gone, regenerating folder.");
      if (!cacheFolder.mkdir()) {
        console.warn("Couldn't remake the cache directory for whatever reason...");
        return;
      }
    }

    // First, open the cache file if it's not been opened already.
    if (cacheInfoTimeout == 0) {
      // Should be true if the info file doesn't exist.
      console.info("openCacheInfo: "+APPPATH+CACHE_INFO);
      File f = new File(APPPATH+CACHE_INFO);
      if (!f.exists()) {
        createNewInfoFile = true;
      } else {
        try {
          cacheInfoJSON = loadJSONObject(APPPATH+CACHE_INFO);
        }
        catch (RuntimeException e) {
          console.warn("Cache file is curroupted. Cache will be erased and regenerated.");
          createNewInfoFile = true;
          return;
        }
        // Make sure this cached file is compatible.
        // We add a question mark in the name so that a file can't possibly be named the same in the json file
        String comp_ver = cacheInfoJSON.getString("?cache_compatibility_version", "");
        if (!comp_ver.equals(CACHE_COMPATIBILITY_VERSION)) createNewInfoFile = true;
      }
    }

    // TODO: we could probably make this value lower?
    cacheInfoTimeout = 10;  // Reset the timer.

    if (createNewInfoFile) {
      console.info("new cache file being created.");
      // Since all currently cached images are now considered useless without the info file, delete all cached images,
      // Folders will be recreated as necessary.
      // TODO: idk ill implement file deleting later, it's not necessary rn.

      // Create the new json file.
      cacheInfoJSON = new JSONObject();
      cacheInfoJSON.setString("?cache_compatibility_version", CACHE_COMPATIBILITY_VERSION);
      saveJSONObject(cacheInfoJSON, APPPATH+CACHE_INFO);

      cacheInfoTimeout = 0;
    }
  }

  private int cacheShrinkX = 0;
  private int cacheShrinkY = 0;
  public void setCachingShrink(int x, int y) {
    cacheShrinkX = x;
    cacheShrinkY = y;
  }
  
  // Gets the size of the cache if available, otherwise returns the original size.
  public int getCacheSize(String originalPath) {
    openCacheInfo();
    JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);
    if (cachedItem != null) {
      return cachedItem.getInt("size", 0);
    }
    else {
      String ext = file.getExt(originalPath);
      if (ext.equals("bmp") || ext.equals("png") || ext.equals("jpeg") || ext.equals("jpg") || ext.equals("gif")) {
        return file.getImageUncompressedSize(originalPath);
      }
      else {
        console.bugWarn("getCacheSize: unsupported file format "+ext+", returning file size.");
        return (int)((new File(originalPath)).length());
      }
    }
  }
  
  
  // IMPORTANT NOTE: This function does NOT load in a seperate thread, so you should do that yourself
  // when using this!
  public SoundFile tryLoadSoundCache(String originalPath, Runnable readOriginalOperation) {
    openCacheInfo();

    JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);
    
    
    // If the object is null here, then there's no info therefore we cannot
    // perform the checksum, so continue to load original instead.
    if (cachedItem != null) {
      console.info("tryLoadSoundCache: Found cached entry from info file");
      
      
      // First, load the actual sound using the actual file path (the one above is a lie lol)
      String actualPath = cachedItem.getString("actual", "");
      

        if (actualPath.length() > 0) {
      File f = new File(originalPath);
      String lastModified = "[null]";        // Test below automatically fails if there's no file found.
      if (f.exists()) lastModified = getLastModified(originalPath);
      
        // Check if the sound has been modified at all since last time before we load the original.
        if (cachedItem.getString("lastModified", "").equals(lastModified)) {
          console.info("tryLoadSoundCache: No modifications");
          
          // No checksum tests because checksums are kinda useless anyways!
          
          // All checks passed so we can load the cache.
          console.info("tryLoadSoundCache: loading cached sound");
          try {
            // Do NOT let this stay in RAM once we're done with it! (the false argument in this constructor)
            SoundFile loadedSound = new SoundFile(app, actualPath, false);
            return loadedSound;
          }
          catch (RuntimeException e) {
            console.info("tryLoadSoundCache: welp, time to load the original!");
            console.info("tryLoadSoundCache: something went wrong with loading cache (maybe it's corrupted)");
          }
          
          
          // After this point something happened to the original image (or cache in unusual circumstances)
          // and must not be used.
          // We continue to load original and recreate the cache.
        }
      }
      
      
    }
    
    // We should only reach this point if no cache exists or is corrupted
    console.info("tryLoadSoundCache: loading original instead");
    if (readOriginalOperation != null) readOriginalOperation.run();
    console.info("tryLoadSoundCache: done loading");
    

    SoundFile returnSound = originalSound;
    // Set it to null to catch programming errors next time.
    originalSound = null;
    return returnSound;
  }

  // Returns image if an image is found, returns null if cache for that image doesn't exist.
  public PImage tryLoadImageCache(String originalPath, Runnable readOriginalOperation) {
    console.info("tryLoadImageCache: "+originalPath);
    openCacheInfo();

    JSONObject cachedItem = cacheInfoJSON.getJSONObject(originalPath);

    // If the object is null here, then there's no info therefore we cannot
    // perform the checksum, so continue to load original instead.
    if (cachedItem != null) {
      console.info("tryLoadImageCache: Found cached entry from info file");
      // First, load the actual image using the actual file path (the one above is a lie lol)
      String actualPath = cachedItem.getString("actual", "");


      // TODO: shouldn't take long loading a small image, but maybe we should probably use requestImage()
      if (actualPath.length() > 0) {
        console.info("tryLoadImageCache: loading cached image");
        PImage loadedImage = loadImage(actualPath);
        if (loadedImage != null) {
          console.info("tryLoadImageCache: Found cached image");

          File f = new File(originalPath);
          String lastModified = "[null]";
          if (f.exists()) lastModified = getLastModified(originalPath);

          if (cachedItem.getString("lastModified", "").equals(lastModified)) {
            console.info("tryLoadImageCache: No modifications");

            // Perform a checksum which determines if the image can properly be loaded.
            int checksum = calculateChecksum(loadedImage);
            // Return -1 by default if for some reason the checksum is abscent because checksums shouldn't be negative
            if (checksum == cachedItem.getInt("checksum", -1)) {
              console.info("tryLoadImageCache: checksums match");
              return loadedImage;
            } else console.info("tryLoadImageCache: Checksums don't match "+str(checksum)+" "+str(cachedItem.getInt("checksum", -1)));

            // After this point something happened to the original image (or cache in unusual circumstances)
            // and must not be used.
            // We continue to load original and recreate the cache.
          }
        }
      }
    }

    // We should only reach this point if no cache exists or is corrupted
    console.info("tryLoadImageCache: loading original instead");
    readOriginalOperation.run();
    console.info("tryLoadImageCache: done loading");

    // At this point we *should* have an image in cachedImage
    if (originalImage == null) {
      //console.bugWarn("tryLoadImageCache: Your runnable must store your loaded image using setOriginalImage(PImage image)");
      return null;
    }

    // Once we read the original image, we now need to cache the file.
    // Only save to cache if we didn't use requestImage();
    // TODO: remove...?
    //if (originalImage.width != 0 && originalImage.height != 0)
    //saveCacheImage(originalPath, originalImage, true);

    PImage returnImage = originalImage;
    // Set it to null to catch programming errors next time.
    originalImage = null;
    return returnImage;
  }

  public void moveCache(String oldPath, String newPath) {
    openCacheInfo();
    // If cache of that file exists...
    if (!cacheInfoJSON.isNull(oldPath)) {
      console.info("moveCache: Moved image cache "+newPath);
      JSONObject properties = cacheInfoJSON.getJSONObject(oldPath);

      // Tbh we don't care about deleting the original entry
      // Just create a new entry in the new location.

      cacheInfoJSON.setJSONObject(newPath, properties);
    }

    // Should close automatically by the cache manager so no need to save or anything.
  }
  
  

  public void scaleDown(PImage image, int scale) {
    console.info("scaleDown: "+str(image.width)+","+str(image.height)+",scale"+str(scale));
    if ((image.width > scale || image.height > scale)) {
      // If the image is vertical, resize to 0x512
      if (image.height > image.width) {
        image.resize(0, scale);
      }
      // If the image is horizontal, resize to 512x0
      else if (image.width > image.height) {
        image.resize(scale, 0);
      }
      // Eh just scale it horizontally by default.
      else image.resize(scale, 0);
    }
  }
  

  // TODO: Put this in a seperate thread, because hoo lordy.
  public String saveCacheImage(String originalPath, PImage image) {
    console.info("saveCacheImage: "+originalPath);
    if (image instanceof Gif) {
      console.warn("Caching gifs not supported yet!");
      return originalPath;
    }
    openCacheInfo();

    JSONObject properties = new JSONObject();

    String cachePath = generateCachePath(CACHE_FILE_TYPE);

    final String savePath = cachePath;
    final int resizeByX = cacheShrinkX;
    final int resizeByY = cacheShrinkY;
    console.info("saveCacheImage: generating cache in main thread");

    // Scale down the cached image so that we have sweet performance and minimal ram usage next time we load up this
    // world. Check if it's actually big enough to be scaled down and scale down by whether it's taller or wider.

    // TODO: cacheShrinkX and cacheShrinkY are not actually needed, we just need a true/false boolean.
    if (resizeByX != 0 || resizeByY != 0) 
      //image = experimentalScaleDown(image);
      scaleDown(image, max(resizeByX, resizeByY));

    console.info("saveCacheImage: saving...");
    image.save(savePath);
    console.info("saveCacheImage: saved");

    properties.setString("actual", cachePath);
    properties.setInt("checksum", calculateChecksum(image));
    
    File f = new File(originalPath);
    if (f.exists()) {
      properties.setString("lastModified", getLastModified(originalPath));
      properties.setInt("size", image.width*image.height*4);
    }
    else {
      properties.setString("lastModified", "");
      
      // TODO: Gif support.
      properties.setInt("size", image.width*image.height*4);
    }

    cacheInfoJSON.setJSONObject(originalPath, properties);
    console.info("saveCacheImage: Done creating cache");

    return cachePath;
  }


  public PImage saveCacheImageBytes(String originalPath, byte[] bytes, String type) {
    openCacheInfo();

    JSONObject properties = new JSONObject();

    String cachePath = generateCachePath(type);

    // Save it as a png.
    saveBytes(cachePath, bytes);
    // Load the png.
    PImage img = loadImage(cachePath);

    properties.setString("actual", cachePath);
    properties.setInt("checksum", calculateChecksum(img));
    properties.setString("lastModified", "");
    properties.setInt("size", 0);
    cacheInfoJSON.setJSONObject(originalPath, properties);


    return img;
  }

  public String generateCachePath(String ext) {
    // Get a unique idenfifier for the file
    String cachePath = APPPATH+CACHE_PATH+"cache-"+str(int(random(0, 2147483646)))+"."+ext;
    File f = new File(cachePath);
    while (f.exists()) {
      cachePath = APPPATH+CACHE_PATH+"cache-"+str(int(random(0, 2147483646)))+"."+ext;
      f = new File(cachePath);
    }

    return cachePath;
  }
  
  private float noise_seed = random(0, 189456790123485.);
  private float noise_octave = 2.;
  private float noise_falloff = 0.5;
  
  public float noise(float x, float y) {
    //4420.0825
    //32760.305
    //519930
    
    long k = (long)(x*4420.0825) + (long)(y*32760.305)*519930 + (long)noise_octave*1048576 + (long)(noise_falloff*1048576.) + (long)noise_seed;
    Float val = noiseCache.get(k);
    if (val == null) {
      float newval = app.noise(x, y);
      
      if (noiseCache.size() > 50000) {
        // Just to be memory-safe.
        noiseCache.clear();
      }
      
      noiseCache.put(k, newval);
      return newval;
    }
    else {
      return (float)val;
    }
  }
  
  public float noise(float x) {
    return this.noise(x, 0);
  }
  
  public void noiseSeed(int seed) {
    noise_seed = (float)seed;
    app.noiseSeed(seed);
  }

  public void noiseDetail(int octave, float fall) {
    noise_octave = (float)octave;
    noise_falloff = fall;
    app.noiseDetail(octave, fall);
  }



  private PImage originalImage = null;
  private SoundFile originalSound = null;
  public void setOriginalImage(PImage image) {
    if (image == null) console.bugWarn("setOriginalImage: the image you provided is null! Is your runnable load code working??");
    originalImage = image;
  }
  public void setOriginalSound(SoundFile sound) {
    if (sound == null) console.bugWarn("setOriginalSound: the sound you provided is null! Is your runnable load code working??");
    originalSound = sound;
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public class InputModule {
    
    // Mouse & keyboard
    public boolean primaryClick = false;
    public boolean secondaryClick = false;
    public boolean primaryDown = false;
    public boolean secondaryDown = false;
    public boolean keyOnce = false;
    public boolean keyDown = false;
    
    public boolean mouseMoved = false;
    
    public float   rawScroll = 0;
    public float   scroll = 0;
    public float   scrollSensitivity = 30.0;
    
    public String keyboardMessage = "";
    public boolean addNewlineWhenEnterPressed = true;
    
    // used for one-time click
    private boolean click = false;
    private boolean eventClick = false;   // This is used sort of as a backup click as a solution to the problem where the user clicks in quick succession, but there aren't enough frames inbetween.
    private float normalClickTimeout = 0.;
    private float keyHoldCounter = 0;
    private float clickStartX = 0;
    private float clickStartY = 0;
    private char lastKeyPressed = 0;
    private int lastKeycodePressed = 0;
    private float holdKeyFrames = 0.;
    
    private float cache_mouseX = 0.0;
    private float cache_mouseY = 0.0;
    public  float scrollOffset = 0.0;
    
    public int keys[]     = new int[1024];
    
    // Down
    public boolean backspaceDown = false;
    public boolean shiftDown = false;
    public boolean ctrlDown = false;
    public boolean altDown  = false;
    public boolean enterDown = false;
    
    // Down counters
    private int backspaceDownCounter = 0;
    private int shiftDownCounter = 0;
    private int ctrlDownCounter = 0;
    private int altDownCounter  = 0;
    private int enterDownCounter = 0;
    
    // Once
    public boolean backspaceOnce = false;
    public boolean shiftOnce = false;
    public boolean ctrlOnce = false;
    public boolean altOnce  = false;
    public boolean enterOnce = false;
    
    public InputModule() {
      scrollSensitivity = settings.getFloat("scrollSensitivity");
    }
    
      
    public void runInputManagement() {
      //*************MOUSE MOVEMENT*************
      cache_mouseX = mouseX/display.getScale();
      cache_mouseY = mouseY/display.getScale();
      
      
      
      //*************MOUSE CLICKING*************
      // "Shouldn't it be (app.mouseButton == LEFT)?"
      // One word. MacOS.
      primaryDown = app.mousePressed && (app.mouseButton != RIGHT);
      secondaryDown = (app.mousePressed &&  (app.mouseButton == RIGHT));
      
      // If the mouse begins click on the frame, this will be later updated to true.
      // Then next frame this will be set to false, and because of the one-click code,
      // this will not be updated at all hence remaining false.
      primaryClick = false;
      secondaryClick = false;
      
      normalClickTimeout -= display.getDelta();
  
      // Here, we use either our default click method or we use the "void mouseClicked" method to
      // mitigate the cases where the mouse is clicked rapidly but not released fast enough for the click variable to be set to false.
      // In order to stop double-click bugs (where we click once but it registers twice because of click and eventClick firing on slightly different frames),
      // we need to introduce a small timeout for event clicks which are always a few frames later.
      if ((app.mousePressed && !click) || (eventClick)) {
        click = true;
        
        // While normal click might not be able to register a mouseup for a few frames, rely on the event click
        // in case user rapidly clicks.
        if (!eventClick)
          normalClickTimeout = 15.;
        eventClick = false;
        
        primaryClick = (app.mouseButton != RIGHT);
        
        secondaryClick = (app.mouseButton == RIGHT);
        
        mouseMoved = false;
        clickStartX = mouseX();
        clickStartY = mouseY();
      }
      else if (!app.mousePressed && click) {
        click = false;
        
        if (clickStartX != mouseX() || clickStartY != mouseY()) {
          mouseMoved = true;
        }
      }
  
  
      //*************KEYBOARD*************
      
      // Oneshot key control
      for (int i = 0; i < 1024; i++) {
        if (keys[i] > 0) {
          keys[i]++;
        }
      }
      
      // Special keys oneshots
      if (backspaceDown) backspaceDownCounter++; else backspaceDownCounter = 0; 
      if (shiftDown) shiftDownCounter++; else shiftDownCounter = 0;
      if (ctrlDown) ctrlDownCounter++; else ctrlDownCounter = 0;
      if (altDown) altDownCounter++; else altDownCounter = 0;
      if (enterDown) enterDownCounter++; else enterDownCounter = 0;
      
      backspaceOnce = (backspaceDownCounter == 1);
      shiftOnce = (shiftDownCounter == 1);
      ctrlOnce = (ctrlDownCounter == 1);
      altOnce = (altDownCounter == 1);
      enterOnce = (enterDownCounter == 1);
      
      // Holding counter (for repeating held keys)
      if (keyHoldCounter >= 1.) {
        keyHoldCounter += display.getDelta();
      }
      // The code that actually repeats the held key.
      if (keyHoldCounter > KEY_HOLD_TIME) {
        power.setAwake();
        // good fix for bad framerates.
        // However we want smooth framerates so we set it to awake mode so this
        // code barely matters oop.
        for (int i = int(holdKeyFrames*0.5); i >= 2; i--) {
          keyboardAction(lastKeyPressed, lastKeycodePressed);
          holdKeyFrames -= 2;
        }
        holdKeyFrames += display.getDelta();
      }
  
      //*************MOUSE WHEEL*************
      if (rawScroll != 0) {
        scroll = rawScroll*-scrollSensitivity;
      } else {
        scroll *= 0.5;
      }
      rawScroll = 0.;
    }
    
  
    // To be called by base sketch code.
    public void releaseKeyboardAction(char kkey, int kkeyCode) {
      // Special keys
      if (kkey == CODED) {
        switch (kkeyCode) {
        case CONTROL:
          ctrlDown = false;
          break;
        case SHIFT:
          shiftDown = false;
          break;
        case ALT:
          altDown = false;
          break;
        }
      }
      else if (kkey == BACKSPACE || kkey == RETURN) {
        backspaceDown = false;
      }
      else if (kkey == ENTER) {
        enterDown = false;
      }
      // Down keys
      int val = int(Character.toLowerCase(kkey));
      
      if (val >= 1024) return;
      
      keys[val] = 0;
    }
  
    public boolean keyDown(char k) {
      if (inputPromptShown) return false;
      
      int val = int(Character.toLowerCase(k));
      return keys[val] >= 1;
    }
    
    public boolean keyDownOnce(char k) {
      if (inputPromptShown) return false;
      
      int val = int(Character.toLowerCase(k));
      
      //if (keys[val] > 0) {
      //  console.log(val);
      //}
      
      return keys[val] == 2;
    }
    
  
    public boolean keyAction(String keybindName) {
      char k = settings.getKeybinding(keybindName);
      
      // Special keys/buttons
      if (int(k) == settings.LEFT_CLICK)
        return this.primaryClick;
      else if (int(k) == settings.RIGHT_CLICK)
        return this.secondaryClick;
      else 
        // Otherwise just tell us if the key is down or not
        return keyDown(k);
    }
  
    public boolean keyActionOnce(String keybindName) {
      char k = settings.getKeybinding(keybindName);
      
      // Special keys/buttons
      if (int(k) == settings.LEFT_CLICK)
        return this.primaryClick;
      else if (int(k) == settings.RIGHT_CLICK)
        return this.secondaryClick;
      else {
        // Otherwise just tell us if the key is down or not
        return keyDownOnce(k);
      }
    }
  
    public void backspace() {
      if (this.keyboardMessage.length() > 0) {
        this.keyboardMessage = this.keyboardMessage.substring(0, this.keyboardMessage.length()-1);
      }
    }
    
    public float mouseX() {
      return cache_mouseX;
    }
  
    public float mouseY() {
      return cache_mouseY;
    }
    
    
    // TODO: This is old code. Need I say more?
    // It's also broken af.
    public void processScroll(float top, float bottom) {
      final float ELASTIC_MAX = 100.;
      
      if (scroll != 0.0) {
        power.setAwake();
      }
      else {
        power.setSleepy();
      }
      
      int n = 1;
      switch (power.getPowerMode()) {
            case HIGH:
            n = 1;
            break;
            case NORMAL:
            n = 2;
            break;
            case SLEEPY:
            n = 4;
            break;
            case MINIMAL:
            n = 1;
            break;
      }
      
      // Sorry not sorry
      for (int i = 0; i < n; i++) {
        if (scrollOffset > top) {
            scrollOffset -= (scrollOffset-top)*0.1;
            if (input.scroll < 0.0) scrollOffset += input.scroll;
            else scrollOffset += input.scroll*(max(0.0, ((ELASTIC_MAX+top)-scrollOffset)/ELASTIC_MAX));
        }
        else if (-scrollOffset > bottom) {
            // TODO: Actually get some pen and paper and make the elastic band edge work.
            // This is just a placeholder so that it's usable.
            scrollOffset = -bottom;
          
            //scrollOffset += (bottom-scrollOffset)*0.1;
            //if (engine.scroll > 0.0) scrollOffset += engine.scroll;
            //else scrollOffset += engine.scroll*(max(0.0, ((-scrollOffset)-(ELASTIC_MAX+bottom))/ELASTIC_MAX));
        }
        else scrollOffset += input.scroll;
      }
    }
      
    
    public void clickEventAction() {
      // We don't want to trigger a click if the normal clicking system receives a click.
      if (normalClickTimeout < 0.) {
        eventClick = true;
      }
    }
    
    public void releaseAllInput() {
      for (int i = 0; i < 1024; i++) {
        keys[i] = 0;
      }
      primaryClick = false;
      secondaryClick = false;
      primaryDown = false;
      secondaryDown = false;
      click = false;
      eventClick = false;
      keyHoldCounter = 0.;
    }
    
    public void keyboardAction(char kkey, int kkeyCode) {
      if (kkey == CODED) {
        switch (kkeyCode) {
          case CONTROL:
            ctrlDown = true;
            return;
          case SHIFT:
            shiftDown = true;
            break;
          case ALT:
            altDown = true;
            return;
        }
      } else if (kkey == ENTER || kkey == RETURN) {
        if (this.addNewlineWhenEnterPressed) {
          this.keyboardMessage += "\n";
        }
        enterDown = true;
      } else if (kkey == BACKSPACE) {    // Backspace
        this.backspace();
        backspaceDown = true;
      }
      else {
        this.keyboardMessage += kkey;
      }
      
      // And actually set the current pressed key state
      int val = int(Character.toLowerCase(kkeyCode));
      
      if (val >= 1024) return;
      if (keys[val] > 0) return;
      keys[val] = 1;
    }
  }

  // Cus why replace 9999999 lines of code when you can write 6 new lines of code that makes sure everything still works.
  public float mouseX() {
    return input.mouseX();
  }
  public float mouseY() {
    return input.mouseY();
  }





  
  
  public class ClipboardModule {
    private Object cachedClipboardObject;
    
    public boolean isImage() {
      if (cachedClipboardObject == null) cachedClipboardObject = getFromClipboard(DataFlavor.imageFlavor);
      
      // If still false, is nothing so isn't an image.
      if (cachedClipboardObject == null) return false;
      return (cachedClipboardObject instanceof java.awt.Image);
    }
  
    public String getText()
    {
      if (cachedClipboardObject == null) cachedClipboardObject = getFromClipboard(DataFlavor.stringFlavor);
      String text = (String) cachedClipboardObject;
      cachedClipboardObject = null;
      return text;
    }
    
    public boolean isString() {
      if (cachedClipboardObject == null) cachedClipboardObject = getFromClipboard(DataFlavor.stringFlavor);
      
      // If still false, is nothing so isn't an image.
      if (cachedClipboardObject == null) return false;
      return (cachedClipboardObject instanceof String);
    }
  
    // That can be the future's problem lol
    @SuppressWarnings("deprecation")
    public PImage getImage()
    {
      PImage img = null;
      
      if (cachedClipboardObject == null) cachedClipboardObject = getFromClipboard(DataFlavor.imageFlavor);
      
      java.awt.Image image = (java.awt.Image) getFromClipboard(DataFlavor.imageFlavor);
      
      cachedClipboardObject = null;
      
      if (image != null)
      {
        img = new PImage(image);
      }
      return img;
    }
  
    private Object getFromClipboard(DataFlavor flavor)
    {
      Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
      Transferable contents;
      try {
        contents = clipboard.getContents(null);
      }
      catch (IllegalStateException e) {
        contents = null;
      }
  
      Object obj = null;
      if (contents != null && contents.isDataFlavorSupported(flavor))
      {
        try
        {
          obj = contents.getTransferData(flavor);
        }
        catch (UnsupportedFlavorException exu) // Unlikely but we must catch it
        {
          console.warn("(Copy/paste) Unsupported flavor");
          //~  exu.printStackTrace();
        }
        catch (java.io.IOException exi)
        {
          console.warn("(Copy/paste) Unavailable data: " + exi);
          //~  exi.printStackTrace();
        }
      }
      return obj;
    } 
    
    // Returns true if successful, false if not
    public boolean copyString(String str) {
      String myString = str;
      try {
        StringSelection stringSelection = new StringSelection(myString);
        Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
        clipboard.setContents(stringSelection, null);
      }
      catch (RuntimeException e) {
        console.warn(e.getMessage());
        console.warn("Couldn't copy text to clipboard: ");
        return false;
      }
      return true;
    }
  
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  public void processCaching() {
    if (cacheInfoTimeout > 0) {
      cacheInfoTimeout--;
      if (cacheInfoTimeout == 0) {
        if (cacheInfoJSON != null) {
          console.info("processCaching: saving cache info.");
          saveJSONObject(cacheInfoJSON, APPPATH+CACHE_INFO);
        }
      }
    }
  }

  // Woops I should place this at the start.
  boolean focusedMode = true;

  // The core engine function which essentially runs EVERYTHING in Timeway.
  // All the screens, all the input management, and everything else.
  public void engine() {
    if (display != null) display.resetTimes();
    if (display != null) display.recordLogicTime();
    // Run benchmark if it's active.
    runBenchmark();
    
    display.WIDTH = width/display.displayScale;
    display.HEIGHT = height/display.displayScale;

    power.updatePowerMode();

    sound.processSound();
    processCaching();


    if (display != null) display.recordRendererTime();
    // This should be run at all times because apparently (for some stupid reason)
    // it uses way more performance NOT to call background();
    app.background(0);
    if (display != null) display.recordLogicTime();

    // Update inputs
    input.runInputManagement();
    
    // Get updates
    processUpdate();

    // Show the current GUI.
    display.displayScreens();
    
    ui.displayMiniMenu();
    
    if (display.showMemUsage) {
      display.displayMemUsageBar();
    }
    
    
    
    // If Timeway is updating, a little notice and progress
    // bar will appear in front of the screen.
    runUpdate();


    // Allow command prompt to be shown.
    if (input.keyActionOnce("showCommandPrompt") && allowShowCommandPrompt)
      showCommandPrompt();


    if (commandPromptShown) {
      // Display the command prompt if shown.
      app.pushMatrix();
      app.scale(display.getScale());
      noStroke();
      app.fill(0, 127);
      app.noStroke();
      float promptWi = 600;
      float promptHi = 250;
      app.rect(display.WIDTH/2-promptWi/2, display.HEIGHT/2-promptHi/2, promptWi, promptHi);
      displayInputPrompt();
      app.noFill();
      app.popMatrix();
    }

    counter += display.getDelta();
    // Update times so we can calculate live fps.
    display.update();
    if (display.showCPUBenchmarks) display.showBenchmarks();
    
    if (display.showFPS()) {
      pushMatrix();
      app.scale(display.getScale());
      app.textFont(DEFAULT_FONT, 32);
      app.textAlign(LEFT, TOP);
      float y = 5;
      if (currScreen != null) y = currScreen.myUpperBarWeight+5;
      
      String txt = str(round(frameRate))+"\n"+power.getPowerModeString();
      
      app.fill(0);
      app.text(txt, 5, y);
      app.fill(255);
      app.text(txt, 7, y+2);
      app.popMatrix();
    }

    // Display console
    // TODO: this renders the console 4 times which is BAD.
    // We need to make the animation execute 4 times, not the drawing routines.
    console.display(true);
    
    display.resetTimes();
    
    if (display != null) display.timeMode = display.IDLE_TIME;
  }
  
}

//*******************************************
//****************SCREEN CODE****************
//*******************************************
// The basis for everything you see in timeway.
// An abstract class so it merely defines the
// default style of timeway.
public abstract class Screen {
  protected final float UPPER_BAR_WEIGHT = 50;
  protected final float LOWER_BAR_WEIGHT = 50;
  protected final color UPPER_BAR_DEFAULT_COLOR = color(200);
  protected final color LOWER_BAR_DEFAULT_COLOR = color(200);
  protected final color DEFAULT_BACKGROUND_COLOR = color(50);
  protected final float DEFAULT_ANIMATION_SPEED = 0.1;

  protected final int NONE = 0;
  protected final int START = 1;
  protected final int END = 2;

  protected Engine engine;
  protected Engine.Console console;
  protected PApplet app;
  protected Engine.SharedResourcesModule sharedResources;
  protected Engine.SettingsModule settings;
  protected Engine.InputModule input;
  protected Engine.DisplayModule display;
  protected Engine.PowerModeModule power;
  protected Engine.AudioModule sound;
  protected Engine.FilemanagerModule file;
  protected Engine.ClipboardModule clipboard;
  protected Engine.UIModule ui;
  
  protected float screenx = 0;
  protected float screeny = 0;
  protected color myUpperBarColor = UPPER_BAR_DEFAULT_COLOR;
  protected color myLowerBarColor = LOWER_BAR_DEFAULT_COLOR;
  protected color myBackgroundColor = DEFAULT_BACKGROUND_COLOR;
  protected float myUpperBarWeight = UPPER_BAR_WEIGHT;
  protected float myLowerBarWeight = LOWER_BAR_WEIGHT;
  protected float myAnimationSpeed = DEFAULT_ANIMATION_SPEED;
  protected int transitionState = NONE;
  protected float transitionTick = 0;
  
  protected float WIDTH = 0.;
  protected float HEIGHT = 0.;

  public Screen(Engine engine) {
    this.engine = engine;
    this.console = engine.console;
    this.app = engine.app;
    
    this.sharedResources = engine.sharedResources;
    this.settings = engine.settings;
    this.input = engine.input;
    this.display = engine.display;
    this.ui = engine.ui;
    this.power = engine.power;
    this.sound = engine.sound;
    this.file = engine.file;
    this.clipboard = engine.clipboard;
    
    this.WIDTH = engine.display.WIDTH;
    this.HEIGHT = engine.display.HEIGHT;
  }

  protected void upperBar() {
    display.recordRendererTime();
    fill(myUpperBarColor);
    noStroke();
    rect(0, 0, WIDTH, myUpperBarWeight);
    display.recordLogicTime();
  }

  protected void lowerBar() {
    display.recordRendererTime();
    fill(myLowerBarColor);
    noStroke();
    rect(0, HEIGHT-myLowerBarWeight, WIDTH, myLowerBarWeight);
    display.recordLogicTime();
  }

  protected void backg() {
    display.recordRendererTime();
    fill(myBackgroundColor);
    noStroke();
    rect(0, myUpperBarWeight, WIDTH, HEIGHT-myUpperBarWeight-myLowerBarWeight);
    display.recordLogicTime();
  }

  public void startupAnimation() {
  }

  protected void startScreenTransition() {
    engine.transitionScreens = true;
    engine.transition = 1.0;
    engine.transitionDirection = RIGHT;   // Right by default, you can change it to left or anything else
    // right after calling startScreenTransition().
  }

  protected void endScreenAnimation() {
  }

  protected void previousReturnAnimation() {
  }


  protected void requestScreen(Screen screen) {
    if (engine.currScreen == this && engine.transitionScreens == false) {
      engine.prevScreen = this;
      engine.currScreen = screen;
      screen.startScreenTransition();
      engine.power.resetFPSSystem();
      engine.allowShowCommandPrompt = true;
      //engine.setAwake();
    }
  }

  protected void previousScreen() {
    if (this.engine.prevScreen == null) engine.console.bugWarn("No previous screen to go back to!");
    else {
      engine.prevScreen.previousReturnAnimation();
      requestScreen(this.engine.prevScreen);
      engine.transitionDirection = LEFT;
      engine.power.setAwake();
    }
  }


  // A method where you can add your own custom commands.
  // Must return true if a command is found and false if a command
  // is not found.
  @SuppressWarnings("unused")
  protected boolean customCommands(String command) {
    return false;
  }




  // The actual stuff you want to display does NOT go into the 
  // display method but rather the content method. Upper and lower
  // bars overlap the content displayed.
  protected void content() {
  }

  // The magic display method that takes all the components
  // of the screen and mashes it all into one complete screen,
  // ready for the engine to display. Simple as.
  public void display() {
    this.WIDTH = engine.display.WIDTH;
    this.HEIGHT = engine.display.HEIGHT;
    if (power.powerMode != PowerMode.MINIMAL) {
      app.pushMatrix();
      //float scl = display.getScale();
      app.translate(screenx, screeny);
      app.scale(display.getScale());
      this.backg();

      this.content();
      this.upperBar();
      this.lowerBar();
      
      // Show the minimenu if any.
      
      app.popMatrix();
    }
  }
}



public class DImage {
  public float width = 0;
  public float height = 0;
  public int mode = 0;
  public PImage pimage;         // 1
  public LargeImage largeImage; // 2
  
  private void setDimensions(float w, float h) {
    this.width = w;
    this.height = h;
  }
  
  public DImage(PImage pimage) {
    setDimensions(pimage.width, pimage.height);
    this.pimage = pimage;
    mode = 1;
  }
  public DImage(LargeImage largeImage, PImage p) {
    setDimensions(largeImage.width, largeImage.height);
    this.pimage = p;
    this.largeImage = largeImage;
    mode = 2;
  }
}



public class LargeImage {
  public float width = 0, height = 0;
  public int glTexID = -1;
  public PShape shape;
  public IntBuffer texData;
  public boolean inGPU = false;
  
  public LargeImage(IntBuffer texData) {
    super();
    this.texData = texData;
  }
  
  public void finalize() {
    if (timewayEngine != null && timewayEngine.display != null) {
      timewayEngine.display.destroyImage(this);
    }
  }
}









public enum PowerMode {
    HIGH, 
    NORMAL, 
    SLEEPY, 
    MINIMAL
}

public enum FileType {
  FILE_TYPE_UNKNOWN, 
    FILE_TYPE_IMAGE, 
    FILE_TYPE_VIDEO, 
    FILE_TYPE_MUSIC, 
    FILE_TYPE_MODEL, 
    FILE_TYPE_DOC,
    FILE_TYPE_TIMEWAYENTRY,
    FILE_TYPE_SHORTCUT
}
