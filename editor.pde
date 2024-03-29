import java.util.Base64;
import de.humatic.dsj.DSCapture;
import java.awt.image.BufferedImage;
import java.util.concurrent.atomic.AtomicInteger;

class CameraException extends RuntimeException {};

abstract class Capture {
  public abstract void setup();
  public abstract void turnOffCamera();
  public abstract void switchNextCamera();
  public abstract PImage updateImage();
}

class DCapture extends Capture implements java.beans.PropertyChangeListener {
  private DSCapture capture;
  public int width, height;
  public AtomicBoolean ready = new AtomicBoolean(false);
  
  public AtomicBoolean error = new AtomicBoolean(false);
  public AtomicInteger errorCode = new AtomicInteger(0);
  
  public final int DEVICE_NONE = -1;
  public final int DEVICE_CAMERA     = 0;
  public final int DEVICE_MICROPHONE = 1;
  
  private Engine engine;
  public ArrayList<DSFilterInfo> cameraDevices;
  public int selectedCamera = 0;
 
  public DCapture(Engine e) {
    ready.set(false);
    error.set(false);
    engine = e;
  }
  
  // Lmao don't care I'm using Java 8 in 2023 dangit
  @SuppressWarnings("deprecation")
  public void setup() {
    ready.set(false);
    error.set(false);
    
    try {
      DSFilterInfo[][] dsi = DSCapture.queryDevices();
      cameraDevices = new ArrayList<DSFilterInfo>();
      
      for (int y = 0; y < dsi.length; y++) {
        for (int x = 0; x < dsi[y].length; x++) {
          println("("+x+", "+y+") "+dsi[y][x].getName(), dsi[y][x].getType());
          if (dsi[y][x].getType() == DEVICE_CAMERA)
            cameraDevices.add(dsi[y][x]);
        }
      }
      
      if (cameraDevices.size() <= 0) {
        error.set(true);
        errorCode.set(Editor.ERR_NO_CAMERA_DEVICES);
        return;
      }
    }
    catch (UnsatisfiedLinkError e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNSUPPORTED_SYSTEM);
        return;
    }
    catch (NoClassDefFoundError e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNSUPPORTED_SYSTEM);
        return;
    }
    catch (Exception e) {
        error.set(true);
        errorCode.set(Editor.ERR_UNKNOWN);
        return;
    }
    
    
    selectedCamera = (int)engine.sharedResources.get("lastusedcamera", 0);
    activateCamera();
    
    ready.set(true);
  }
  
  public void turnOffCamera() {
    if (capture != null) capture.dispose();
  }
  
  // Activate currently selected camera, switching to next camera if it doesn't work
  private void activateCamera() {
    boolean success = false;
    int originalSelection = selectedCamera;
    
    while (!success) {
      try {
        // Activate the next camera in the list.
        // Some cameras may not work. Skip them if they don't work. If none of them work, throw an error.
        capture = new DSCapture(DSFiltergraph.DD7, cameraDevices.get(selectedCamera), false, DSFilterInfo.doNotRender(), this);
        success = true;
      }
      catch (DSJException e) {
        success = false; // Keep trying
        // Increase index by 1, reset to 0 if we're at end of list.
        selectedCamera = ((selectedCamera+1)%(cameraDevices.size()));
        
        // If we're back where we started, then there's been a problem :(
        if (originalSelection == selectedCamera) {
          error.set(true);
          errorCode.set(Editor.ERR_FAILED_TO_SWITCH);
          return;
        }
      }
    }
    
    width = capture.getDisplaySize().width;
    height = capture.getDisplaySize().height;
  }
  
  public void switchNextCamera() {
    // Only run if a camera isn't currently being setup.
    if (ready.compareAndSet(true, false)) {
      if (cameraDevices == null) return;
      if (cameraDevices.size() == 0) return;
      
      // Turn off last used camera.
      turnOffCamera();
      
      // Increase index by 1, reset to 0 if we're at end of list.
      selectedCamera = ((selectedCamera+1)%(cameraDevices.size()));
      activateCamera();
      
      ready.set(true);
    }
  }
 
  public PImage updateImage() {
    PImage img = createImage(width, height, RGB);
    BufferedImage bimg = capture.getImage();
    bimg.getRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);
    img.updatePixels();
    return img;
  }
 
  public void propertyChange(java.beans.PropertyChangeEvent e) {
    switch (DSJUtils.getEventType(e)) {
    }
  }
}

public class Editor extends Screen {
    public boolean showGUI = false;
    public float upperbarExpand = 0;
    public SpriteSystemPlaceholder gui;
    public SpriteSystemPlaceholder placeables;
    public HashSet<Placeable> placeableset;
    public ArrayList<String> imagesInEntry;  // This is so that we can know what to remove when we exit this screen.
    public TextPlaceable textPlaceable;
    public Placeable editingPlaceable = null;
    public DCapture camera;
    public PGraphics cameraDisplay;
    public String entryName;
    public String entryPath;
    public String entryDir;
    public color selectedColor = color(255, 255, 255);
    public float selectedFontSize = 20;
    public float xview = 0;
    public float yview = 0;
    public TextPlaceable entryNameText;
    public boolean cameraMode = false;
    public boolean autoScaleDown = false;
    public boolean changesMade = false;
    public int upperBarDrop = INITIALISE_DROP_ANIMATION;
    public static final int INITIALISE_DROP_ANIMATION = 0;
    public static final int CAMERA_ON_ANIMATION = 1;
    public static final int CAMERA_OFF_ANIMATION = 2;
    
