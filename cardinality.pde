import damkjer.ocd.*;
import controlP5.*;
import ketai.sensors.*;
import android.view.WindowManager;
import android.view.View;
import android.os.Bundle;

KetaiSensor sensor;
KetaiLocation location;
PVector rotation;
PVector protation;
PVector[] rotations;
PVector magneticField;
PVector[][] origins;
Camera cam;
ControlP5 cp5;
int gridSize = 20;
int scale = 1000;
int time;
double lat;
double lon;
float clon;
float clat;
float yscale = 500;
Textlabel coords;
Textlabel title;
PFont robotolite;
PFont robotobold;
boolean pre;
float compRot;
float totalx, totaly, averagex, averagey, paveragex, paveragey;
int index;
boolean setup;
int sample = 5;


void setup(){
  size(displayWidth, displayHeight, P3D);
  orientation(PORTRAIT);
  setup = false;
  totalx = 0;
  totaly = 0;
  averagex = 0;
  paveragex = 0;
  paveragey = 0;
  averagey = 0;
  index = 0;
  pre = true;
  cp5 = new ControlP5(this);
  robotolite = createFont("Roboto-Thin.ttf", displayHeight/40, true);
  robotobold = createFont("Roboto-MediumItalic.ttf", displayHeight/26.6667, true);
  rotation = new PVector(0,0,0);
  protation = new PVector(0,0,0);
  rotations = new PVector[sample];
  for(int k = 0; k < sample; k++){
   rotations[k] = new PVector(0,0,0); 
  }
  magneticField = new PVector();
  sensor = new KetaiSensor(this);
  sensor.start();
  textSize(20);
  noiseSeed(1);
  //strokeWeight(3);
  time = 0;
  noiseDetail(1);
  colorMode(HSB, 255, 255, 255, 255);
  
  origins = new PVector[gridSize][gridSize];
  for(int i = 0; i < gridSize; i++){
    for (int j = 0; j < gridSize; j++){
     origins[i][j] = new PVector(i*scale, 0 , j*scale);
    }
  }
  cam = new Camera(this, 0.0, -400.0, 0.0, (origins[gridSize/2][gridSize/2].x), -400, -(origins[gridSize/2][gridSize/2].z)+1, 0.0, -1.0, 0.0,
  1, 10000);
  location = new KetaiLocation(this);
  title = cp5.addTextlabel("title")
  .setText("Cardinality of Singular Place")
  .setPosition(64, displayHeight/2)
  .setColorValue(0x000000)
  .setFont(robotobold)
  .setVisible(true);
  
  coords = cp5.addTextlabel("label")
  .setText("\n" + "Hold Screen Orthogonally to the Ground" + "\n" + "and Touch to Begin")
  .setPosition(64, displayHeight/2 + 32)
  .setColorValue(0x000000)
  .setFont(robotolite);
}

void onCreate(Bundle bundle) 
{
  super.onCreate(bundle);
  // fix so screen doesn't go to sleep when app is active
  getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
}

void draw(){
  if(pre){
    background(0,0,255);
    camera();
  }
  else if(!pre){
    if (location.getProvider() == "none"){
      text("I don't know where you are." + "\n" + "Check your location settings.", 0, 0, width, height);
    }
    else{
      hint(ENABLE_DEPTH_TEST);

      
      background(clon,clat/3.0,127);  
      if(abs(rotation.x - protation.x) < 300.0 && abs(rotation.y - protation.y) < 300){
          if(index == 0){
          totalx = totalx - rotations[sample-1].x;
          totaly = totaly - rotations[sample-1].y;
          }else{
          totalx = totalx - rotations[index-1].x;
          totaly = totaly - rotations[index-1].y;
          }
          index += 1;
          if (index >= sample){
           index = 0;
           if(!setup){
            setup = true;
           } 
          }
          rotations[index].x = rotation.x;
          rotations[index].y = rotation.y;
          totalx += rotations[index].x;
          totaly += rotations[index].y;
          paveragex = averagex;
          paveragey = averagey;
          averagex = totalx/sample;
          averagey = totaly/sample;
          if(abs(averagex - paveragex) > 10){
            print("average - paverage" + (averagex - paveragex));
            float rotationcap = (-(averagex-paveragex)/abs(averagex-paveragex)*2);
            if(setup)cam.look(radians(rotationcap)*2, radians((averagey - paveragey)));
          }else{
            if(setup)cam.look(radians((averagex - paveragex))*2, radians((averagey - paveragey)));
          }
        }
        cam.feed();
      
      pushMatrix();
      
      rotateY(compRot);
      translate(-(origins[gridSize/2][gridSize/2].x), 0, -(origins[gridSize/2][gridSize/2].z));
      
      for(int i = 0; i < gridSize; i++){
        for(int j = 0; j < gridSize; j++){
          
         float rowoff = (float)(i + lon);
         float coloff = (float)(j + lat); 
         drawLine(origins[i][j].x, origins[i][j].y, origins[i][j].z, rowoff, coloff);
         drawLineAlt(origins[i][j].x, origins[i][j].y, origins[i][j].z, rowoff, coloff);
        }
      }
      popMatrix();
      hint(DISABLE_DEPTH_TEST);
    }
    camera();
  }
}

