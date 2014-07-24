#version 400

#define	AMBIENT		0
#define	DIFFUSE		1
#define	SPECULAR	2
// ---------- TYLKO DLA TEXTUR -------------
#define	ALPHA		3
#define	BUMP		4
// -----------------------------------------

in FragInfo {
	vec2		uv;
	vec3		normal;
	vec3		pos;
	vec3		cam;
	float		mtl;
} frag;
struct Light {
	vec3	pos;
	float	ambient_intensity;
	
	vec4	diffuse_col;
	float	diffuse_intensity;	
	
	vec4	specular_col;
	float	specular_intensity;
};

// ------------- UNIFORMY -----------------
// std140
// tablica wielkosc * sizeof vec4
// chunk vec4
// 3 bloki po 136B+8B extra i 4 block 136B
struct Material { // 136B size
	vec4				col[3]; // 48B
	bool				tex_flag[BUMP + 1]; // 80B
	float				transparent; // 4B
	float				shine; // 4B
	// 4*float=8B extra
};
layout(std140) uniform MaterialBlock {
	Material	material[4];
};

uniform	sampler2DArray		texture_pack;
uniform	vec4				col;

#define	GET_MATERIAL_UV_TEX(uv, type)	texture(texture_pack, vec3(uv , frag.mtl * (BUMP+1) + type))
#define	GET_MATERIAL_TEX(type)			GET_MATERIAL_UV_TEX(vec2(frag.uv.x, 1.0 - frag.uv.y), type)

Material 	MATERIAL 	= 	material[int(frag.mtl)];
Light		light 		= 	Light(
	vec3(0.0, 0.5, 0.0), // Pos
	1.0,				// Ambient intensity
	
	vec4(1.0, 1.0, 1.0, 1.0), // Diffuse col
	2.0,
	
	vec4(1.0, 1.0, 1.0, 1.0), // Specular col
	1.0
);

vec2 pixelize(in float d) {
	return vec2(d * floor(frag.uv.x / d), d * floor((1.0 - frag.uv.y) / d));
}
void calcLight(void) {
	vec3 normal;
	if(MATERIAL.tex_flag[BUMP])
		normal = normalize(GET_MATERIAL_TEX(BUMP).rgb * 2.0 - 1.0);
	else
		normal = normalize(frag.normal);
	
	// Diffuse
	vec3	light_normal	=	normalize(abs(frag.pos - light.pos));
	float	distance		=	length(frag.pos - light.pos);
	float	diffuse			=	max(dot(light_normal, normal), 0.0) 
									* (1.0 / (1.0 + (0.5 * distance * distance)));
											
	// Specular
	if(MATERIAL.tex_flag[SPECULAR]) {
		vec3 	reflect 	= 	normalize(2 * diffuse * normal - light_normal);
		vec3 	viewDir 	=	normalize(abs(frag.cam - frag.pos));
		float 	aspect 		=	pow(max(dot(viewDir, reflect), 0.0), 2);
		float 	specular 	= 	0.0;
		vec3 	spec_tex 	= 	GET_MATERIAL_TEX(SPECULAR).rgb;
		specular = (spec_tex.r + spec_tex.g + spec_tex.b) * 
							aspect * 
							light.specular_intensity;
		gl_FragColor +=	
					vec4(
						(MATERIAL.col[SPECULAR] * 
						specular * 
						light.specular_col * 
						light.specular_intensity).rgb, 0.0);
	}
	
	// Całość
	if(MATERIAL.tex_flag[AMBIENT])	
		gl_FragColor += vec4(MATERIAL.col[AMBIENT].rgb * 
						light.ambient_intensity, 0.0);
						
	if(MATERIAL.tex_flag[DIFFUSE]) {
		vec4	diffuse_col	= GET_MATERIAL_TEX(DIFFUSE) * MATERIAL.col[DIFFUSE];
		gl_FragColor += 
					diffuse_col * 
					light.diffuse_col * 
					light.diffuse_intensity * 
					vec4(diffuse, diffuse, diffuse, 1.0);
		gl_FragColor.a *= MATERIAL.transparent;
	} else
		gl_FragColor =	col;
}
void main(void) {
	calcLight();
}