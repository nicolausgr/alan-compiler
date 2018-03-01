#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <assert.h>

#include "intermediate.h"
#include "final.h"
#include "error.h"
#include "symbol.h"


char *strings[MAX_NUMBER_OF_STRINGS];
int  str_num = 0;
int isOfTypeArray = 0;

char *funcNameOfScope, *funcNameOfMain;

/* Function prototypes */
void load(char *, char *);
void loadAddr(char *, char *);

/* Our implementation of strdup */
char *my_strdup2(const char *str)
{
	int n = strlen(str) + 1;
	char *dup = malloc(n);

	if (dup)
		strcpy(dup, str);
	else
		internal("memory allocation failure");

	return dup;
}

/* Function for conversion from hex byte to int (ASCII value) */
char hextoint(char msb, char lsb)
{
	char ret;

	if (msb >= '0' && msb <= '9')
		ret = 16 * (msb-'0');
	else if (msb >= 'A' && msb <= 'F')
		ret = 16 * (msb-'A'+10);
	else
		ret = 16 * (msb-'a'+10);

	if (lsb >= '0' && lsb <= '9')
		ret += lsb-'0';
	else if (lsb >= 'A' && lsb <= 'F')
		ret += lsb-'A'+10;
	else
		ret += lsb-'a'+10;

	return ret;
}

/* This function writes a line of x86 assembly to final_stream */
void code(const char *s, ...)
{
	va_list ap;

	va_start(ap, s);
	vfprintf(final_stream, s, ap);
	fprintf(final_stream, "\n");
	va_end(ap);
}

/* This function returns 1 if its string argument is of IntegerType */
int SizeOfInteger(char *s)
{
	char buf[BUFLEN], *p, *q;
	SymbolEntry *se;

	isOfTypeArray = 0;

	/* If it is a constant (int), return true */
	if (isdigit(s[0]))
		return 1;
	/* If it is a character, return false */
	else if (s[0] == '\'')
		return 0;
	/* If it is a pointer, lookup the refType */
	else if (s[0] == '[') {
		strcpy(buf, s);
		q = buf;
		q++;
		p = q;
		while (*p != ']')
			p++;
		*p = '\0';
		se = lookupEntry(q, LOOKUP_ALL_SCOPES, true);
		if (se->entryType != ENTRY_TEMPORARY || (se->entryType == ENTRY_TEMPORARY && se->u.eTemporary.type->kind != TYPE_POINTER))
			internal("SizeOfInteger: expected pointer, got something else :p");
		else if (se->u.eTemporary.type->refType == typeInteger)
			return 1;
		else
			return 0;
	}
	else {
		se = lookupEntry(s, LOOKUP_ALL_SCOPES, true);
		switch (se->entryType) {
			case ENTRY_VARIABLE:
				if (se->u.eVariable.type->kind == TYPE_ARRAY || se->u.eVariable.type->kind == TYPE_IARRAY) {
					isOfTypeArray = 1;
					return (se->u.eVariable.type->refType == typeInteger) ? 1 : 0;
				}
				else
					return (se->u.eVariable.type == typeChar) ? 0 : 1;
				break;
			case ENTRY_PARAMETER:
				if (se->u.eParameter.type->kind == TYPE_ARRAY || se->u.eParameter.type->kind == TYPE_IARRAY) {
					isOfTypeArray = 1;
					return (se->u.eParameter.type->refType == typeInteger) ? 1 : 0;
				}
				else
					return (se->u.eParameter.type == typeChar) ? 0 : 1;
				break;
			case ENTRY_TEMPORARY:
				if (se->u.eTemporary.type == typeChar)
					return 0;
				else
					return 1;
				break;
			default: internal("SizeOfInteger: unexpected entryType"); exit(1);
		}
	}
	/* Will never reach here */
	return 0;
}

/* This function returns the size of the arguments of a function */
int GetSizeOfArguments(SymbolEntry *se)
{
	int ret = 0;
	SymbolEntry *args = se->u.eFunction.firstArgument;

	while (args != NULL) {
		if (args->u.eParameter.type == typeChar)
			ret++;
		else
			ret += 2;
		args = args->u.eParameter.next;
	}

	return ret;
}

/* The following functions return pointers to static buffers */

char *label(char *numstr)
{
	static char buf[BUFLEN];

	snprintf(buf, BUFLEN, "@%s", numstr);
	return buf;
}

