#version 400
in FragInfo {
	vec2		uv;
	vec3		normal;
	vec3		pos;
	vec3		cam;
	float		mtl;
} frag;

struct Material {
	float				transparent;
	float				shine;
	vec4				col[4];
};
uniform	Material			material[4];
uniform	sampler2DArray		texture_pack;
uniform	vec4				col;

bool use_material =	frag.mtl >= 0;

#define	AMBIENT		0
#define	DIFFUSE		1
#define	SPECULAR	2
// ---------- TYLKO DLA TEXTUR -------------
#define	ALPHA		3
#define	BUMP		4
// -----------------------------------------

#define	GET_MATERIAL_UV_TEX(uv, type)	texture(texture_pack, vec3(uv , frag.mtl * (BUMP+1) + type))
#define	GET_MATERIAL_TEX(type)			GET_MATERIAL_UV_TEX(vec2(frag.uv.x, 1.0 - frag.uv.y), type)
#define	MATERIAL						material[int(frag.mtl)]

struct Light {
	vec3	pos;
	float	ambient_intensity;
	
	vec4	diffuse_col;
	float	diffuse_intensity;	
	
	vec4	specular_col;
	float	specular_intensity;
};
Light	light = Light(
	vec3(0.0, 0.5, 0.5), // Pos
	1.0,				// Ambient intensity
	
	vec4(1.0, 1.0, 1.0, 1.0), // Diffuse col
	1.0,
	
	vec4(1.0, 1.0, 1.0, 1.0), // Specular col
	1.0
);

vec2 pixelize(in float d) {
	return vec2(d * floor(frag.uv.x / d), d * floor((1.0 - frag.uv.y) / d));
}
void calcLight(void) {
	vec3 normal	= normalize(frag.normal + 
			(use_material ? 
						normalize((GET_MATERIAL_TEX(BUMP).rgb * 2.0 - 1.0)) : 
						vec3(0,0,0)));
	// Diffuse
	float	distance		=	length(frag.pos - light.pos);
	vec3	light_normal	=	normalize(abs(frag.pos - light.pos)); // abs
	float	diffuse			=	max(dot(light_normal, normal), 0.0) 
									* (1.0 / (distance * distance));
	vec4	diffuse_col		=	use_material ? 
									GET_MATERIAL_TEX(DIFFUSE) * vec4(MATERIAL.col[DIFFUSE].rgb, 1.0) : 
									col;
											
	// Specular
	float specular_col = 0.f;
	if(use_material) {
		vec3 reflect 	= 	normalize(2 * diffuse * normal - light_normal);
		vec3 viewDir 	=	normalize(abs(frag.cam - frag.pos));
		float specular 	=	pow(max(dot(viewDir, reflect), 0.0), 64);
		
		specular_col = GET_MATERIAL_TEX(SPECULAR).g * 
							specular * 
							light.specular_intensity;
	}
	
	gl_FragColor += 	
				(diffuse_col + specular_col * light.specular_col) 
				* light.diffuse_col 
				* light.diffuse_intensity
				* diffuse;
}
bool drawMaterial(void) {
	if(!use_material)
		return false;
	gl_FragColor = MATERIAL.col[AMBIENT]; // ambient
	gl_FragColor.a = MATERIAL.transparent;
	return true;
}
void main(void) {
	if(!drawMaterial())
		gl_FragColor =	col;
	calcLight();
}
