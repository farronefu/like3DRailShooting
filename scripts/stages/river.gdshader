shader_type spatial;
render_mode cull_disabled;
uniform float flow_time = 0.0;
varying vec3 world;
float waves(vec2 p) {
    return sin(p.x * 1.7 + p.y * 0.63) * 0.32 + sin(p.x * 0.71 - p.y * 1.23) * 0.23 + sin(p.x * 3.1 + p.y * 2.7) * 0.08;
}
void vertex() {
    world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX.y += waves(world.xz * 0.55 + vec2(0.0, flow_time * 2.0)) * 0.12;
}
void fragment() {
    vec2 p = world.xz + vec2(0.0, flow_time * 4.0);
    float w = waves(p);
    vec3 normal_world = normalize(vec3((waves(p + vec2(0.12,0.0)) - w) * -1.1, 1.0, (waves(p + vec2(0.0,0.12)) - w) * -1.1));
    NORMAL = normalize((VIEW_MATRIX * vec4(normal_world, 0.0)).xyz);
    float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 4.0);
    float shore = smoothstep(16.0, 24.0, abs(world.x));
    ALBEDO = mix(vec3(0.035,0.16,0.16), vec3(0.32,0.46,0.43), fresnel * 0.8);
    ALBEDO = mix(ALBEDO, vec3(0.16,0.26,0.20), shore * 0.4);
    float foam = smoothstep(0.52,0.62,w) * shore;
    ALBEDO += foam * vec3(0.17,0.20,0.17);
    METALLIC = 0.35;
    ROUGHNESS = 0.17 + shore * 0.14;
    SPECULAR = 0.85;
}