char *endof(char *p)
{
	SymbolEntry *se;
	static char buf[BUFLEN];

	se = lookupEntry(p, LOOKUP_ALL_SCOPES, true);
	snprintf(buf, BUFLEN, "@%s_%d", p, se->u.eFunction.funcid);
	return buf;
}

char *name(char *p)
{
	SymbolEntry *se;
	static char buf[BUFLEN];

	se = lookupEntry(p, LOOKUP_ALL_SCOPES, true);
	if (se->u.eFunction.funcid == 0 && strcmp(p, funcNameOfMain))
		snprintf(buf, BUFLEN, "_%s", p);
	else
		snprintf(buf, BUFLEN, "_%s_%u", p, se->u.eFunction.funcid);
	return buf;
}

void getAR(char *a)
{
	unsigned int q, i;
	SymbolEntry *se;

	se = lookupEntry(a, LOOKUP_ALL_SCOPES, true);
	q = currentScope->nestingLevel - se->nestingLevel - 1;

	code("\tmov\tsi,word ptr [bp+4]");
	assert(q >= 0);
	for (i=0; i<q; i++)
		code("\tmov\tsi,word ptr [si+4]");
}

void updateAL(char *called_func)
{
	unsigned int np, nx, q;
	SymbolEntry *se;

	np = currentScope->nestingLevel - 1;
	se = lookupEntry(called_func, LOOKUP_ALL_SCOPES, true);
	nx = se->nestingLevel;

	/* if nx==1 access link won't be needed */
	if (np < nx || nx == 1)
		code("\tpush\tbp");
	else if (np == nx)
		code("\tpush\tword ptr [bp+4]");
	else {
		code("\tmov\tsi,word ptr [bp+4]");
		for (q=0; q<np-nx-1; q++)
			code("\tmov\tsi,word ptr [si+4]");
		code("\tpush\tword ptr [si+4]");
	}
}

void load(char *reg, char *a)
{
	SymbolEntry *se;
	char buf[BUFLEN], *p, *q;

	/* a is an integer constant */
	if (isdigit(a[0])) {
		code("\tmov\t%s,%s", reg, a);
		return;
	}

	/* a is a character constant */
	if (a[0] == '\'') {
		if (a[1] != '\\')
			code("\tmov\t%s,%d", reg, a[1]);
		else {
			switch (a[2]) {
				case 'n':  code("\tmov\t%s,%d", reg, '\n'); break;
				case 't':  code("\tmov\t%s,%d", reg, '\t'); break;
				case 'r':  code("\tmov\t%s,%d", reg, '\r'); break;
				case '0':  code("\tmov\t%s,%d", reg, '\0'); break;
				case '\\': code("\tmov\t%s,%d", reg, '\\'); break;
				case '\'': code("\tmov\t%s,%d", reg, '\''); break;
				case '\"': code("\tmov\t%s,%d", reg, '\"'); break;
				default:   internal("load: unknown character"); exit(1);
			}
		}
		return;
	}

	/* a is an array expression */
	if (a[0] == '[') {
		strcpy(buf, a);
		q = buf;
		q++;
		p = q;
		while (*p != ']')
			p++;
		*p = '\0';
		load("di", q);
		if (SizeOfInteger(a))
			code("\tmov\t%s,word ptr [di]", reg);
		else
			code("\tmov\t%s,byte ptr [di]", reg);
		return;
	}

	se = lookupEntry(a, LOOKUP_ALL_SCOPES, true);
	/* Local or non-local variable? */
	if (currentScope->nestingLevel != se->nestingLevel) {
		getAR(a);
		/* Variable passed ByReference? */
		if (se->entryType == ENTRY_PARAMETER && se->u.eParameter.mode == PASS_BY_REFERENCE) {
			code("\tmov\tsi,word ptr [si+%d]", se->u.eParameter.offset);
			if (SizeOfInteger(a) || isOfTypeArray)
				code("\tmov\t%s,word ptr [si]", reg);
			else
				code("\tmov\t%s,byte ptr [si]", reg);
			return;
		}
		else {
			switch (se->entryType) {
				case ENTRY_VARIABLE:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\t%s,word ptr [si-%d]", reg, -(se->u.eVariable.offset));
					else
						code("\tmov\t%s,byte ptr [si-%d]", reg, -(se->u.eVariable.offset));
					break;
				case ENTRY_PARAMETER:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\t%s,word ptr [si+%d]", reg, se->u.eParameter.offset);
					else
						code("\tmov\t%s,byte ptr [si+%d]", reg, se->u.eParameter.offset);
					break;
				case ENTRY_TEMPORARY:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\t%s,word ptr [si-%d]", reg, -(se->u.eTemporary.offset));
					else
						code("\tmov\t%s,byte ptr [si-%d]", reg, -(se->u.eTemporary.offset));
					break;
				default: internal("load: unexpected entryType"); exit(1);
			}
			return;
		}
	}
	else {
		/* Variable passed ByReference? */
		if (se->entryType == ENTRY_PARAMETER && se->u.eParameter.mode == PASS_BY_REFERENCE) {
			code("\tmov\tsi,word ptr [bp+%d]", se->u.eParameter.offset);
			if (SizeOfInteger(a) || isOfTypeArray)
				code("\tmov\t%s,word ptr [si]", reg);
			else
				code("\tmov\t%s,byte ptr [si]", reg);
			return;
		}
		else {
			switch (se->entryType) {
				case ENTRY_VARIABLE:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\t%s,word ptr [bp-%d]", reg, -(se->u.eVariable.offset));
					else
						code("\tmov\t%s,byte ptr [bp-%d]", reg, -(se->u.eVariable.offset));
					break;
				case ENTRY_PARAMETER:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\t%s,word ptr [bp+%d]", reg, se->u.eParameter.offset);
					else
						code("\tmov\t%s,byte ptr [bp+%d]", reg, se->u.eParameter.offset);
					break;
				case ENTRY_TEMPORARY:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\t%s,word ptr [bp-%d]", reg, -(se->u.eTemporary.offset));
					else
						code("\tmov\t%s,byte ptr [bp-%d]", reg, -(se->u.eTemporary.offset));
					break;
				default: internal("load: unexpected entryType"); exit(1);
			}
			return;
		}
	}
}