    final String RENAMEABLE_NAME         = "title";                // The name of the sprite object which is used to rename entries
    final float  EXPAND_HITBOX           = 10;                     // For the (unused) ERS system to slightly increase the erase area to prevent glitches
    final String DEFAULT_FONT            = "Typewriter";           // Default font for entries
    final float  STANDARD_FONT_SIZE      = 64;                     // You get the idea
    final float  DEFAULT_FONT_SIZE       = 30;
    final color  DEFAULT_FONT_COLOR      = color(255, 255, 255);
    final float  MIN_FONT_SIZE           = 8.;
    final float  UPPER_BAR_DROP_WEIGHT   = 150;                    
    final int    SCALE_DOWN_SIZE         = 512;
    
    final color BACKGROUND_COLOR = 0xFF0f0f0e;
    
    // Camera errors
    public final static int ERR_UNKNOWN = 0;
    public final static int ERR_NO_CAMERA_DEVICES = 1;
    public final static int ERR_FAILED_TO_SWITCH = 2;
    public final static int ERR_UNSUPPORTED_SYSTEM = 3;


    

    
    
    private void textOptions() {
      String[] labels = new String[2];
      Runnable[] actions = new Runnable[2];
      
      labels[0] = "Copy";
      actions[0] = new Runnable() {public void run() {
          
          if (editingPlaceable != null) {
            if (editingPlaceable instanceof TextPlaceable) {
              TextPlaceable t = (TextPlaceable)editingPlaceable;
              boolean success = clipboard.copyString(t.text);
              if (success)
                console.log("Copied!");
            }
          }
          
      }};
      
      
      labels[1] = "Delete";
      actions[1] = new Runnable() {public void run() {
          
          if (editingPlaceable != null) {
            placeableset.remove(editingPlaceable);
            changesMade = true;
          }
          
      }};
      
      
      
      ui.createOptionsMenu(labels, actions);
    }
    
    
    private void imageOptions() {
      
      String[] labels = new String[3];
      Runnable[] actions = new Runnable[3];
      
      labels[0] = "Copy";
      actions[0] = new Runnable() {public void run() {
          
        console.log("Copying images to clipboard not supported yet, sorry!");
          
      }};
      
      
      labels[1] = "Save";
      actions[1] = new Runnable() {public void run() {
          
        if (editingPlaceable != null && editingPlaceable instanceof ImagePlaceable) {
          ImagePlaceable im = (ImagePlaceable)editingPlaceable;
          file.selectOutput("Save image...", im.getImage());
        }
          
      }};
      
      labels[2] = "Delete";
      actions[2] = new Runnable() {public void run() {
          
        if (editingPlaceable != null) {
          placeableset.remove(editingPlaceable);
          changesMade = true;
        }
          
      }};
      
      ui.createOptionsMenu(labels, actions);
    }
    
    
    

    public class Placeable {
        public SpriteSystemPlaceholder.Sprite sprite;

        public Placeable() {
            // Essentially get the number of placeables that already exist so we have a unique id for the placeable..
            int id = placeables.spriteNames.size();

            // I wonder if it will crash if there's over 999 objects on a page lol.
            // A bug to look out for later.
            String name = engine.appendZeros(id, 3);
            placeables.placeable(name);
            sprite = placeables.getSprite(name);

            if (!placeableset.contains(this)) {
                placeableset.add(this);
            }
        }
        
        
        protected boolean placeableSelected() {
          return (sprite.mouseWithinHitbox() && placeables.selectedSprite == sprite && engine.pressDown && engine.noMove);
        }


        
        // Just a placeholder display for the base class.
        // You shouldn't use super.display() for inherited classes.
        public void display() {
            app.fill(255, 0, 0);
            app.rect(sprite.xpos, sprite.ypos, sprite.wi, sprite.hi);
        }

        public void update() {
            display();
            placeables.placeable(sprite);
        }
    }


    public class TextPlaceable extends Placeable {
        public String text = "Sample text";
        public float fontSize = DEFAULT_FONT_SIZE;
        public PFont fontStyle;
        public color textColor = DEFAULT_FONT_COLOR;
        public float lineSpacing = 8;
        int newlines = 0;

        public TextPlaceable() {
            super();
            sprite.allowResizing = false;
            fontStyle = display.getFont(DEFAULT_FONT);
        }

        private boolean editing() {
            if (editingPlaceable == this)
              changesMade = true;
            return editingPlaceable == this;
        }

        private int countNewlines(String t) {
            int count = 0;
            for (int i = 0; i < t.length(); i++) {
                if (t.charAt(i) == '\n') {
                    count++;
                }
            }
            return count;
        }

        int testy = 0;
        public void display() {
            app.fill(textColor);
            app.textAlign(LEFT, TOP);
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            //sprite.move(xview, yview);

            // move the text from top to bottom on the screen just for fun
            
            // Update 25/09/23:
            // WOW that is old code
            //if (placeables.selectedSprite != sprite) {
            //    //sprite.offmove(0, 100);
            //}
            //else {
            //    testy = 0;
            //}

            String displayText = "";
            if (editing()) {
                if (int(display.getTime()) % 60 < 30)
                    displayText = engine.keyboardMessage+"|";
                else
                    displayText = engine.keyboardMessage;
            }
              else {
                  displayText = text;
            }
            app.text(displayText, sprite.xpos, sprite.ypos-app.textDescent()+EXPAND_HITBOX/2+10);
        }

