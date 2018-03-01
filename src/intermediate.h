#include <stdio.h>

#define MAX_QUAD_NUM 10000

/*
 * Intermediate Code Producer section
 */

/* Quad types */
typedef enum {
	PLUS_QUAD, MINUS_QUAD, MULT_QUAD, DIV_QUAD, MOD_QUAD,
	EQ_QUAD, NE_QUAD, GT_QUAD, LT_QUAD, GE_QUAD, LE_QUAD,
	UNIT_QUAD, ENDU_QUAD,
	ASSIGN_QUAD, ARRAY_QUAD,
	JMP_QUAD,
	PAR_QUAD, CALL_QUAD, RET_QUAD, RETV_QUAD,
	NULL_QUAD
} QuadType;

typedef struct {
	QuadType type;
	char *arg1, *arg2;
	char *dest;
} Quad;

extern int ProduceInterm;
extern long quad_num, q_off;
extern Quad quad_array[];
extern FILE *imm_stream;

/* Define a linked list of labels */
typedef struct label_list_struct {
	long label;
	struct label_list_struct *next;
} label_list_t;
typedef label_list_t * label_list;

/* Quad and label_list manipulation functions */
extern long GenQuad(QuadType, char *, char *, char *);
extern void FlushQuads(void);
extern void FreeQuads(void);

void next_tempvar_name(char *);
void backpatch(label_list, long);

label_list make_list(long);
label_list empty_list();
label_list merge(label_list, label_list);

