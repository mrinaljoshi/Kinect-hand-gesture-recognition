// Daniel Shiffman
// Tracking the average location beyond a given depth threshold
// Thanks to Dan O'Sullivan

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

class KinectTracker {

  // Depth threshold
  int threshold = 800;

  // Raw location
  PVector loc;

  // Interpolated location
  PVector lerpedLoc;
  PVector highestPoint;
  
  // Depth data
  int[] depth;

  // What we'll show the user
  PImage display;
  
  //Kinect2 class
  Kinect2 kinect2;
  
  
  KinectTracker(PApplet pa) {
    
    //enable Kinect2
    kinect2 = new Kinect2(pa);
    kinect2.initDepth();
    kinect2.initVideo();
    kinect2.initRegistered();
    kinect2.initDevice();
   
    // Make a blank image
    display = createImage(kinect2.depthWidth, kinect2.depthHeight, RGB);
    
    // Set up the vectors
    loc = new PVector(0, 0);
    lerpedLoc = new PVector(0, 0);
  }

  void track() {
    // Get the raw depth as array of integers
    depth = kinect2.getRawDepth();

    // Being overly cautious here
    if (depth == null) return;

    float sumX = 0;
    float sumY = 0;
    float count = 0;
    int min_x = 0;
    int min_y = kinect2.depthHeight;
    for (int x = 0; x < kinect2.depthWidth; x++) {
      for (int y = 0; y < kinect2.depthHeight; y++) {
        // Mirroring the image
        int offset = kinect2.depthWidth - x - 1 + y * kinect2.depthWidth;
        // Grabbing the raw depth
        int rawDepth = depth[offset];

        // Testing against threshold
        if (rawDepth > 0 && rawDepth < threshold) {
          sumX += x;
          sumY += y;
          count++;
          if(min_y > y){ 
            min_y = y;
            min_x = x;
        }
      }
    }
   }
     
    // As long as we found something
    if (count != 0) {
      loc = new PVector(sumX/count, sumY/count);
    }
    
    // Interpolating the location, doing it arbitrarily for now
    lerpedLoc.x = PApplet.lerp(lerpedLoc.x, loc.x, 0.3f);
    lerpedLoc.y = PApplet.lerp(lerpedLoc.y, loc.y, 0.3f);
    
    highestPoint = new PVector(min_x, min_y);
    
  }



  PVector getLerpedPos() {
    return lerpedLoc;
  }

  PVector getPos() {
    return loc;
  }
  
  PVector gethighestPoint() {
    return highestPoint;
  }

  int centerDepth(){
    PVector v1 = getPos();
    int offset = kinect2.depthWidth - (int)v1.x - 1 + (int)v1.y * kinect2.depthWidth;
    return depth[offset];
  }
  void display() {
    PImage img = kinect2.getDepthImage();
    
    //PImage img_color = kinect2.getRegisteredImage();

    // Being overly cautious here
    if (depth == null || img == null) return;

    // Going to rewrite the depth image to show which pixels are in threshold
    // A lot of this is redundant, but this is just for demonstration purposes 
    display.loadPixels();
    for (int x = 0; x < kinect2.depthWidth; x++) {
      for (int y = 0; y < kinect2.depthHeight; y++) {
        // mirroring image
        int offset = (kinect2.depthWidth - x - 1) + y * kinect2.depthWidth;
        // Raw depth
        int rawDepth = depth[offset];
        int pix = x + y*display.width;
        if (rawDepth > 0 && rawDepth < threshold) {
          // A white color instead
          //display.pixels[pix] = 0;
          display.pixels[pix] = color(255, 255, 255);
        } else {
          //display.pixels[pix] = color(255, 255, 255);
          display.pixels[pix] =  color(0, 0, 0);
        }
      }
    }
    display.updatePixels();

    // Draw the image
    image(display, 0, 0);
    //image(img_color, 0, 0);
// ================opencv part
//    src = display;
//    image(src, 0, 0);
//    opencv.gray();
//    opencv.threshold(70);
//    ArrayList<Contour> contours;
//    contours = opencv.findContours();
//    println("found " + contours.size() + " contours");   
  }
  
  

  int[] getPixel(){
    int[] rDepth = new int[depth.length];
    int count = 0;
    for (int x = 0; x < kinect2.depthWidth; x++) {
      for (int y = 0; y < kinect2.depthHeight; y++) {
        // Mirroring the image
        int offset = kinect2.depthWidth - x - 1 + y * kinect2.depthWidth;
        // Grabbing the raw depth
        rDepth[x + y*kinect2.depthWidth] = depth[offset];
      }
    }
    return rDepth;
  }
  int getThreshold() {
    return threshold;
  }

  void setThreshold(int t) {
    threshold =  t;
  }
}