        public void update() {
            app.textFont(fontStyle, fontSize);
            app.textLeading(fontSize+lineSpacing);

            // The famous hitbox hack where we set the hitbox to the text size.
            // For width we simply check the textWidth with the handy function.
            // For text height we account for the ascent/descent thing, expand hitbox to make it slightly larger
            // and times it by the number of newlines.
            placeables.hackSpriteDimensions(sprite, int(app.textWidth(text)), int((app.textAscent()+app.textDescent()+lineSpacing)*(countNewlines(text)+1) + EXPAND_HITBOX));

            if (editing()) {
                engine.addNewlineWhenEnterPressed = true;
                // Oh my god if this bug fix doesn't work I'm gonna lose it
                // DO NOT allow the command prompt to appear by pressing '/' and make the current text we're writing disappear
                // while writing text
                engine.allowShowCommandPrompt = false;
                text = engine.keyboardMessage;
            }
            
            if (placeableSelected()) {
                engine.allowShowCommandPrompt = false;
                editingPlaceable = this;
                engine.keyboardMessage = text;
                
                // Mini menu for text
                if (engine.rightPressDown) {
                  textOptions();
                }
            }
            super.update();
        }

    }
    

    public class ImagePlaceable extends Placeable {
        // You'd think we'd assign a PImage object to each ImagePlaceable.
        // However, because of the Sprite implementation, that's not how things
        // are done unfortunately.
        // Instead, we must add the image to the engine's image hashmap and then
        // give it a name that the sprite will use to find the correct image.
        // Stupid workaround but it's the least complicated way of doing things lol.
        // We must also remember to remove the image from the engine when we leave
        // this screen otherwise we'll technically create a memory leak.
        public String imageName;

        public ImagePlaceable() {
            super();
            sprite.allowResizing = true;
        }
        
        public ImagePlaceable(PImage i) {
            super();
            sprite.allowResizing = true;
            
            // Ok yes I see the flaws in this, I'll figure out a more robust system later maybe.
            int uniqueIdentifier = int(random(0, 2147483646));
            String name = "cache-"+str(uniqueIdentifier);
            this.imageName = name;
            
            // I feel so bad using systemImages because it was only ever intended
            // for images loaded by the engine only >.<
            display.systemImages.put(name, i);
            imagesInEntry.add(name);
        }
        
        public void setImage(PImage img, String imgName) {
          this.imageName = imgName;
          display.systemImages.put(imgName, img);
          //app.image(img,0,0);
          imagesInEntry.add(imgName);
        }
        
        public PImage getImage() {
          return display.systemImages.get(this.imageName);
        }
        
        public void display() {
                                      }
        
        public void update() {
            if (placeableSelected()) {
                editingPlaceable = this;
                if (engine.rightPressDown) {
                  imageOptions();
                }
            }
            placeables.sprite(sprite.getName(), imageName);
        }
    }
    
    //**************************************************************************************
    //**********************************EDITOR SCREEN CODE**********************************
    //**************************************************************************************
    public Editor(Engine engine, String entryPath) {
        super(engine);
        gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/editor/");
        gui.repositionSpritesToScale();
        
        // Bug fix: run once so that text element in GUI being at pos 0,0 isn't shown.
        runGUI();
        
        placeables = new SpriteSystemPlaceholder(engine);
        imagesInEntry = new ArrayList<String>();
        placeableset = new HashSet<Placeable>();
        
        this.entryPath = entryPath;
        camera = new DCapture(engine);
        
        // Reset cpu canvas to original size, it will automatically shrink as needed.
        display.currentCPUCanvas = 0;
        
        // Because of the really annoying delay thing, we wanna create a canvas that uses the cpu to draw the frame instead
        // of the P2D renderer struggling to draw things. In the future, we can implement this into the engine so that it can
        // be used in other places and not just for the camera.
        int SIZE_DIVIDER = 2;
        cameraDisplay = createGraphics(int(WIDTH)/SIZE_DIVIDER, int(HEIGHT)/SIZE_DIVIDER);

        // Get the path without the file name
        int lindex = entryPath.lastIndexOf('/');
        if (lindex == -1) {
          lindex = entryPath.lastIndexOf('\\');
          if (lindex == -1) console.warn("Could not find entry's dir, possible bug?");
        }
        if (lindex != -1) {
          this.entryDir = entryPath.substring(0, lindex+1);
          this.entryName = entryPath.substring(lindex+1, entryPath.lastIndexOf('.'));
        }

        // textPlaceable = new TextPlaceable();
        // textPlaceable.sprite.xpos = app.width/2;
        // textPlaceable.sprite.ypos = app.height/2;
        // textPlaceable.text = "[ amogus ]";
        gui.interactable = false;
        
        autoScaleDown = engine.settings.getBoolean("autoScaleDown");

        myLowerBarColor   = 0xFF4c4945;
        myUpperBarColor   = myLowerBarColor;
        myBackgroundColor = BACKGROUND_COLOR;
        //myBackgroundColor = color(255,0,0);

        readEntryJSONInSeperateThread();
    }

    // Honestly just commenting it out so the code isn't as bloated.

    // public void saveEntry() {
    //     // Dummy save name just for testing.
    //     engine.beginSaveEntry(entryPath);

    //     int len = placeableset.size();
    //     int i = 0;
    //     for (Placeable p : placeableset) {
    //         if (p instanceof TextPlaceable) {
    //             TextPlaceable t = (TextPlaceable)p;
    //             engine.save.createStringProperty("ID", t.sprite.name);
    //             engine.save.createIntProperty("type", TYPE_TEXT);
    //             engine.save.createIntProperty("x", int(t.sprite.xpos));
    //             engine.save.createIntProperty("y", int(t.sprite.ypos));
    //             engine.save.createStringProperty("text", t.text);

    //             if (i == len-1) {
    //                 engine.save.endProperties();
    //             }
    //             else {
    //                 engine.save.nextElement();
    //             }
    //         }
    //         i++;
    //     }
    //     engine.save.closeAndSave();
    // }

    // public void readEntry() {
    //     engine.beginReadEntry(entryPath);

