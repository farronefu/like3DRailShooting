shader_type spatial;
render_mode cull_disabled;
void fragment() {
    float across = abs(UV.x-0.5)*2.0;
    float taper = pow(max(0.0,1.0-UV.y),0.45);
    float needles = abs(sin(UV.y*110.0 + across*18.0));
    float feather = taper * (0.46 + needles*0.54);
    ALPHA = step(across,feather) * step(UV.y,0.985);
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    vec3 pine = mix(vec3(0.023,0.055,0.021),vec3(0.074,0.135,0.045),UV.y+needles*0.2);
    ALBEDO = pine * COLOR.rgb;
    ROUGHNESS = 0.9;
    BACKLIGHT = vec3(0.055,0.09,0.025);
}
