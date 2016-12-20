// Daniel Shiffman and Thomas Sanchez Lengeling
// Tracking the average location beyond a given depth threshold
// Thanks to Dan O'Sullivan

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

import org.openkinect.processing.*;
import de.voidplus.dollar.*;

import gab.opencv.*;
import fingertracker.*;
import java.util.*;

// The kinect stuff is happening in another class
KinectTracker tracker;
//OpenCV opencv;
FingerTracker fingers;
Calculator cal;

boolean globel;
int finger_threshold;
boolean finger_display;
boolean write_buff; 
PVector center;
PVector highestPt;
PVector highestPt_prev;
boolean detectGesture;
boolean printNumber = false;
int threshold_start;
boolean checkHighestPt = false;
boolean isNumber = true;
boolean maybedetectGesture;
boolean ready_to_calculate = false;
boolean isGesture = false;
int frames = 0;
String figure;
String result = "";
PImage src;
int N = 100;
int[] buffer = new int[N];
int[] midBuff = new int[2];
String expression = "";
ArrayList<Integer> val_array = new ArrayList<Integer>();
ArrayList<String> op_array = new ArrayList<String>();
int prev;
OneDollar one;
String name = "hello";
boolean write_to_string;


class Calculator{
  private Stack<Integer> values;
  private Stack<Character> ops;
  private String expression;

  public Calculator(){
    this.values = new Stack<Integer>();
    this.ops = new Stack<Character>();
  }
  public void read(String exp){
    this.expression = exp;
  }
  
  int evaluate(){
      char[] tokens = expression.toCharArray();
        for (int i = 0; i < tokens.length; i++)
        {
            // Current token is a number, push it to stack for numbers
            if (tokens[i] >= '1' && tokens[i] <= '9')
            {   
                values.push(tokens[i] - '0');
            }
 
            // Current token is an operator.
            else if (tokens[i] == '+' || tokens[i] == '-' ||
                     tokens[i] == '*' || tokens[i] == '/')
            {
                // While top of 'ops' has same or greater precedence to current
                // token, which is an operator. Apply operator on top of 'ops'
                // to top two elements in values stack
                while (!ops.empty() && hasPrecedence(tokens[i], ops.peek()))
                  values.push(applyOp(ops.pop(), values.pop(), values.pop()));
                // Push current token to 'ops'.
                ops.push(tokens[i]);
            }
        }
        // Entire expression has been parsed at this point, apply remaining
        // ops to remaining values
        while (!ops.empty())
            values.push(applyOp(ops.pop(), values.pop(), values.pop()));
 
        // Top of 'values' contains result, return it
        return values.pop();
    }
 
    // Returns true if 'op2' has higher or same precedence as 'op1',
    // otherwise returns false.
    public  boolean hasPrecedence(char op1, char op2)
    {
        if ((op1 == '*' || op1 == '/') && (op2 == '+' || op2 == '-'))
            return false;
        else
            return true;
    }
 
    // A utility method to apply an operator 'op' on operands 'a' 
    // and 'b'. Return the result.
    public  int applyOp(char op, int b, int a)
    {
        switch (op)
        {
        case '+':
            return a + b;
        case '-':
            return a - b;
        case '*':
            return a * b;
        case '/':
            if (b == 0)
                throw new
                UnsupportedOperationException("Cannot divide by zero");
            return a / b;
        }
        return 0;
    }
}