    //     int len = engine.read.getElementCount();
    //     for (int i = 0; i < len; i++) {
    //         engine.read.selectElement(i);
    //         int type = engine.read.getIntProperty("type");
    //         console.log("type:"+type);
    //         console.log("ID:"+engine.read.getStringProperty("ID"));
    //         if (type == TYPE_TEXT) {
    //             TextPlaceable t = new TextPlaceable();
    //             t.sprite.xpos = (float)engine.read.getIntProperty("x");
    //             t.sprite.ypos = (float)engine.read.getIntProperty("y");
    //             t.text = engine.read.getStringProperty("text");
    //             placeableset.add(t);

    //             console.log("Created text at x:"+t.sprite.xpos+" y:"+t.sprite.ypos+" text:"+t.text);
    //         }
    //     }
    // }

    //*****************************************************************
    //***********************PLACEABLE TYPES***************************
    //*****************************************************************
    public final int TYPE_UNKNOWN = 0;
    public final int TYPE_TEXT    = 1;
    public final int TYPE_IMAGE   = 2;

    //*****************************************************************
    //**************************SAVE PAGE******************************
    //*****************************************************************
    public void saveEntryJSON() {
      // Only save if any changes were made.
      if (changesMade) {
        sound.playSound("chime");
        numImages = 0;
        //JSONObject json = new JSONObject();
        JSONArray array = new JSONArray();
        for (Placeable p : placeableset) {
            if (p instanceof TextPlaceable)
                saveTextPlaceable(p, array);
            else if (p instanceof ImagePlaceable)
                saveImagePlaceable(p, array);
            else {
                console.bugWarn("Missing code! Couldn't save unknown placeable.");
                console.log("Once: "+p.toString());
            }
        }

        engine.app.saveJSONArray(array, entryPath);
      }
    }

    private void saveTextPlaceable(Placeable p, JSONArray array) {
        TextPlaceable t = (TextPlaceable)p;
        JSONObject obj = new JSONObject();
        obj.setString("ID", t.sprite.name);
        obj.setInt("type", TYPE_TEXT);
        obj.setInt("x", int(t.sprite.xpos));
        obj.setInt("y", int(t.sprite.ypos));
        obj.setFloat("size", t.fontSize);
        obj.setString("text", t.text);
        obj.setInt("color", t.textColor);
        array.append(obj);
    }
    
    public int numImages = 0;
    
    // TODO: we need to put it into a new thread, huh?
    private void saveImagePlaceable(Placeable p, JSONArray array) {
        // First, we need the png image data.
        ImagePlaceable imgPlaceable = (ImagePlaceable)p;
        PImage image = display.systemImages.get(imgPlaceable.sprite.imgName);
        if (image == null) {
          console.bugWarn("Trying to save image placeable, and image doesn't exist in memory?? Possible bug??");
          return;
        }
        
        // No multithreading please!
        // And no shrinking please!
        engine.setCachingShrink(0,0);
        String cachePath = engine.saveCacheImage(entryPath+"_"+str(numImages++), image);
        
        byte[] cacheBytes = loadBytes(cachePath);
        
        String encodedPng = new String(Base64.getEncoder().encode(cacheBytes));
        //println(encodedPng);
        
        JSONObject obj = new JSONObject();
        obj.setString("ID", imgPlaceable.sprite.name);
        obj.setInt("type", TYPE_IMAGE);
        obj.setInt("x", int(imgPlaceable.sprite.xpos));
        obj.setInt("y", int(imgPlaceable.sprite.ypos));
        obj.setInt("wi", int(imgPlaceable.sprite.wi));
        obj.setInt("hi", int(imgPlaceable.sprite.hi));
        obj.setString("imgName", imgPlaceable.sprite.imgName);
        obj.setString("png", encodedPng);
        
        array.append(obj);
    }

