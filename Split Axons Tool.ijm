//200310 - Changed findNearest to actually return NaN in even of no nearest max/min.

var lineWidth = 10;
var minimaThreshold = 100;
var keepStacks = false;
var keepOriginal = true;

macro "Split Axons Tool - CfffLb0d0Lb1d1La2c2L93b3Le3f3L84f4L75f5L66c6L47a7L1878L0969L0a5aD0bL3b4bL3c4cL3d4dL3e4eL3f4f" {
setBatchMode(true);
setBatchMode("hide");
originalID = getImageID();
imageTitle = getTitle();
getVoxelSize(voxWidth, voxHeight, voxDepth, voxUnit);
run("Reslice [/]...", "output="+voxDepth+" start=Top avoid");
topID = getImageID();
getDimensions(topWidth, topHeight, channels, topSlices, topFrames);
run("Z Project...", "projection=[Max Intensity]");
topMaxID = getImageID();
setTool(7);
run("Select None");
setBatchMode("show");
waitForUser("Make point between regions to split and click ok.");
setBatchMode("hide");
getSelectionCoordinates(xTemp, yTemp);
last = yTemp[0];
run("Line Width...", "line="+lineWidth+"");
xPoints = newArray(topWidth+2);
yPoints = newArray(topWidth+2);
for(i=0; i<topWidth; i++){
  makeLine(i,0,i,topHeight);
  profile = getProfile();
  minima = Array.findMinima(profile, minimaThreshold);
  min = findNearest(minima, last);
  temp = "Pixel "+i+":  "+last+"  "+min+"  ";
  xPoints[i] = i;
  if(matches(min, NaN)==false){
    yPoints[i] = min;
    last = min;
//    for(n=0;n<minima.length;n++){
//      temp = temp+minima[n]+" ";
//    }
//    else min = minima[1];
//    makePoint(i, min);
//    tempName = "Minima at x = "+i;
//    Roi.setName(tempName);
//    roiManager("Add");
  }
  else yPoints[i] = last;
}
xPoints[xPoints.length-2] = topWidth;
xPoints[xPoints.length-1] = 0;
yPointsTop = Array.copy(yPoints);
yPointsBottom = Array.copy(yPoints);
yPointsTop[yPoints.length-2] = 0;
yPointsBottom[yPoints.length-2] = topHeight;
yPointsTop[yPoints.length-1] = 0;
yPointsBottom[yPoints.length-1] = topHeight;
run("Line Width...", "line=1");
selectImage(topID);
run("Select None");
run("Duplicate...", "duplicate");
rearIDTop = getImageID();
run("Select None");
run("Duplicate...", "duplicate");
frontIDTop = getImageID();
selectImage(rearIDTop);
makeSelection("freehand", xPoints, yPointsTop);
run("Clear", "stack");
run("Select None");
run("Reslice [/]...", "output="+voxHeight+" start=Top avoid");
rename(imageTitle+" RearAxon");
rearID = getImageID();
run("Z Project...", "projection=[Max Intensity]");
selectImage(rearIDTop);
close();
selectImage(frontIDTop);
makeSelection("freehand", xPoints, yPointsBottom);
run("Clear", "stack");
run("Select None");
run("Reslice [/]...", "output="+voxHeight+" start=Top avoid");
rename(imageTitle+" Front Axon");
frontID = getImageID();
run("Z Project...", "projection=[Max Intensity]");
if(keepStacks==false){
  selectImage(frontID);
  close();
  selectImage(rearID);
  close();
}
selectImage(frontIDTop);
close();
selectImage(topID);
close();
selectImage(topMaxID);
close();
if(keepOriginal==false){
  selectImage(originalID);
  close();
}
else{
  selectImage(originalID);
  run("Z Project...", "projection=[Max Intensity]");
  rename(imageTitle+" Both Axons");
}
setBatchMode("exit and display");
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

macro "Split Axons Tool Options" {
//  lineWidth = getNumber("Line width used to sample axons", 10);
//  minimaThreshold = getNumber("Threshold for identifying minima between axons", 100);
  title = "Split Axons Tool Options";
  Dialog.create(title);
  Dialog.addNumber("Line width used to sample axons", 10);
  Dialog.addNumber("Threshold for identifying minima between axons", 100);
  Dialog.addCheckbox("Keep Z-Stacks?", false);
  Dialog.addCheckbox("Keep original image?", true);
//  Dialog.addRadioButtonGroup("Trace minima or maxima?", newArray("Minima", "Maxima"), 1,2,"Maxima");
  Dialog.show();
  lineWidth = Dialog.getNumber();
  minimaThreshold = Dialog.getNumber();
  keepStacks = Dialog.getCheckbox();
  keepOriginal = Dialog.getCheckbox();
//  choice = Dialog.getRadioButton();
}