void setup() {
  size(640, 520);
  // oneDollar
  one = new OneDollar(this);
  cal = new Calculator();
  one.setVerbose(true);          // Activate console verbose
  // 2. Add gestures (templates):
  one.learn("triangle", new int[] {137,139,135,141,133,144,132,146,130,149,128,151,126,155,123,160,120,166,116,171,112,177,107,183,102,188,100,191,95,195,90,199,86,203,82,206,80,209,75,213,73,213,70,216,67,219,64,221,61,223,60,225,62,226,65,225,67,226,74,226,77,227,85,229,91,230,99,231,108,232,116,233,125,233,134,234,145,233,153,232,160,233,170,234,177,235,179,236,186,237,193,238,198,239,200,237,202,239,204,238,206,234,205,230,202,222,197,216,192,207,186,198,179,189,174,183,170,178,164,171,161,168,154,160,148,155,143,150,138,148,136,148} );
  one.learn("circle", new int[] {127,141,124,140,120,139,118,139,116,139,111,140,109,141,104,144,100,147,96,152,93,157,90,163,87,169,85,175,83,181,82,190,82,195,83,200,84,205,88,213,91,216,96,219,103,222,108,224,111,224,120,224,133,223,142,222,152,218,160,214,167,210,173,204,178,198,179,196,182,188,182,177,178,167,170,150,163,138,152,130,143,129,140,131,129,136,126,139} ); 
  one.learn("circler", new int[] {126, 139, 129, 136, 140, 131, 143, 129, 152, 130, 163, 138, 170, 150, 178, 167, 182, 177, 182, 188, 179, 196, 178, 198, 173, 204, 167, 210, 160, 214, 152, 218, 142, 222, 133, 223,120, 224, 111, 224, 108, 224, 103, 222, 96, 219, 91,216,88,213,84,205,83,200,82,195,82,190,83,181,85,175,87,169,90,163,93,157,96,152,100,147,104,144,109,141,111,140,116,139,118,139,120,139,124,140,127,141} ); 
  one.learn("triangler", new int[] {136,148,138,148,143,150,148,155,154,160,161,168,164,171,170,178,174,183,179,189,186,198,192,207,197,216,202,222,205,230,206,234,204,238,202,239,200,237,198,239,193,238,186,237,179,236,177,235,170,234,160,233,153,232,145,233,134,234,125,233,116,233,108,232,99,231,91,230,85,229,77,227,74,226,67,226,65,225,62,226,60,225,61,223,64,221,67,219,70,216,73,213,75,213,80,209,82,206,86,203,90,199,95,195,100,191,102,188,107,183,112,177,116,171,120,166,123,160,126,155,128,151,130,149,132,146,133,144,135,141,137,139});
  one.learn("line",new int[] {3,3,6,6,9,9,12,12,15,15,18,18,21,21,24,24,27,27,30,30,33,33,36,36,39,39,42,42,45,45,48,48,51,51,54,54,57,57,60,60,63,63,66,66,69,69,72,72,75,75,78,78,81,81});  // 3. Bind templates to methods (callbacks):
  one.bind("triangle circle circler triangler", "detected");

  
  //tracker
  tracker = new KinectTracker(this);
  fingers = new FingerTracker(this, 512, 424);
  fingers.setMeltFactor(100);
  finger_display = false;
  
  threshold_start = 650; 
  println("Setup finish! ");
  
}

