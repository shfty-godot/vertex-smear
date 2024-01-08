/*
Spline-based vertex smearing shader

TODO:
[ ] Fix UB
    * Entire shader will fail if any segment is empty

[ ] Fix point 0 behavior
    * Shouldn't move weight 0 vertices
    * Should define where the smear begins
	* Ex. place p0 on surface of sphere for accurate end-point positioning
	* As per old single-segment implementation

[ ] Implement handle generation for PathTracker
    * Currently using linear point-to-point
    * Generate smooth spline segments via projection

[ ] Interpolation
    * Need a way to make the spline change smoothly
    * Currently prone to visual hiccups (ex. when slow-dragging in the editor)
    * Update spline at a fixed tick, interpolate every frame

[ ] Figure out how to rotate vertices based on spline
    * Similar to Blender deform modifier

[ ] Normal correction

*/

shader_type spatial;

const float PI = 3.14159265358979323846264338327950288419716939937510;

uniform vec4 albedo : hint_color = vec4(1.0);

uniform bool draw_vertex_weight = false;

uniform sampler2D data;

varying float v_vertex_weight;

ivec2 data_size() {
    return textureSize(data, 0);
}

vec2 texel_size(ivec2 data_size) {
    return 1.0 / vec2(data_size);
}

vec3 data_position(int idx, ivec2 data_size, vec2 half_texel) {
    return texture(data, vec2(float(idx) / float(data_size.x), 0) + half_texel).xyz;
}

vec3 data_handle_in(int idx, ivec2 data_size, vec2 half_texel) {
    return texture(data, vec2(float(idx) / float(data_size.x), 1) + half_texel).xyz;
}

vec3 data_handle_out(int idx, ivec2 data_size, vec2 half_texel) {
    return texture(data, vec2(float(idx) / float(data_size.x), 2) + half_texel).xyz;
}

float vertex_weight(vec3 vertex, vec3 p0, vec3 p0_out, vec3 p1) {
    // Weight vertices based on their dot versus the start point.
    // If the start point is at the origin, use the out handle instead.
    vec3 weight_axis; 

    if(p0 != vec3(0.0)) {
	weight_axis = normalize(p0);
    }
    else if(p0_out != vec3(0.0)) {
	weight_axis = normalize(p0_out);
    }
    else {
	weight_axis = normalize(p1);
    }

    return clamp(dot(normalize(vertex), weight_axis), 0.0, 1.0);
}

void vertex() {
    COLOR = albedo;
    mat3 basis = mat3(WORLD_MATRIX);

    ivec2 data_size = data_size();
    vec2 texel_size = texel_size(data_size);
    vec2 half_texel = texel_size * 0.5;

    int segment_count = data_size.x - 1;

    // Calculate U coordinate of first and second points
    float u0 = half_texel.x;
    float u1 = u0 + texel_size.x;

    // Fetch first and second points
    vec3 p0 = data_position(0, data_size, half_texel);
    vec3 p1 = data_position(1, data_size, half_texel);

    vec3 p0_out = data_handle_out(0, data_size, half_texel);
    vec3 p1_in = data_handle_in(1, data_size, half_texel);

    // Calculate vertex weight
    v_vertex_weight = vertex_weight(VERTEX * inverse(basis), p0, p0_out, p1);

    // Segment weight
    float t = mod(v_vertex_weight, 1.0 / float(segment_count)) * float(segment_count);

    // Segment index
    int segment_idx = int(v_vertex_weight * float(segment_count));

    // Segment start / end
    vec3 pa = data_position(segment_idx, data_size, half_texel);
    vec3 pb = data_position(segment_idx + 1, data_size, half_texel);

    // Segment handles
    vec3 pa_out = data_handle_out(segment_idx, data_size, half_texel);
    vec3 pb_in = data_handle_in(segment_idx + 1, data_size, half_texel);

    // Apply world rotation
    pa *= basis;
    pb *= basis;
    pa_out *= basis;
    pb_in *= basis;

    // Calculate line segment
    vec3 segment = pb - pa;

    vec3 segment_smear = pa;
    vec3 out_smear = vec3(0.0);
    vec3 in_smear = vec3(0.0);

    if(length(segment) >= 0.001) {
        // Base start > end smear
	segment_smear = pa + segment * t;

	// Center point for handle offset calculation
        vec3 center = segment * 0.5;

        // Out handle offset
	
        // Use start > end if pa_out is unset
        if(length(pa_out) < 0.001) {
            pa_out = normalize(segment) * 0.001;
        }

        if(pa_out != center) {
            out_smear = normalize(pa_out - center)
	       		    * sin(t * PI)
			    * length(pa_out - center)
			    * 0.5;
        }

        // In handle offset

        // Use end > start if pa_out is unset
        if(length(pb_in) < 0.001) {
            pb_in = normalize(-segment) * 0.001;
        }

	vec3 pb_in_local = segment + pb_in;
	if(pb_in_local != center) {
	    in_smear = normalize(pb_in_local - center)
				* sin(t * PI)
				* length(pb_in_local - center)
				* 0.5;
	}
    }

    // Compose final smear
    VERTEX += segment_smear + mix(out_smear, in_smear, t);
}

void fragment() {
    if(draw_vertex_weight) {
        ALBEDO = vec3(v_vertex_weight);
    }
    else {
        ALBEDO = COLOR.rgb;
    }
}