void store(char *reg, char *a)
{
	SymbolEntry *se;
	char buf[BUFLEN], *p, *q;
	
	/* s is an array expression */
	if (a[0] == '[') {
		strcpy(buf, a);
		q = buf;
		q++;
		p = q;
		while (*p != ']')
			p++;
		*p = '\0';
		load("di", q);
		if (SizeOfInteger(a))
			code("\tmov\tword ptr [di],%s", reg);
		else
			code("\tmov\tbyte ptr [di],%s", reg);
		return;
	}

	se = lookupEntry(a, LOOKUP_ALL_SCOPES, true);
	/* Local or non-local variable? */
	if (currentScope->nestingLevel != se->nestingLevel) {
		getAR(a);
		/* Variable passed ByReference? */
		if (se->entryType == ENTRY_PARAMETER && se->u.eParameter.mode == PASS_BY_REFERENCE) {
			code("\tmov\tsi,word ptr [si+%d]", se->u.eParameter.offset);
			if (SizeOfInteger(a) || isOfTypeArray)
				code("\tmov\tword ptr [si],%s", reg);
			else
				code("\tmov\tbyte ptr [si],%s", reg);
			return;
		}
		else {
			switch (se->entryType) {
				case ENTRY_VARIABLE:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\tword ptr [si-%d],%s", -(se->u.eVariable.offset), reg);
					else
						code("\tmov\tbyte ptr [si-%d],%s", -(se->u.eVariable.offset), reg);
					break;
				case ENTRY_PARAMETER:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\tword ptr [si+%d],%s", se->u.eParameter.offset, reg);
					else
						code("\tmov\tbyte ptr [si+%d],%s", se->u.eParameter.offset, reg);
					break;
				case ENTRY_TEMPORARY:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\tword ptr [si-%d],%s", -(se->u.eTemporary.offset), reg);
					else
						code("\tmov\tbyte ptr [si-%d],%s", -(se->u.eTemporary.offset), reg);
					break;
				default: internal("store: unexpected entryType"); exit(1);
			}
			return;
		}
	}
	else {
		/* Variable passed ByReference? */
		if (se->entryType == ENTRY_PARAMETER && se->u.eParameter.mode == PASS_BY_REFERENCE) {
			code("\tmov\tsi,word ptr [bp+%d]", se->u.eParameter.offset);
			if (SizeOfInteger(a) || isOfTypeArray)
				code("\tmov\tword ptr [si],%s", reg);
			else
				code("\tmov\tbyte ptr [si],%s", reg);
			return;
		}
		else {
			switch (se->entryType) {
				case ENTRY_VARIABLE:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\tword ptr [bp-%d],%s", -(se->u.eVariable.offset), reg);
					else
						code("\tmov\tbyte ptr [bp-%d],%s", -(se->u.eVariable.offset), reg);
					break;
				case ENTRY_PARAMETER:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\tword ptr [bp+%d],%s", se->u.eParameter.offset, reg);
					else
						code("\tmov\tbyte ptr [bp+%d],%s", se->u.eParameter.offset, reg);
					break;
				case ENTRY_TEMPORARY:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tmov\tword ptr [bp-%d],%s", -(se->u.eTemporary.offset), reg);
					else
						code("\tmov\tbyte ptr [bp-%d],%s", -(se->u.eTemporary.offset), reg);
					break;
				default: internal("store: unexpected entryType"); exit(1);
			}
			return;
		}
	}
}

