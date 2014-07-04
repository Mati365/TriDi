#version 400
layout(location = 0) in  vec4 Position;
layout(location = 1) in  vec3 Normal;
layout(location = 2) in  vec2 UV;
layout(location = 3) in  int	MTL_index;

out 	vec2		frag_uv;
out	vec3		frag_normal;
out 	vec3		frag_pos;
out 	float		mtl;
out	mat3		NormalMatrix;

struct Matrix {
	mat4x4 	mvp;
	mat3		normal_matrix;
};
uniform Matrix	matrix;

void main(void) {
	gl_Position 	= 	Position * matrix.mvp;
	NormalMatrix	=	matrix.normal_matrix;
	frag_normal		= 	Normal;
	frag_pos			= 	gl_Position.xyz;

	frag_uv = UV;
	mtl = MTL_index;
}