void draw() {
  text("please move your hands to the kinect", 30,100);
  if(finger_display){
    text("Game is On", 30, 110);
  }
  frames++;
  background(255);
  // Run the tracking analysis
  tracker.track();
  // Show the image
  tracker.display();
  fingers.setThreshold(800);
  int[] depthMap = tracker.getPixel();

  fingers.update(depthMap);
  // detect the center and its depth;
  int centerDis = tracker.centerDepth();  
  
  if(centerDis != 0 && centerDis < 800){
    finger_display = true;
  } else {
    finger_display = false;
    globel = true;
    centerDis = 0;
    maybedetectGesture = false;
  }

  textSize(15);

  if(globel){
    text("result:" + result, width - 200, height - 20);
  }
  // Let's draw the raw location
  center = tracker.getPos();
  fill(50, 100, 250, 200);
  noStroke();
  ellipse(center.x, center.y, 10, 10);
  int t = tracker.getThreshold();
  fill(0);
  text("the current expression is " + expression, 30, height - 20);
  //text("figure: " + figure, width - 200, height - 80 );
  //text("detect finger: centerDis " + centerDfis, 40, 300);
//  text("threshold: " + t + "    " +  "framerate: " + int(frameRate) + "    " +
//    "UP increase threshold, DOWN decrease threshold", 10, 500);   
  //text("Detected gesture: "+ figure, 30, 40);   
  //text("Draw anticlockwise a circle or triangle.", 30, height-30);
  if(maybedetectGesture == true ){
    text("hold one finger straight", 30, height -120);
    text("clockwise_circle: +; reverse_counter_circle: *", 30, height - 80);
    text("clockwise_triangle: -; reverse_counter_triangle: /", 30, height -60);
    
  }
  
  if(finger_display == false){
    maybedetectGesture = false;
    text("please move your hands to the kinect", 30,100);
    if(expression.length() != 0){
      cal.read(expression);
      //text("expression evaluation: " + cal.evaluate() , 70, height - 45);
      result = String.valueOf(cal.evaluate());
    } else {
      expression = "";
    }
    
  }
  if(write_to_string == true){
    //text("open to push to string", 30,170);
  } else {
    //text("not open to push to string", 30,150);
  }
  
  
  if(finger_display){ 
     //text("Game is on", 30,90);
    // iterate over all the contours found
    // and display each of them with a green line
    stroke(0,255,0);
    for (int k = 0; k < fingers.getNumContours(); k++) {
      fingers.drawContour(k);
    }
    // iterate over all the fingers found
    // and draw them as a red circle
    noStroke();
    fill(255,0,0);
    int fingercount = 0;
    for (int i = 0; i < fingers.getNumFingers(); i++) {
      PVector position = fingers.getFinger(i);
      if(position.y < center.y){
        ellipse(position.x-5, position.y-5, 10, 10);
        fingercount++;
      }  
    }
    println("frame: " + frames + "    Really      finger numbers: " + fingercount);
    
    buffer[frames % N] = fingercount;
    
    if(printNumber){
      text("do you mean: " + prev + " give fist to confirm", 30, 120);
    }
    
    if(frames % N == 0){
      //text("For each " + N + " frames expression " + expression + "======================================");
      
      int mode = getModeFromBuff();  
      if(mode != 0 && isNumber == true){
         
        println("we are now detecting the number!!!!!!!!!!!!!!!!!!!!!!!!");
        prev = mode;
        isGesture = true;
        printNumber = true;
        write_to_string = false;
      }
      if(mode == 0 && isGesture == true){
        //text("we are now detecting gesture?????????????????????????");
        printNumber = false;
        if(write_to_string == false){
          expression += String.valueOf(prev);
          write_to_string = true;
        }
        
        isNumber = false;
        maybedetectGesture = true;
      }
      
      if(mode == 1 && isNumber == false && isGesture == true){
        detectGesture = true;
      }
    }
    if(detectGesture){
      text("Start to draw!!!!" , 300, 200);
      maybedetectGesture = false;
       println("we are ACTUALLY now detecting gesture?????????????????????????");
       if(tracker.gethighestPoint().y < 520 * 0.9 && tracker.gethighestPoint().y > 520 * 0.1 && tracker.gethighestPoint().x < 460 * 0.9 && tracker.gethighestPoint().x > 460 * 0.1 ){
         one.track(tracker.gethighestPoint().x, tracker.gethighestPoint().y);
         ellipse(tracker.gethighestPoint().x, tracker.gethighestPoint().y, 10, 10);
         highestPt_prev = tracker.gethighestPoint();
        } 
    }
    
     if(name != "hello"){
        println("Finalllllllyyy we detected a gesture: " + name);
        if(name == "circle"){
          expression += "+";
        }
        if(name == "triangle"){
          expression += "-";
        }
        if(name == "circler"){
          expression += "*";
        }
        if(name == "triangler"){
          expression += "/";
        }
        text("Detected expression: "+ name, 10, 300); 
        isNumber = true;
        isGesture = false;
        detectGesture = false;
        figure = name;
        name = "hello";
     } 
}

  // Display some info
   // Optional draw:
  one.draw();


}
void detected(String gesture, float percent, int startX, int startY, int centroidX, int centroidY, int endX, int endY){
  println("Gesture: "+gesture+", "+startX+"/"+startY+", "+centroidX+"/"+centroidY+", "+endX+"/"+endY);    
  name = gesture;
}
// Adjust the threshold with key presses
void keyPressed() {
  int t = tracker.getThreshold();
  if (key == CODED) {
    if (keyCode == UP) {
      t +=5;
      tracker.setThreshold(t);
    } else if (keyCode == DOWN) {
      t -=5;
      tracker.setThreshold(t);
    }
  }
}


int getModeFromBuff() {
    int maxValue = 0, maxCount = 0;
    for (int i = 0; i < buffer.length; ++i) {
        int count = 0;
        for (int j = 0; j < buffer.length; ++j) {
            if (buffer[j] == buffer[i]) ++count;
        }
        if (count > maxCount) {
            maxCount = count;
            maxValue = buffer[i];
        }
    }
    return maxValue;
}