void loadAddr(char *reg, char *a)
{
	SymbolEntry *se;
	char buf[BUFLEN], *p, *q;
	
	/* a is an array expression */
	if (a[0] == '[') {
		strcpy(buf, a);
		q = buf;
		q++;
		p = q;
		while (*p != ']')
			p++;
		*p = '\0';
		load(reg, q);
		return;
	}

	se = lookupEntry(a, LOOKUP_ALL_SCOPES, true);
	/* Local or non-local variable? */
	if (currentScope->nestingLevel != se->nestingLevel) {
		getAR(a);
		/* Variable passed ByReference? */
		if (se->entryType == ENTRY_PARAMETER && se->u.eParameter.mode == PASS_BY_REFERENCE) {
			code("\tmov\t%s,word ptr [si+%d]", reg, se->u.eParameter.offset);
			return;
		}
		else {
			switch (se->entryType) {
				case ENTRY_VARIABLE:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tlea\t%s,word ptr [si-%d]", reg, -(se->u.eVariable.offset));
					else
						code("\tlea\t%s,byte ptr [si-%d]", reg, -(se->u.eVariable.offset));
					break;
				case ENTRY_PARAMETER:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tlea\t%s,word ptr [si+%d]", reg, se->u.eParameter.offset);
					else
						code("\tlea\t%s,byte ptr [si+%d]", reg, se->u.eParameter.offset);
					break;
				case ENTRY_TEMPORARY:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tlea\t%s,word ptr [si-%d]", reg, -(se->u.eTemporary.offset));
					else
						code("\tlea\t%s,byte ptr [si-%d]", reg, -(se->u.eTemporary.offset));
					break;
				default: internal("loadAddr: unexpected entryType"); exit(1);
			}
			return;
		}
	}
	else {
		/* Variable passed ByReference? */
		if (se->entryType == ENTRY_PARAMETER && se->u.eParameter.mode == PASS_BY_REFERENCE) {
			code("\tmov\t%s,word ptr [bp+%d]", reg, se->u.eParameter.offset);
			return;
		}
		else {
			switch (se->entryType) {
				case ENTRY_VARIABLE:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tlea\t%s,word ptr [bp-%d]", reg, -(se->u.eVariable.offset));
					else
						code("\tlea\t%s,byte ptr [bp-%d]", reg, -(se->u.eVariable.offset));
					break;
				case ENTRY_PARAMETER:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tlea\t%s,word ptr [bp+%d]", reg, se->u.eParameter.offset);
					else
						code("\tlea\t%s,byte ptr [bp+%d]", reg, se->u.eParameter.offset);
					break;
				case ENTRY_TEMPORARY:
					if (SizeOfInteger(a) || isOfTypeArray)
						code("\tlea\t%s,word ptr [bp-%d]", reg, -(se->u.eTemporary.offset));
					else
						code("\tlea\t%s,byte ptr [bp-%d]", reg, -(se->u.eTemporary.offset));
					break;
				default: internal("load: unexpected entryType"); exit(1);
			}
			return;
		}
	} 	
}

int string_param(char *s)
{
	if (str_num == MAX_NUMBER_OF_STRINGS) {
		internal("Max number of strings reached");
		exit(1);
	}

	strings[str_num] = my_strdup2(s);
	return ++str_num;
}

/*
 * This function converts an element of quad_array[]
 * to x86 assembly
 */
