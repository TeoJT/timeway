#ifdef GL_ES
precision mediump float;
#endif

uniform vec4 color;
uniform float intensity;

void main() {
    gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
}