    //*****************************************************************
    //**************************SAVE PAGE******************************
    //*****************************************************************
    public void readEntryJSON() {
        // check if file exists
        File f = new File(entryPath);
        if (!f.exists() || f.length() <= 2) {
          // If it doesn't exist or is blank, create a new placeable for the name of the entry
            entryNameText = new TextPlaceable();
            entryNameText.sprite.xpos = 20;
            entryNameText.sprite.ypos = UPPER_BAR_DROP_WEIGHT + 80;
            entryNameText.fontSize = 60.;
            entryNameText.textColor = color(255);
            entryNameText.text = entryName;
            entryNameText.sprite.name = RENAMEABLE_NAME;
            
            // Create date
            TextPlaceable date = new TextPlaceable();
            String d = engine.appendZeros(day(), 2)+"/"+engine.appendZeros(month(), 2)+"/"+year()+"\n"+engine.appendZeros(hour(), 2)+":"+engine.appendZeros(minute(), 2)+":"+engine.appendZeros(second(), 2);
            date.sprite.move(WIDTH-app.textWidth(d)*2., 250);
            date.text = d;
            
            // New entry, new default template, ofc we want to save changes!
            changesMade = true;
            
            loading = false;
            return;
        }
        if (!engine.openJSONArray(entryPath)) {
            return;
        }
        for (int i = 0; i < engine.loadedJsonArray.size(); i++) {
            int type = engine.getJSONArrayInt(i, "type", 0);

            switch (type) {
                case TYPE_UNKNOWN:
                    console.warn("Corrupted element, skipping.");
                break;
                case TYPE_TEXT: 
                    TextPlaceable t = readTextPlaceable(i);
                    // Title text element should always be 000
                    if (t.sprite.name.equals(RENAMEABLE_NAME)) entryNameText = t;
                break;
                case TYPE_IMAGE: 
                    readImagePlaceable(i);
                break;
                default:
                    console.warn("Corrupted element, skipping.");
                break;
            }
        }
        loading = false;
    }
    private TextPlaceable readTextPlaceable(int i) {
        TextPlaceable t = new TextPlaceable();
        t.sprite.xpos = (float)engine.getJSONArrayInt(i, "x", (int)WIDTH/2);
        t.sprite.ypos = (float)engine.getJSONArrayInt(i, "y", (int)HEIGHT/2);
        t.sprite.name = engine.getJSONArrayString(i, "ID", "");
        t.text = engine.getJSONArrayString(i, "text", "");
        t.fontSize = engine.getJSONArrayFloat(i, "size", 12.);
        t.textColor = engine.getJSONArrayInt(i, "color", color(255, 255, 255));
        placeableset.add(t);
        return t;
    }
    private ImagePlaceable readImagePlaceable(final int i) {
        ImagePlaceable im = new ImagePlaceable();
        im.sprite.xpos = (float)engine.getJSONArrayInt(i, "x", (int)WIDTH/2);
        im.sprite.ypos = (float)engine.getJSONArrayInt(i, "y", (int)HEIGHT/2);
        im.sprite.wi   = engine.getJSONArrayInt(i, "wi", 512);
        im.sprite.hi   = engine.getJSONArrayInt(i, "hi", 512);
        String imageName = engine.getJSONArrayString(i, "imgName", "");
        
        // If there's cache, don't bother decoding the base64 string.
        // Otherwise, read the base64 string, generate cache, read from that cache.
        
        Runnable loadFromEntry = new Runnable() {
          public void run() {
            // Decode the string of base64
            String encoded   = engine.getJSONArrayString(i, "png", "");
            
            // Png image data in json is missing
            if (encoded.length() == 0) {
              console.warn("while loading entry: png image data in json is missing.");
            }
            // Everything is found as expected.
            else {
              byte[] decodedBytes = Base64.getDecoder().decode(encoded.getBytes());
              
              PImage img = engine.saveCacheImageBytes(entryPath+"_"+str(i), decodedBytes);
              
              // An error occured, data may have been tampered with/corrupted.
              if (img == null) 
                console.warn("while loading entry: png image data is corrupted or cachepath is invalid.");
              else 
                engine.setOriginalImage(img);
            }
          }
        };
        
        im.setImage(engine.tryLoadImageCache(this.entryPath+"_"+str(i), loadFromEntry), imageName);
        
        
        placeableset.add(im);
        return im;
    }
    
    
    public boolean loading = false;
    public void readEntryJSONInSeperateThread() {
      loading = true;
      Thread t = new Thread(new Runnable() {
          public void run() {
              readEntryJSON();
          }
      });
      t.start();
    }
    
    protected boolean customCommands(String command) {
      if (command.equals("/editgui")) {
        gui.interactable = !gui.interactable;
        if (gui.interactable) console.log("GUI now interactable.");
        else  console.log("GUI is no longer interactable.");
        return true;
      }
      else return false;
    }


    //*****************************************************************
    //*********************GUI BUTTONS AND ACTIONS*********************
    //*****************************************************************

    public void runGUI() {
        ui.useSpriteSystem(gui);
        ui.spriteSystemClickable = !ui.miniMenuShown();

        
        if (!cameraMode) {
  
          // The lines nothin to see here
          gui.guiElement("line_1");
          gui.guiElement("line_2");
          gui.guiElement("line_3");
  
          app.noTint();
          app.textFont(engine.DEFAULT_FONT);
  
          //************BACK BUTTON************
          if (ui.button("back", "back_arrow_128", "Save & back")) {
               saveEntryJSON();
               if (engine.prevScreen instanceof Explorer) {
                 Explorer prevExplorerScreen = (Explorer)engine.prevScreen;
                 prevExplorerScreen.refreshDir();
               }
               
               // Remove all the images from this entry before we head back,
               // we don't wanna cause any memory leaks.
               
               // Update 25/09/23
               // ... where's the code? Hmmmmmmmmmmmm
               // Oh wait it's in the endAnimation function.
               // Bit misleading there, past me.
               
               previousScreen();
          }
  
          //************FONT COLOUR************
          if (ui.button("font_color", "fonts_128", "Colour")) {
              SpriteSystemPlaceholder.Sprite s = gui.getSprite("font_color");
              
              Runnable r = new Runnable() {
                public void run() {
                  // Set the color of the text placeable
                  if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                      TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                      selectedColor = ui.getPickedColor();
                      editingTextPlaceable.textColor = selectedColor;
                  }
                }
              };
              
              ui.colorPicker(s.xpos, s.ypos+100, r);
          }
  
          //************BIGGER FONT************
          if (ui.button("bigger_font", "bigger_text_128", "Bigger")) {
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  selectedFontSize = editingTextPlaceable.fontSize + 2;
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
              else {
                  selectedFontSize += 2;
              }
          }
  
          //************SMALLER FONT************
          if (ui.button("smaller_font", "smaller_text_128", "Smaller")) {
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  selectedFontSize = editingTextPlaceable.fontSize - 2;
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
              else {
                  selectedFontSize -= 2;
              }
  
              // Minimum font size
              if (selectedFontSize < MIN_FONT_SIZE) {
                  selectedFontSize = MIN_FONT_SIZE;
              }
          }
  
          //************FONT SIZE************
          
          // Sprite might not be loaded by the time we want to check for hovering
          // so suppress warnings so we don't get an ugly warning.
          // Nothing bad will happen other than that.
          gui.suppressSpriteWarning = true;
          SpriteSystemPlaceholder.Sprite s = gui.getSprite("font_size");
          // Draw text where the sprite is
          app.textAlign(CENTER, CENTER);
          app.textSize(20);
  
          // Added this line cus other elements caused the text size to gray.
          app.fill(255);
          // Bug fix: don't show the sprite on the first frame of the animation start
          // (showGUI is set later)
          if (showGUI)
            app.text(selectedFontSize, s.xpos+s.wi/2, s.ypos+s.hi/2);
  
          // The button code
          if (ui.button("font_size", "nothing", "Font size")) {
              if (editingPlaceable != null && editingPlaceable instanceof TextPlaceable) {
                  TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                  // Doesn't really do anything yet really.
                  editingTextPlaceable.fontSize = selectedFontSize;
              }
          }
  
          // Turn warnings back on.
          gui.suppressSpriteWarning = false;
          
          //************CAMERA************
          if (ui.button("camera", "camera_128", "Take photo")) {
            this.beginCamera();
          }
        }
        else {
          
          if (ui.button("camera_back", "back_arrow_128", "")) {
            this.endCamera();
          }
          
          if (!camera.error.get() && camera.ready.get()) {
            if (ui.button("snap", "snap_button_128", "")) {
              insertImage(camera.updateImage());
              
              // Rest of the stuff is just for cosmetic effects :sparkle_emoji:
              takePhoto = true;
              cameraFlashEffect = 255.;
            }
            
            // TODO: Add some automatic "position at bottom" function to the messy class.
            gui.getSprite("snap").setY(HEIGHT-myLowerBarWeight+20);
            
            if (ui.button("camera_flip", "flip_camera_128", "Switch camera")) {
              preparingCameraMessage = "Switching camera...";
              camera.switchNextCamera();
            }
            gui.getSprite("camera_flip").setY(HEIGHT-myLowerBarWeight+10);
          }
          
        }