void Quad2Asm(Quad q)
{
	SymbolEntry *se;
	QuadType type = q.type;
	char *x = q.arg1, *y = q.arg2, *z = q.dest;

	switch (type) {
		case PLUS_QUAD:
		case MINUS_QUAD:
			if (SizeOfInteger(x)) {
				load("ax", x);
				load("dx", y);
				switch (type) {
					case PLUS_QUAD:	code("\tadd\tax,dx"); break;
					case MINUS_QUAD: code("\tsub\tax,dx"); break;
					default: break;
				}
				store("ax", z);
				break;
			}
			else {
				load("al", x);
				load("dl", y);
				switch (type) {
					case PLUS_QUAD:	code("\tadd\tal,dl"); break;
					case MINUS_QUAD: code("\tsub\tal,dl"); break;
					default: break;
				}
				store("al", z);
				break;
			}

		case MULT_QUAD:
			if (SizeOfInteger(x)) {
				load("ax", x);
				load("cx", y);
				code("\timul\tcx");
				store("ax", z);
				break;
			}
			else {
				code("\tmov\tah,0");
				load("al", x);
				code("\tmov\tch,0");
				load("cl", y);
				code("\timul\tcx");
				store("al", z);
				break;
			}

		case DIV_QUAD:
		case MOD_QUAD:
			if (SizeOfInteger(x)) {
				load("ax", x);
				code("\tcwd");
				load("cx", y);
				code("\tidiv\tcx");
				store((type==DIV_QUAD) ? "ax" : "dx", z);
				break;
			}
			else {
				code("\tmov\tah,0");
				load("al", x);
				code("\tcwd");
				code("\tmov\tch,0");
				load("cl", y);
				code("\tidiv\tcx");
				store((type==DIV_QUAD) ? "al" : "dl", z);
				break;
			}

		case EQ_QUAD: case NE_QUAD: case GT_QUAD:
		case LT_QUAD: case GE_QUAD: case LE_QUAD:
			if (SizeOfInteger(x)) {
				load("ax", x);
				load("dx", y);
				code("\tcmp\tax,dx");
			} else {
				load("al", x);
				load("dl", y);
				code("\tcmp\tal,dl");
			}
			switch (type) {
				case EQ_QUAD: code("\tje\t%s", label(z)); break;
				case NE_QUAD: code("\tjne\t%s", label(z)); break;
				case GT_QUAD: code("\tjg\t%s", label(z)); break;
				case LT_QUAD: code("\tjl\t%s", label(z)); break;
				case GE_QUAD: code("\tjge\t%s", label(z)); break;
				case LE_QUAD: code("\tjle\t%s", label(z)); break;
				default: internal("no way"); exit(1);
			}
			break;

		case UNIT_QUAD:
			code("%s\tproc\tnear", name(x));
			code("\tpush\tbp");
			code("\tmov\tbp,sp");
			code("\tsub\tsp,%d\n", -currentScope->negOffset);
			funcNameOfScope = my_strdup2(x);
			break;

		case ENDU_QUAD:
			code("%s:\n\tmov\tsp,bp", endof(x));
			code("\tpop\tbp");
			code("\tret");
			code("%s\tendp\n", name(x));
			break;

		case ASSIGN_QUAD:
			if (SizeOfInteger(z)) {
				load("ax", x);
				store("ax", z);
			} else {
				load("al", x);
				store("al", z);
			}
			break;

		case ARRAY_QUAD:
			load("ax", y);
			/* Optimization: avoid imul */
			if (SizeOfInteger(x))
				code("\tshl\tax,1");
			loadAddr("cx", x);
			code("\tadd\tax,cx");
			store("ax", z);
			break;

		case JMP_QUAD:
			code("\tjmp\t%s", label(z));
			break;

		case PAR_QUAD:
			/* String as parameter */
			if (x[0]=='\"') {
				code("\tlea\tsi,@str%d", string_param(x));
				code("\tpush\tsi");
				break;
			}
			/* ByValue or ByReference parameter? */
			if (!strcmp(y, "V")) {
				if (SizeOfInteger(x)) {
					load("ax", x);
					code("\tpush\tax");
				}
				else {
					load("al", x);
					code("\tsub\tsp,1");
					code("\tmov\tsi,sp");
					code("\tmov\tbyte ptr [si],al");
				}
			}
			else {
				loadAddr("si", x);
				code("\tpush\tsi");
			}
			break;

		case CALL_QUAD:
			se = lookupEntry(z, LOOKUP_ALL_SCOPES, true);
			if (se->entryType != ENTRY_FUNCTION)
				internal("CALL_QUAD: no function id");
			else if (se->u.eFunction.resultType == typeVoid)
				code("\tsub\tsp,2");
			updateAL(z);
			code("\tcall\tnear ptr %s", name(z));
			code("\tadd\tsp,%d", GetSizeOfArguments(se)+4);
			break;

		case RET_QUAD:
			code("\tjmp\t%s", endof(funcNameOfScope));
			break;

		case RETV_QUAD:
			if (SizeOfInteger(x)) {
				load("ax", x);
				code("\tmov\tsi,word ptr [bp+6]");
				code("\tmov\tword ptr [si],ax");
			}
			else {
				load("al", x);
				code("\tmov\tsi,word ptr [bp+6]");
				code("\tmov\tbyte ptr [si],al");
			}
			break;

		case NULL_QUAD:
			break;

		default:
			internal("Quad2Asm: Unknown type of Quad\n");
			exit(1);
	}
}

