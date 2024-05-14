
uniform mat4 transformMatrix;
//uniform mat4 texMatrix;

attribute vec4 color;
attribute vec4 position;
attribute vec2 texCoord;
attribute vec2 vertexFrame;

varying vec4 vertColor;
varying vec4 texSamplePoint;
varying vec2 fragPos;

void main() {
  gl_Position = transformMatrix * position;



  vertColor = vec4(1.0); //color;
  texSamplePoint = vec4(texCoord, 1.0, 1.0);
  fragPos = vertexFrame;
}