        // We want to render the gui sprite system above the upper bar
        // so we do it here instead of content()
        gui.updateSpriteSystem();


    }
    
    public void beginCamera() {
      upperBarDrop = CAMERA_ON_ANIMATION;        // Set to 
      upperbarExpand = 1.;
      cameraMode = true;
      myBackgroundColor = color(0);
      
      // Because rendering cameraDisplay takes time on the first run, we should prompt the user
      // that the display is getting set up. I hate this so much.
      app.textFont(engine.DEFAULT_FONT);
      ui.loadingIcon(WIDTH/2, HEIGHT/2);
      fill(255);
      textSize(30);
      textAlign(CENTER, CENTER);
      text("Starting camera display...", WIDTH/2, HEIGHT/2+120);
      cameraDisplay.beginDraw();
      cameraDisplay.clear();
      cameraDisplay.endDraw();
      app.image(cameraDisplay, 0, 0, WIDTH, HEIGHT);
      
      // Start up the camera.
      Thread t = new Thread(new Runnable() {
          public void run() {
             camera.setup();
          }
      });
      t.start();
      preparingCameraMessage = "Starting camera...";
    }
    
    public void endCamera() {
      upperBarDrop = CAMERA_OFF_ANIMATION;
      upperbarExpand = 1.;
      cameraMode = false;
      camera.turnOffCamera();
      myBackgroundColor = BACKGROUND_COLOR;       // Restore original background color
      engine.sharedResources.set("lastusedcamera", camera.selectedCamera);
    }

    // New name without the following path.
    // TODO: safer to move instead of delete
    public void renameEntry(String newName) {
      File f = new File(entryPath);
      if (f.exists()) {
        if (!f.delete()) console.warn("Couldn't rename entry; old file couldn't be deleted.");
      }
      entryPath = entryDir+newName+"."+engine.ENTRY_EXTENSION;
      entryName = newName;
      saveEntryJSON();
    }

    // I don't think you'll really need to modify this code much.
    public void upperBar() {
        // The upper bar expand down animation when the screen loads.
        if (upperbarExpand > 0.001) {
            engine.power.setAwake();
            upperbarExpand *= PApplet.pow(0.8, display.getDelta());
            
            float newBarWeight = UPPER_BAR_DROP_WEIGHT;
            
            if (upperBarDrop == CAMERA_OFF_ANIMATION || upperBarDrop == INITIALISE_DROP_ANIMATION)
              myUpperBarWeight = UPPER_BAR_WEIGHT + newBarWeight - (newBarWeight * upperbarExpand);
            else myUpperBarWeight = UPPER_BAR_WEIGHT + (newBarWeight * upperbarExpand);
            
            
            
            if (upperbarExpand <= 0.001) power.setSleepy();
        }
        
        display.shader("fabric", "color",float((myUpperBarColor>>16)&0xFF)/255.,(float)((myUpperBarColor>>8)&0xFF)/255.,float((myUpperBarColor)&0xFF)/255.,1., "intensity",0.1);
        
        if (!ui.miniMenuShown() && !cameraMode) 
          display.clip(0, 0, WIDTH, myUpperBarWeight);
        super.upperBar();
        display.defaultShader();
        
        if (showGUI)
          runGUI();
        app.noClip();
    }
    
    public void lowerBar() {
      display.shader("fabric", "color",float((myUpperBarColor>>16)&0xFF)/255.,float((myUpperBarColor>>8)&0xFF)/255.,float((myUpperBarColor)&0xFF)/255.,1., "intensity",0.1);
      
      float LOWER_BAR_EXPAND = 100.;
      if (upperBarDrop == CAMERA_ON_ANIMATION) myLowerBarWeight = LOWER_BAR_WEIGHT+(LOWER_BAR_EXPAND * (1.-upperbarExpand));
      if (upperBarDrop == CAMERA_OFF_ANIMATION) myLowerBarWeight = LOWER_BAR_WEIGHT+(LOWER_BAR_EXPAND * (upperbarExpand));
      
      super.lowerBar();
      display.defaultShader();
    }
    
    public float insertedXpos = 10;
    public float insertedYpos = this.myUpperBarWeight;
    
    private void insertImage(PImage img) {
      // Because this could potentially take a while to load and cache into the Processing engine,
      // we should expect framerate drops here.
      engine.power.resetFPSSystem();
      
      // TODO: Check whether we have text or image in the clipboard.
      if (!ui.miniMenuShown()) {
        if (img == null) console.log("Can't paste image from clipboard!");
        else {
          // Resize the image if autoScaleDown is enabled for faster performance.
          if (autoScaleDown) {
            engine.scaleDown(img, SCALE_DOWN_SIZE);
          }
          
          ImagePlaceable imagePlaceable = new ImagePlaceable(img);
          if (editingPlaceable != null) {
            // Grab the position of the text that was there previously
            // so we can plonk an image in its place, but only if there was
            // no text to begin with.
            if (editingPlaceable instanceof TextPlaceable) {
              TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
              float xpos = editingPlaceable.sprite.xpos;
              float ypos = editingPlaceable.sprite.ypos;
              int hi = editingPlaceable.sprite.hi;
              
              if (editingTextPlaceable.text.length() == 0) {
                  placeableset.remove(editingPlaceable);
                  imagePlaceable.sprite.xpos = xpos;
                  imagePlaceable.sprite.ypos = ypos;
              }
              else {
                  imagePlaceable.sprite.xpos = xpos;
                  imagePlaceable.sprite.ypos = ypos+hi;
              }
            }
          }
          else {
            // If no text is being edited then place the image in the default location.
            imagePlaceable.sprite.xpos = insertedXpos;
            imagePlaceable.sprite.ypos = insertedYpos;
            insertedXpos += 20;
            insertedYpos += 20;
          }
          // Dont want our image stretched
          imagePlaceable.sprite.wi = img.width;
          imagePlaceable.sprite.hi = img.height;
          
          
          float aspect = float(img.height)/float(img.width);
          // If the image is too large, make it smaller quickly
          if (imagePlaceable.sprite.wi > WIDTH*0.5) {
            imagePlaceable.sprite.wi = int((WIDTH*0.5));
            imagePlaceable.sprite.hi = int((WIDTH*0.5)*aspect);
          }
          
          // Select the image we just pasted.
          editingPlaceable = imagePlaceable;
          changesMade = true;
        }
      }
    }
    
    private void insertText(String initText, float x, float y) {
        TextPlaceable editingTextPlaceable = new TextPlaceable();
        editingTextPlaceable.textColor = selectedColor;
        placeables.selectedSprite = editingTextPlaceable.sprite;
        editingTextPlaceable.sprite.xpos = x;
        editingTextPlaceable.sprite.ypos = y;
        editingPlaceable = editingTextPlaceable;
        engine.keyboardMessage = initText;
        engine.allowShowCommandPrompt = false;
    }
    
    private void renderEditor() {
      //yview += engine.scroll;
        // In order to know if we clicked on an object or a blank area,
        // this is what we do:
        // 1 Keep track of a click and do some stuff (like deleting a placeable object)
        // it it's empty
        // 2 Update all objects which will check if any of them have been clicked.
        // 3 If there's been a click from step 1 then check if any object has been clicked.
        boolean clickedThing = false;
        if (engine.leftClick) {
            if (engine.noMove) {
                clickedThing = true;
            }
        }

        // The part of the code that actually deselects an element when clicking in
        // a blank area.
        // However, we don't want to deselect text in the following:
        // 1. If the minimenu is open
        // 2. GUI element is clicked (we just check the mouse is in the upper bar
        // to check that condition)
        boolean mouseInUpperbar = engine.mouseY() < myUpperBarWeight;
        if (engine.pressDown) {
            if(!ui.miniMenuShown() && !mouseInUpperbar) {

                if (editingPlaceable != null) {
                  if (editingPlaceable instanceof TextPlaceable) {
                    TextPlaceable editingTextPlaceable = (TextPlaceable)editingPlaceable;
                    if (editingTextPlaceable.text.length() == 0) {
                        placeableset.remove(editingPlaceable);
                    }
                  }
                  // Rename the entry if we're clicking off the title text.
                  if (editingPlaceable == entryNameText) {
                    if (entryNameText.text.matches("^[a-zA-Z0-9_ ,\\-]+$()") && entryNameText.text.length() > 0) {
                      renameEntry(entryNameText.text);
                      console.log("Entry renamed!");
                    }
                    else {
                      console.log("Invalid characters in entry name!");
                      entryNameText.text = entryName;
                    }
                  }
                  
                  // Otherwise anything else should be deselected automatically.
                  editingPlaceable = null;
                  engine.allowShowCommandPrompt = true;
                  //saveEntryJSON();
                }

            }
        }
        
        if (engine.keyPressed && key == 3) { // Ctrl+c
          if (editingPlaceable != null) {
            if (editingPlaceable instanceof TextPlaceable) {
              TextPlaceable t = (TextPlaceable)editingPlaceable;
              boolean success = clipboard.copyString(t.text);
              if (success)
                console.log("Copied!");
            }
            else console.log("Copying of element not supported yet, sorry!");
          }
        }
        
        if (engine.keyPressed && key == 0x16) // Ctrl+v
        {
            // Timeout so that we don't immediately shrink our cpu canvas since a delay is expected.
            display.smallerCanvasTimeout = 10;
            
            if (clipboard.isImage()) {
              PImage pastedImage = clipboard.getImage();
              if (pastedImage == null) console.log("Can't paste image from clipboard!");
              else insertImage(pastedImage);
            }
            else if (clipboard.isString()) {
              String pastedString = clipboard.getText();
              
              if (editingPlaceable != null) {
                // If we're currently editing text, append it
                if (editingPlaceable instanceof TextPlaceable) {
                  engine.keyboardMessage += pastedString;
                }
                else if (editingPlaceable instanceof ImagePlaceable) {
                  // Place it just underneath the image.
                  float imx = editingPlaceable.sprite.xpos;
                  float imy = editingPlaceable.sprite.ypos;
                  int imhi = editingPlaceable.sprite.hi;
                  insertText(pastedString, imx, imy+imhi);
                }
              }
              // No text or image being edited, just plonk it whereever.
              else {
                insertedXpos += 20;
                insertedYpos += 20;
                insertText(pastedString, insertedXpos, insertedYpos);
              }
            }
            else console.log("Can't paste item from clipboard!");
        }
        
        
        if (engine.keyPressed && key == DELETE) {
          if (editingPlaceable != null) {
            placeableset.remove(editingPlaceable);
            changesMade = true;
          }
        }
        
        placeables.updateSpriteSystem();

        // Run all placeable objects
        for (Placeable p : placeableset) {
            p.update();
        }

        // Check back to see if something's been clicked.
        if (clickedThing) {

            // Create new text if a blank area has been clicked.
            // Clicking in a blank area will create new text
            // however, there's some exceptions to that rule
            // and the following conditions need to be met:
            // 1. There's no minimenu open
            // 2. There's no gui element being interacted with
            if (editingPlaceable == null && !ui.miniMenuShown() && !mouseInUpperbar) {
                insertText("", engine.mouseX(), engine.mouseY()-20);
            }
        }

        
        // Power stuff
        // If we're dragging a sprite, we want framerates to be smooth, so temporarily
        // set framerates higher while we're dragging around.
        if (placeables.selectedSprite != null) {
          if (placeables.selectedSprite.repositionDrag.isDragging() || placeables.selectedSprite.resizeDrag.isDragging()) {
            engine.power.setAwake();
            
            // While we're here, a sprite is being dragged which means changes to the file.
            changesMade = true;
          }
          else {
            engine.power.setSleepy();
          }
          
          // Just check for changes
          // Technically (as of now) just for images (text will never see this code)
          // but can also apply to any new future placeables in the future.
          if (placeables.selectedSprite.resizeDrag.isDragging()) {
            changesMade = true;
          }
        }
    }
    
    public String preparingCameraMessage = "Starting camera...";
    public boolean takePhoto = false;
    public float cameraFlashEffect = 0.;
    public void renderPhotoTaker() {
      app.textFont(engine.DEFAULT_FONT);
      if (!camera.ready.get()) {
        
        textAlign(CENTER, CENTER);
        textSize(30);
        if (camera.error.get() == true) {
          display.imgCentre("error", WIDTH/2, HEIGHT/2);
          String errorMessage = "";
          fill(255, 0, 0);
          switch (camera.errorCode.get()) {
            case ERR_UNKNOWN:
              errorMessage = "An unknown error has occured.";
            break;
            case ERR_NO_CAMERA_DEVICES:
              errorMessage = "No camera devices found.";
            break;
            case ERR_FAILED_TO_SWITCH:
              errorMessage = "A weird error occured with switching cameras.";
            break;
            case ERR_UNSUPPORTED_SYSTEM:
              errorMessage = "Camera is unsupported on your system, sorry :(";
            break;
            default:
              errorMessage = "An unknown error has occured.";
              console.bugWarn("renderPhotoTaker: Unused error code.");
            break;
          }
          text(errorMessage, WIDTH/2, HEIGHT/2+120);
        }
        else {
          ui.loadingIcon(WIDTH/2, HEIGHT/2);
          fill(255);
          text("Starting camera...", WIDTH/2, HEIGHT/2+120);
        }
      }
      else {
        PImage pic = camera.updateImage();
        if (pic != null && pic.width > 0 && pic.height > 0) {
          
          float aspect = float(pic.height)/float(pic.width);
          cameraDisplay.beginDraw();
          cameraDisplay.image(pic, 0, 0, float(cameraDisplay.width), float(cameraDisplay.width)*aspect);
          cameraDisplay.endDraw();
          app.image(cameraDisplay, 0, 0, WIDTH, HEIGHT);
          if (takePhoto) {
            app.blendMode(ADD);
            app.noStroke();
            app.fill(cameraFlashEffect);
            app.rect(0,0, WIDTH, HEIGHT);
            app.blendMode(NORMAL);
            cameraFlashEffect -= 20.*display.getDelta();
            if (cameraFlashEffect < 10.) {
              takePhoto = false;
              this.endCamera();
            }
          }
        }
        //engine.timestamp("start image");
        //app.beginShape();
        //engine.timestamp("texture");
        //app.texture(pic);
        //engine.timestamp("verticies");
        //app.vertex(x1, y1, 0, 0);           // Bottom left
        //app.vertex(x2,     y1, 1., 0);    // Bottom right
        //app.vertex(x2,     y2, 1., 1.); // Top right
        //app.vertex(x1,       y2, 0, 1.);  // Top left
        //app.endShape();
        //engine.timestamp("end image");
      }
    }
    
    public void display() {
      if (engine.power.getPowerMode() != PowerMode.MINIMAL) {
        app.pushMatrix();
        app.translate(screenx,screeny);
        app.scale(display.getScale());
        this.backg();
        
        this.content();
        this.lowerBar();
        this.upperBar();
        app.popMatrix();
      }
    }

    public void content() {
      if (loading) {
        ui.loadingIcon(WIDTH/2, HEIGHT/2);
      }
      else {
        if (cameraMode) {
          renderPhotoTaker();
        }
        else {
          // We pretty much just render all of the placeables here.
          renderEditor();
        }
      }
    }

    public void startupAnimation() {
        // As soon as the window finishes sliding in, roll down the upper bar.
        // Beautiful animation :twinkle_emoji:
        upperBarDrop = INITIALISE_DROP_ANIMATION;
        upperbarExpand = 1.0;
        showGUI = true;
    }
    
    public void endScreenAnimation() {
       // Clear the images from systemimages to clear up used images.
       for (String s : imagesInEntry) {
         display.systemImages.remove(s);
       }
       
       engine.allowShowCommandPrompt = true;
    }

    
}
