shader_type spatial;
render_mode cull_disabled;
varying vec3 local_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() { local_pos = VERTEX; }
void fragment() {
    float detail = noise(local_pos.xz*0.9)*0.5 + noise(local_pos.xz*3.7)*0.3 + noise(local_pos.xz*17.0)*0.2;
    vec3 moss = mix(vec3(0.12,0.18,0.07),vec3(0.28,0.31,0.14),detail);
    vec3 stone = mix(vec3(0.19,0.20,0.16),vec3(0.39,0.38,0.28),detail);
    float shore = 1.0-smoothstep(-8.8,-5.0,local_pos.y);
    ALBEDO = mix(moss,stone,shore);
    ROUGHNESS = mix(0.95,0.58,shore);
}
