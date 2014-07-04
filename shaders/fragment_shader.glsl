#version 400
in vec2		frag_uv;
in	vec3		frag_normal;
in	vec3		frag_pos;
in float		mtl;
in	mat3		NormalMatrix;

struct Material {
	float				transparent;
	float				shine;
	vec4				col[4];
};
uniform	sampler2DArray	texture_pack;
uniform	vec4				col;
uniform	Material			material[4];

#define	AMBIENT	0
#define	DIFFUSE	1
#define	SPECULAR	2
// ---------- TYLKO DLA TEXTUR -------------
#define	ALPHA		3
#define	BUMP		4
// -----------------------------------------

#define	GET_MATERIAL_TEX(type)	texture(texture_pack, vec3(vec2(frag_uv.x, 1.0 - frag_uv.y), mtl * (BUMP+1) + ## type ##))
#define	MATERIAL						material[int(mtl)]

struct Light {
	vec3	pos;
	vec4	col;
};
Light	light = Light(
	vec3(0, 0, 0),
	vec4(1, 1, 1, 1)
);

void calcLight(void) {
	vec3 	light_vec	=	normalize(vec3(light.pos - frag_pos));
	float	diffuse		= max(normalize(dot(light_vec, GET_MATERIAL_TEX(BUMP).rgb)), 0.0);
	//gl_FragColor.rgb *= diffuse;
}
bool drawWithMaterial(void) {
	if(mtl < 0)
		return false;
	// Oswietlenie
	gl_FragColor =   GET_MATERIAL_TEX(DIFFUSE) * MATERIAL.transparent;
	return true;
}
void main(void) {
	if(!drawWithMaterial())
		gl_FragColor =	col;
	calcLight();
}