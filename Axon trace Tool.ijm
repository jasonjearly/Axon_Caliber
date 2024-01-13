//200310 - Changed findNearest to actually return NaN in event of no nearest max/min.
var lineWidth = 10;
var threshold = 100;
var level = 20;
var choice = "Maxima";

macro "Axon Trace Tool - C111L00f0L01e1CfffDf1C111L02d2CfffLe2f2C111L03b3CfffLc3f3C111L04a4CfffLb4d4C111Le4f4L0585CfffL95c5C111Ld5f5L0676CfffL86b6C111Lc6f6L0757CfffL6797C111La7f7L0848CfffL5888C111L98f8L0939CfffL4959C111L69f9L0a2aCfffL3a4aC111L5afaL0b1bCfffL2b4bC111L5bfbL0c1cCfffL2c4cC111L5cfcD0dCfffL1d4dC111L5dfdD0eCfffL1e3eC111L4efeCfffL0f3fC111L4fff"{
setBatchMode(true);
//if(roiManager("count")==0) roiManager("reset");
if(nImages==0) exit("No images are open.");
tool = toolID();
//setBatchMode("show");
//setTool(7);
run("Select None");
setOption("DisablePopupMenu", true);
clicked=false;
alternate = false;
while(clicked==false&&toolID()==tool){
  getCursorLoc(xTemp, yTemp, zTemp, flags);
  if(flags==16) clicked=true;
  if(flags==24){ // Is alt clicked? (16 = ctrl)
  	clicked=true;
  	alternate = true;
  }
}
setOption("DisablePopupMenu", false);
ID = "";
ID = getImageID();
selectImage(ID);
getDimensions(topWidth, topHeight, channels, topSlices, topFrames);
run("Duplicate...", "duplicate");
if(alternate==true) run("Subtract Background...", "rolling=10 create");
tempID = getImageID();
xPoints = newArray(topWidth);
yPoints = newArray(topWidth);
last = yTemp;
  for(i=0; i<topWidth; i++){
    makeLine(i,0,i,topHeight);
    profile = getProfile();
    if(matches(choice, "Minima")) minima = Array.findMinima(profile, threshold);
    else minima = Array.findMaxima(profile, threshold);
    min = findNearest(minima, last);
    temp = "Pixel "+i+":  "+last+"  "+min+"  ";
    xPoints[i] = i;
    if(matches(min, NaN)==false){
      yPoints[i] = min;
      last = min;
  //    for(n=0;n<minima.length;n++){
  //      temp = temp+minima[n]+" ";
  //    else min = minima[1];
//      makePoint(i, min);
//      tempName = "Maxima at x = "+i;
//      Roi.setName(tempName);
//      roiManager("Add");
//      run("Select None");
    }
    else yPoints[i] = last;
  }
//  makeSelection("line", xPoints, yPoints);
  yNew = smoothLine(xPoints, yPoints, level);
  selectImage(tempID);
  close();
  selectImage(ID);
  makeSelection("line", xPoints, yNew);
  traceNumber = IJ.pad((countROIs("Axon-Trace:")+1),4);
  tempName = "Axon-Trace:"+traceNumber;
//  Roi.setName(tempName);
//  roiManager("Add");
  setOption("Show All", false);
//  roiManager("deselect");
//  run("Select None");
  setTool(tool);
  setBatchMode(false);
}

function findNearest(array, point){
  nearest=99999999;
  for(i=0, min=99999999; i<array.length; i++){
    temp = point-array[i];
    if(temp<0) temp = temp*-1;
    if(temp<min){
      nearest = i;
      min = temp;
    }
  }
  if(nearest==99999999) return NaN;
  return array[nearest];
}

function smoothLine(x, y, level){
  yOut = newArray(y.length);
  for(i=0;i<x.length; i++){
    top = i+level;
    if(top>=x.length-1) top = x.length-1;
    bottom = i-level;
    if(bottom<0) bottom = 0;
    xIn = Array.slice(x,bottom,top);
    yIn = Array.slice(y,bottom,top);
    form = getBestFitStraightLine(xIn, yIn);
    yOut[i] = (form[0]*x[i])+form[1];
    if(matches(yOut[i], NaN)) yOut[i]=y[i];
  }
  return yOut;
}

//http://www.neoprogrammics.com/linear_least_squares_regression/index.php
//Need to add in checks for horizontal or vertical lines.
function getBestFitStraightLine(x,y){
  sumX = 0;
  sumX2 = 0;
  sumY = 0;
  sumY2 = 0;
  sumXY = 0;
  for(i=0;i<x.length;i++){
    sumX = sumX+x[i];
    sumY = sumY+y[i];
    sumX2 = sumX2+(x[i]*x[i]);
    sumY2 = sumY2+(y[i]*y[i]);
    sumXY = sumXY+(x[i]*y[i]);
  }
  n = x.length;
  m = ((n*sumXY)-(sumX*sumY))/((n*sumX2)-(sumX*sumX));
  c = ((sumY*sumX2)-(sumX*sumXY))/((n*sumX2)-(sumX*sumX));
  verX = NaN;
  return newArray(m,c,verX);
}

function countROIs(prefix){
  roiTot = roiManager("count");
  for(i=0, t=0; i<roiTot; i++){
    roiManager("select", i);
    if(startsWith(Roi.getName, prefix)) t++;
  }
  return t;
}

macro "Axon Trace Tool Options" {
  title = "Axon Trace Options";
  Dialog.create(title);
  Dialog.addNumber("Line width used to sample axons", 10);
  Dialog.addNumber("Threshold for identifying axons", 100);
  Dialog.addNumber("Line smoothing (2 or more)", 20);
//  lineWidth = getNumber("Line width used to sample axons", 10);
//  threshold = getNumber("Threshold for identifying axons", 100);
//  level = getNumber("Line smoothing (2 or more)", 20);
  Dialog.addRadioButtonGroup("Trace minima or maxima?", newArray("Minima", "Maxima"), 1,2,"Maxima");
  Dialog.show();
  lineWidth = Dialog.getNumber();
  threshold = Dialog.getNumber();
  level = Dialog.getNumber();
  choice = Dialog.getRadioButton();
}