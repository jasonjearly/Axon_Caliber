// 06-03-2020

var calibre, sample_line_width, sample_line_length, gradient_sampling, output_string;

macro "Axon Calibre [u]"{
  sample_line_length = 10;//Sample line width in microns
  sample_line_width = 40;//Sample line width in pixels
  gradient_sampling = 10;//Number of points before and after current point on line to consider when calculating local gradient
  print_widths_by_px = false;//change to false to only get caliber
  getVoxelSize(voxWidth, voxHeight, voxDepth, voxUnit);
  output_string = "Point#\tX(px)\tY(px)\tGradient\tDistance on Selection ("+voxUnit+")\tCalibre(microns)";
  if(nImages==0) exit("No images are open.");
  if(selectionType()==-1||selectionType()==10){
//    setTool("Axon Trace Tool");
    exit("No line selection");
  }
  List.setMeasurements;
  line_length = List.getValue("Length");
  setBatchMode(true);
  originalID = getImageID();
  imageTitle = getTitle();
  calibre = getCalibre()*voxWidth;
  getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
  outString = imageTitle+"\t"+calibre+"\t"+voxUnit;
  print(outString);
  outString = "Title\t"+imageTitle+"\nCalibre\t"+calibre+"\nPixel Size\t"+voxWidth+"\t"+voxUnit+"\nMeasured Length (Scaled)\t"+line_length+"\nLine Width (Pixels)\t"+sample_line_width+"\nLine length (Scaled)\t"+sample_line_length+"\nGradient Sampling (points before and after current)\t"+gradient_sampling+"\nDatetime\t"+year+"-"+month+1+"-"+dayOfMonth+"T"+hour+":"+minute+"."+second+"\n";
  String.copy(outString);
  if(print_widths_by_px) String.copy(outString+"\n"+output_string);
  setBatchMode(false);
}

function getCalibre(){
  run("Interpolate", "interval=1");
  getVoxelSize(voxWidth, voxHeight, voxDepth, voxUnit);
  getSelectionCoordinates(x, y);
  run("Duplicate...", "duplicate");
  tempID = getImageID();
  xOut = newArray((x.length-1)*2);
  yOut = newArray((y.length-1)*2);
  run("Line Width...", "line="+sample_line_width+"");
  for(i=0, n=0;i<x.length-1;i++){
    top = i+gradient_sampling;
    if(top>=x.length-1) top = x.length-1;
    bottom = i-gradient_sampling;
    if(bottom<0) bottom = 0; 
    xIn = Array.slice(x,bottom,top);
    yIn = Array.slice(y,bottom,top);
    form = getBestFitStraightLine(xIn, yIn);
    m = form[0];
    c = form[1];
    xTemp = x[i]+((x[i+1]-x[i])/2);
    yTemp = y[i]+((y[i+1]-y[i])/2);
    perp = getPerpendicular(form, xTemp, yTemp);
    half_length = sample_line_length/(voxWidth*2);
    point1 = pointDFromX(perp, xTemp, yTemp, half_length, 1);
    point2 = pointDFromX(perp, xTemp, yTemp, half_length, -1);
//    line = newArray(point1[0], point1[1], point2[0], point2[1]);
    if(i==0) line = newArray(point1[0], point1[1], point2[0], point2[1]);
    else{
      d1 = getDistance(point1[0],point1[1],line[0],line[1]);
      d2 = getDistance(point2[0],point2[1],line[0],line[1]);
      if(d1>d2) line = newArray(point2[0], point2[1], point1[0], point1[1]);
      else line = newArray(point1[0], point1[1], point2[0], point2[1]); 
    }
//    makePoint(line[0], line[1]);
//    wait(100);
    makeLine(line[0], line[1], line[2], line[3]);
    run("Interpolate", "interval=1");
    getSelectionCoordinates(xProfile, yProfile);
    profile = getProfile();
    edges = findEdges(profile);
    if(calibre!=0){
      if(print_widths_by_px){
      	output_string = output_string + "\n"+i+"\t"+x[i]+"\t"+y[i]+"\t"+m+"\t"+i*voxWidth+"\t"+calibre*voxWidth;
//      	print(""+i+","+x[i]+","+y[i]+","+calibre*voxWidth);
      	
      }
      calibreTot = calibreTot+calibre;
      n++;
    }
//    if(i==0) calibreList = ""+i;
//    calibreList = calibreList+","+calibre;
    xOut[i] = xProfile[edges[0]];
    xOut[xOut.length-(i+1)] = xProfile[edges[1]];
    yOut[i] = yProfile[edges[0]];
    yOut[yOut.length-(i+1)] = yProfile[edges[1]];
  }
  selectImage(tempID);
  close();
  selectImage(originalID);
  run("Line Width...", "line="+1+"");
  makeSelection("freehand", xOut, yOut);
//  tempCalibres = split(calibreList,i);
  meanCalibre = calibreTot/x.length;
  return meanCalibre;
}

function getPerpendicular(formula, x, y){
  m = formula[0];
  c = formula[1];
  verX = NaN;
  if(matches(m,NaN)) newM = 0;
  else if(m==0) newM = NaN;
  else newM = -1/m;
  if(matches(newM, NaN)){
    newC = 0;
    verX = x;
  }
  newC = (newM*-1*x)+y;
  outLine = newArray(newM,newC,verX);
  return outLine;
}

function pointDFromX(form, x, y, d, direction){
  m = form[0];
  if(form[0]==0||matches(form[0],NaN)){
    if(form[0]==0){
      newX = x+(direction*d);
      newY = y;
    }
    if(matches(form[0],NaN)){
      newX = x;
      newY = y+(direction*d);
    }
  }
  else{
    if(direction==1) newX = x+sqrt((d*d)/(1+m*m));
    if(direction==-1) newX = x-sqrt((d*d)/(1+m*m));
    newY = (form[0]*newX)+form[1];
  }
  return newArray(newX, newY);
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

function findEdges(profile){
  centre = round(profile.length/2);
  Array.getStatistics(profile, min, max, mean, stdDev);
  threshold = max/2;
  profileLog = "";
  tempProfile = "";
  containsCentre = false;
  minLength = 3;
  for(i=0, l=0;i<profile.length;i++){
    if(profile[i]>threshold){
      l++;
      if(l==1){
        tempProfile = ""+i;
      }
      else tempProfile = tempProfile+","+i;
      if(i==centre) containsCentre = true;
      if(l>=minLength&&i==(profile.length-1)&&containsCentre==true){
        profileLog = tempProfile;
        calibre = l;
      }
    }
    else{
      if(l>=minLength&&containsCentre==true){
        profileLog = tempProfile;
        i = profile.length-1;
        calibre = l;
      }
      else{
        tempProfile = "";
        l=0;
      }
    }
  }
  pixels = split(profileLog, ",");
  if(pixels.length>0) edges = newArray(pixels[0], pixels[pixels.length-1]);
  else edges = newArray(NaN, NaN);
//  midPoint = floor(pixels.length/2);
//  print("Midpoint = "+midPoint);
//  mod =pixels.length%2;
//  if (mod!=0&&pixels.length>1) midPoint++;
//  centre = pixels[midPoint];
  return edges;

}

function getDistance(x1,y1,x2,y2){
  d = sqrt(((x1-x2)*(x1-x2))+((y1-y2)*(y1-y2)));
  return d;
}