void onOrientationEvent(float x, float y, float z){
   protation.x = rotation.x;
   protation.y = rotation.y;
   protation.z = rotation.z;
   rotation.x = x;
   rotation.y = y;
   rotation.z = z;
}

void drawLine(float _x, float _y, float _z, float row, float col){
  float x = _x;
  float y = map(noise(row, col), 0.0, 1.0, -yscale, yscale) + _y;
  float z = _z;
  float off = 0.2;
  beginShape(LINES); 
  for(int it = 0; it < 5; it++){
    vertex(x, y, z);
    row += off;
    y = map(noise(row, col), 0.0, 1.0, -yscale, yscale) + _y;
    x += scale/5;
    float cy = map(y, yscale, -yscale, 0.0, 255.0);
    stroke(clon, clat, cy);
    vertex(x, y, z);
  }
  endShape();
}

void drawLineAlt(float _x, float _y, float _z, float row, float col){
  float x = _x;
  float y = map(noise(row, col), 0.0, 1.0, -yscale, yscale) + _y;
  float z = _z;
  float off = 0.2;
  
  beginShape(LINES); 
  for(int it = 0; it < 5; it++){
    vertex(x, y, z);
    col += off;
    y = map(noise(row, col), 0.0, 1.0, -yscale, yscale) + _y;
    z += scale/5;
    float cy = map(y, yscale, -yscale, 0.0, 255.0);
    stroke(clon, clat, cy);
    vertex(x, y, z);
  }
  endShape();
}

void stop(){
 sensor.stop(); 
}

void mouseReleased(){
  if(pre){
    pre = false;
    title.setVisible(false);
    coords
    .setText((float)lat + "\n" + (float)lon + "\n" + magneticField.x + " " + magneticField.y + " " + magneticField.z)
    .setPosition(64, displayHeight - 128)
    .setColorValue(0xffffffff)
    .setFont(robotolite);
    cam.aim((origins[gridSize/2][gridSize/2].x), -400, -(origins[gridSize/2][gridSize/2].z)+1);

  }
  else if(!pre){
    pre = true;
    title.setVisible(true);
    coords
    .setText("\n" + "Hold Screen Orthogonally to the Ground" + "\n" + "and Touch to Begin")
    .setPosition(64, displayHeight/2 + 32)
    .setColorValue(0x000000)
    .setFont(robotolite);
  }
}

void onLocationEvent(double _latitude, double _longitude, double _altitude){
  lon = _longitude;
  lat = _latitude;
  clon = map((float)lon, -180.0, 180.0, 0.0, 255.0);
  clat = map((float)lat, -90.0, 90.0, 0.0, 255.0);
  if(!pre)coords.setText((float)lat + "\n" + (float)lon + "\n" + magneticField.x + " " + magneticField.y + " " + magneticField.z);
}

void onMagneticFieldEvent(float x, float y, float z, long time, int accuracy)
{
  float _x = floor(x);
  float _y = floor(y);
  float _z = floor(z);
  magneticField.set(_x, _y, _z);
  if(pre){
    compRot = atan2(map(x, -31.5, 31.5, -1.0, 1.0), map(z, -31.5, 31.5, -1.0, 1.0));
  }
  if(!pre)coords.setText((float)lat + "\n" + (float)lon + "\n" + magneticField.x + " " + magneticField.y + " " + magneticField.z);
}