void init_final(char *main_name)
{
	if (!ProduceFinal)
		return;
	funcNameOfMain = my_strdup2(main_name);
	code("xseg\tsegment\tpublic 'code'");
	code("\tassume\tcs:xseg, ds:xseg, ss:xseg");
	code("\torg\t100h\n");
	code("main\tproc\tnear");
	code("\tcall\tnear ptr %s", name(main_name));
	code("\tmov\tax,4C00h");
	code("\tint\t21h");
	code("main\tendp\n");
}

void dump_strings(void)
{
	int i;
	char *p, *q;
	int comma;

	for (i=0; i<str_num; i++) {
		p = strings[i];
		comma = 0;

		fprintf(final_stream, "@str%d\tdb\t", i+1);
		 /* Avoid double quotes */
		++p;
		q = p;
		while (*q != '\0')
			q++;
		*--q = '\0';

		while (*p != '\0') {
			if (comma)
				fprintf(final_stream, ", ");

			if (*p != '\\') {
				fputc('\'', final_stream);
				for (; *p!='\\' && *p!='\0'; p++)
					fputc(*p, final_stream);
				fputc('\'', final_stream);
				comma =1;
				continue;
			}
			/* Escape character */
			if (*p == '\\') {
				p++;
				switch (*p) {
                			case 'n':  fprintf(final_stream, "13, 10"); break;
                			case 't':  fprintf(final_stream, "%d", '\t'); break;
                			case 'r':  fprintf(final_stream, "%d", '\r'); break;
                			case '0':  fprintf(final_stream, "%d", '\0'); break;
                			case '\\': fprintf(final_stream, "%d", '\\'); break;
                			case '\'': fprintf(final_stream, "%d", '\''); break;
                			case '\"': fprintf(final_stream, "%d", '\"'); break;
                			case 'x':  fprintf(final_stream, "%d", hextoint(*(p+1), *(p+2))); p += 2; break;
                			default:   internal("bug at string dumping"); break;
                		}
				++p;
				comma = 1;
				continue;
			}
		}
		if (comma)
			fprintf(final_stream, ", ");
		fprintf(final_stream,"0\n");
		free(strings[i]);
	}
	fprintf(final_stream, "\n");
}

void dump_externs(void)
{
	code("\textrn\t_writeInteger : proc");
	code("\textrn\t_writeByte    : proc");
	code("\textrn\t_writeChar    : proc");
	code("\textrn\t_writeString  : proc");
	code("\textrn\t_readInteger  : proc");
	code("\textrn\t_readByte     : proc");
	code("\textrn\t_readChar     : proc");
	code("\textrn\t_readString   : proc");
	code("\textrn\t_extend       : proc");
	code("\textrn\t_shrink       : proc");
	code("\textrn\t_strlen       : proc");
	code("\textrn\t_strcmp       : proc");
	code("\textrn\t_strcpy       : proc");
	code("\textrn\t_strcat       : proc");
	code("");
}

void end_final(void)
{
	if (!ProduceFinal)
		return;
	dump_strings();
	dump_externs();
	code("xseg\tends");
	code("\tend\tmain");
}

void FlushFinal(void)
{
	long i, j;

	if (!ProduceFinal)
		return;
	for (i=q_off; i<quad_num; ++i) {
		j = i - q_off;          /* Index of Quad number i in array */
		code("@%ld: ", i);
		Quad2Asm(quad_array[j]);
	}
}

