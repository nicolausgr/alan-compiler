%{
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#include "intermediate.h"
#include "final.h"
#include "error.h"
#include "symbol.h"

SymbolEntry *se, *tempse, *args;
int funcrettype;   /* 0: void, 1: int, 2: byte */

void builtinfunctions();

extern int lineno;

long quad_num = 1, q_off = 1;
Quad quad_array[MAX_QUAD_NUM];
long last_tempvar = 1;

char tempvar[256];
char str_label[256];

char *my_strdup(const char *str);
void yyerror(const char *msg);

/* A simple stack for args in func calls */
int argsOnAir = 0, stackPointer = 0;
#define STACKSIZE 50
SymbolEntry *stack[STACKSIZE];
void push(SymbolEntry *syme);
SymbolEntry *pop();
%}

%token T_byte      "byte"
%token T_else      "else"
%token T_false     "false"
%token T_if        "if"
%token T_int       "int"
%token T_proc      "proc"
%token T_reference "reference"
%token T_return    "return"
%token T_while     "while"
%token T_true      "true"

%token T_eq        "=="
%token T_neq       "!="
%token T_le        "<="
%token T_ge        ">="

%left '|'
%left '&'
%nonassoc T_eq T_neq T_le T_ge '<' '>'
%left '+' '-'
%left '*' '/' '%'
%left UNARY

%union {
	char *string;
	int integer;
	char character;
	struct types{
		enum { TY_void = 0, TY_int, TY_byte, TY_intarray, TY_bytearray } numtypes;
		char place[256];
	} alltypes;
	struct true_false {
		label_list ltrue;
		label_list lfalse;
	} branch;
	struct statements {
		int boolean;
		label_list next;
	} lbool;
	long tmp_quadnum;
	label_list temp_list;
}

%token<string> T_id
%token<integer> T_const
%token<character> T_char
%token<string> T_string

%type<alltypes> expr
%type<alltypes> r_type
%type<alltypes> l_value
%type<alltypes> data_type
%type<alltypes> type
%type<alltypes> func_call

%type<lbool> compound_stmt
%type<lbool> stmt_more
%type<lbool> stmt
%type<lbool> if_tail

%type<branch> cond

%%

program : { initSymbolTable(512); openScope(); builtinfunctions(); }   func_def   { FlushQuads(); FlushFinal(); FreeQuads(); closeScope(); end_final(); }
        ;

func_def : T_id '('   { se = newFunction($1); openScope(); if (currentScope->nestingLevel == 2) init_final($1) }   fpar_list ')' ':' r_type local_def_more   { funcrettype = $7.numtypes; GenQuad(UNIT_QUAD, $1, NULL, NULL); }
           compound_stmt   { backpatch($10.next, quad_num); GenQuad(ENDU_QUAD, $1, NULL, NULL); FlushQuads(); FlushFinal(); FreeQuads(); closeScope(); if (!$10.boolean && funcrettype!=0) yyerror("non-void function returns nothing"); }
         | T_id '('   { se = newFunction($1); openScope(); if (currentScope->nestingLevel == 2) init_final($1) }   ')' ':' r_type local_def_more   { funcrettype = $6.numtypes; GenQuad(UNIT_QUAD, $1, NULL, NULL); }
           compound_stmt   { backpatch($9.next, quad_num); GenQuad(ENDU_QUAD, $1, NULL, NULL); FlushQuads(); FlushFinal(); FreeQuads(); closeScope(); if (!$9.boolean && funcrettype!=0) yyerror("non-void function returns nothing"); }
         ;

local_def_more : /* nothing */
               | local_def local_def_more
               ;

fpar_list : fpar_def fpar_def_more
          ;

fpar_def_more : /* nothing */
              | ',' fpar_def fpar_def_more
              ;

fpar_def : T_id ':' "reference" type   {
                                         switch ($4.numtypes) {
                                         	case TY_int: newParameter($1, typeInteger, PASS_BY_REFERENCE, se); break;
                                         	case TY_byte: newParameter($1, typeChar, PASS_BY_REFERENCE, se); break;
                                         	case TY_intarray: newParameter($1, typeIArray(typeInteger), PASS_BY_REFERENCE, se); break;
                                         	case TY_bytearray: newParameter($1, typeIArray(typeChar), PASS_BY_REFERENCE, se); break;
                                         	default: internal("type error");
                                         }
                                       }
         | T_id ':' type   {
                             if ($3.numtypes==TY_intarray || $3.numtypes==TY_bytearray) yyerror("array passed by value");
                             newParameter($1, ($3.numtypes==TY_int) ? typeInteger : typeChar, PASS_BY_VALUE, se);
                           }
         ;

data_type : "int"   { $$.numtypes = TY_int; }
          | "byte"   { $$.numtypes = TY_byte; }
          ;

type : data_type '[' ']'   { $$.numtypes = ($1.numtypes==TY_int) ? TY_intarray : TY_bytearray; }
     | data_type   { $$.numtypes = $1.numtypes; }
     ;

r_type : data_type   {
                       if ($1.numtypes==TY_int) endFunctionHeader(se, typeInteger);
                       else endFunctionHeader(se, typeChar);
                       $$.numtypes = $1.numtypes;
                     }
       | "proc"   { endFunctionHeader(se, typeVoid); $$.numtypes = TY_void; }
       ;

local_def : func_def
          | var_def
          ;

var_def : T_id ':' data_type '[' T_const ']' ';'   { newVariable($1, typeArray($5, ($3.numtypes==TY_int) ? typeInteger : typeChar)); }
        | T_id ':' data_type ';'   { newVariable($1, ($3.numtypes==TY_int) ? typeInteger : typeChar); }
        ;

stmt : ';'   { $$.boolean = 0; $$.next = empty_list(); }
     | l_value '=' expr ';'   {
                                if ($1.numtypes != $3.numtypes) yyerror("wrong type assignment");
                                else if ($1.numtypes != TY_int && $1.numtypes != TY_byte) yyerror("assignment to array type variable");
                                $$.boolean = 0;
                                GenQuad(ASSIGN_QUAD, $3.place, NULL, $1.place);
                                $$.next = empty_list();
                              }
     | compound_stmt   { $$.boolean = $1.boolean; $$.next = $1.next; }
     | func_call ';'   { $$.boolean = 0; $$.next = empty_list(); }
     | "if" '(' cond ')'   { backpatch($3.ltrue, quad_num); }   if_tail   { $$.next = $6.next; $$.boolean = $6.boolean; }
     | "while"   { $<tmp_quadnum>$ = quad_num; }   '(' cond ')'   { backpatch($4.ltrue, quad_num); }   stmt   { $$.boolean = 0; backpatch($7.next, $<tmp_quadnum>2); snprintf(str_label, 255, "%ld", $<tmp_quadnum>2); GenQuad(JMP_QUAD, NULL, NULL, str_label); $$.next = $4.lfalse; }
     | "return" expr ';'   {
                             if (funcrettype == 0)
                             	yyerror("proc should not return any value");
                             else if ((funcrettype==1 && $2.numtypes!=TY_int) || (funcrettype==2 && $2.numtypes!=TY_byte))
                             	yyerror("unmatched type of return value");
                             $$.boolean = 1;
                             GenQuad(RETV_QUAD, $2.place, NULL, NULL);
                             GenQuad(RET_QUAD, NULL, NULL, NULL);
                           }
     | "return" ';'   { if (funcrettype != 0) yyerror("non-void function must return a value"); $$.boolean = 0; GenQuad(RET_QUAD, NULL, NULL, NULL); }
     ;

if_tail : stmt "else"   { $<temp_list>$ = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*")); backpatch($<branch>-2.lfalse, quad_num); }   stmt   { $$.boolean = $1.boolean && $4.boolean; $$.next = merge(merge($<temp_list>3, $1.next),$4.next); }
        | stmt   { $$.boolean = 0; $$.next = merge($<branch>-2.lfalse, $1.next); }
        ;

compound_stmt : '{' stmt_more '}'   { $$.boolean = $2.boolean; $$.next = $2.next; }
              | '{' '}'   { $$.boolean = 0; $$.next = empty_list(); }
              ;

stmt_more : stmt   { backpatch($1.next, quad_num); }   stmt_more   { $$.boolean = $1.boolean || $3.boolean; $$.next = $3.next; }
          | stmt   { $$.boolean = $1.boolean; $$.next = $1.next; }
          ;

func_call : T_id '('   {
                          tempse = lookupEntry($1, LOOKUP_ALL_SCOPES, true);
                          if (tempse == NULL)
                          	exit(1);
                          else if (tempse->entryType == ENTRY_FUNCTION) {
                          	if (argsOnAir > 0)
                          		push(args);
                          	args = tempse->u.eFunction.firstArgument;
                          	argsOnAir++;
                          }
                          else
                          	yyerror("function identifier expected");
                       }
            expr_list ')'  {
                             if (argsOnAir > 1)
                             	args = pop();
                             argsOnAir--;
                             tempse = lookupEntry($1, LOOKUP_ALL_SCOPES, true);
                             if (tempse == NULL)
                             	exit(1);
                             else if (tempse->entryType == ENTRY_FUNCTION) {
                             	if (tempse->u.eFunction.firstArgument == NULL)
					yyerror("function must have no parameters");
                             	else {
                             		if (tempse->u.eFunction.resultType == typeInteger)
                             			$$.numtypes = TY_int;
                             		else if (tempse->u.eFunction.resultType == typeChar)
                             			$$.numtypes = TY_byte;
                             		else
                             			$$.numtypes = TY_void;

                             		if (tempse->u.eFunction.resultType != typeVoid) {
                             			next_tempvar_name(tempvar);
                             			GenQuad(PAR_QUAD, tempvar, "RET", NULL);
						if (tempse->u.eFunction.resultType == typeInteger)
		                     			newTemporary(typeInteger);
		                     		else
		                     			newTemporary(typeChar);
                             			sprintf($$.place,"%s",tempvar);
                             		}
                             	}
                             }
                             else
                             	yyerror("function identifier expected");
                             GenQuad(CALL_QUAD, NULL, NULL, $1);
                           }

          | T_id '(' ')'   {
                             tempse = lookupEntry($1, LOOKUP_ALL_SCOPES, true);
                             if (tempse == NULL)
                             	exit(1);
                             else if (tempse->entryType == ENTRY_FUNCTION) {
                             	if (tempse->u.eFunction.firstArgument != NULL) yyerror("function needs parameters");
                             	else {
                             		if (tempse->u.eFunction.resultType == typeInteger)
                             			$$.numtypes = TY_int;
                             		else if (tempse->u.eFunction.resultType == typeChar)
                             			$$.numtypes = TY_byte;
                             		else
                             			$$.numtypes = TY_void;

                             		if (tempse->u.eFunction.resultType != typeVoid) {
                             			next_tempvar_name(tempvar);
                             			GenQuad(PAR_QUAD, tempvar, "RET", NULL);
						if (tempse->u.eFunction.resultType == typeInteger)
		                     			newTemporary(typeInteger);
		                     		else
		                     			newTemporary(typeChar);
                             			sprintf($$.place,"%s",tempvar);
                             		}
                             	}
                             }
                             else
                             	yyerror("function identifier expected");
                             GenQuad(CALL_QUAD, NULL, NULL, $1);
                           }
          ;

expr_list : expr   { if (args == NULL) yyerror("function must have no parameters");
                     if (   (args->u.eParameter.type == typeInteger && $1.numtypes != TY_int)
                         || (args->u.eParameter.type == typeChar    && $1.numtypes != TY_byte)
                         ||((args->u.eParameter.type->kind == TYPE_ARRAY || args->u.eParameter.type->kind == TYPE_IARRAY)
                               && (   (args->u.eParameter.type->refType == typeInteger && $1.numtypes != TY_intarray)
                                   || (args->u.eParameter.type->refType == typeChar && $1.numtypes != TY_bytearray)
                                  )
                           )
                        ) yyerror("unmatched parameters");
                     if (args->u.eParameter.mode == PASS_BY_VALUE)
                     	GenQuad(PAR_QUAD, $1.place, "V", NULL);
                     else
                     	GenQuad(PAR_QUAD, $1.place, "R", NULL);
                     args = args->u.eParameter.next;
                   }
            expr_more
          ;

expr_more : /* nothing */   { if (args != NULL) yyerror("more parameters needed"); }
          | ',' expr   { if (args == NULL) yyerror("function has less parameters");
                         if (   (args->u.eParameter.type == typeInteger && $2.numtypes != TY_int)
                             || (args->u.eParameter.type == typeChar    && $2.numtypes != TY_byte)
                             ||((args->u.eParameter.type->kind == TYPE_ARRAY || args->u.eParameter.type->kind == TYPE_IARRAY)
                                   && (   (args->u.eParameter.type->refType == typeInteger && $2.numtypes != TY_intarray)
                                       || (args->u.eParameter.type->refType == typeChar && $2.numtypes != TY_bytearray)
                                      )
                               )
                            ) yyerror("unmatched parameters");
                         if (args->u.eParameter.mode == PASS_BY_VALUE)
                     		GenQuad(PAR_QUAD, $2.place, "V", NULL);
                    	 else
                     		GenQuad(PAR_QUAD, $2.place, "R", NULL);
                         args = args->u.eParameter.next;
                       }
            expr_more
          ;

expr : T_const   { $$.numtypes = TY_int; sprintf($$.place,"%d", $1); }
     | T_char   {
                  $$.numtypes = TY_byte;
                  switch ($1) {
                  	case '\n':  sprintf($$.place, "\'%s\'", "\\n"); break;
                  	case '\t':  sprintf($$.place, "\'%s\'", "\\t"); break;
                  	case '\r':  sprintf($$.place, "\'%s\'", "\\r"); break;
                  	case '\0':  sprintf($$.place, "\'%s\'", "\\0"); break;
                  	case '\\': sprintf($$.place, "\'%s\'", "\\\\"); break;
                  	case '\'': sprintf($$.place, "\'%s\'", "\\\'"); break;
                  	case '\"': sprintf($$.place, "\'%s\'", "\\\""); break;
                  	default:   sprintf($$.place, "\'%c\'", $1); break;
                  }
                }
     | l_value   { $$.numtypes = $1.numtypes; sprintf($$.place,"%s",$1.place); }
     | '(' expr ')'   { $$.numtypes = $2.numtypes; sprintf($$.place,"%s",$2.place); }
     | func_call   { if ($1.numtypes == TY_void) yyerror("proc cannot be used as expression"); $$.numtypes=$1.numtypes; sprintf($$.place,"%s",$1.place); }
     | '+' expr %prec UNARY   { if ($2.numtypes != TY_int) yyerror("expected int after +"); $$.numtypes = $2.numtypes; sprintf($$.place,"%s",$2.place); }
     | '-' expr %prec UNARY   {
                                if ($2.numtypes != TY_int) yyerror("expected int after -");
                                $$.numtypes = $2.numtypes;
                                next_tempvar_name(tempvar);
                                sprintf($$.place,"%s",tempvar);
                                GenQuad(MINUS_QUAD, "0", $2.place, $$.place);
                                newTemporary(typeInteger);
                              }
     | expr '+' expr   {
                         if ($1.numtypes != $3.numtypes) yyerror("operands of different type in +");
                         else if ($1.numtypes == TY_intarray || $1.numtypes == TY_bytearray) yyerror("operands of array type in +");
                         else $$.numtypes = $1.numtypes;
                         next_tempvar_name(tempvar); sprintf($$.place,"%s",tempvar);
                         GenQuad(PLUS_QUAD, $1.place, $3.place, $$.place);
                         if ($$.numtypes == TY_int)
                         	newTemporary(typeInteger);
                         else
                         	newTemporary(typeChar);
                       }
     | expr '-' expr   {
                         if ($1.numtypes != $3.numtypes) yyerror("operands of different type in -");
                         else if ($1.numtypes == TY_intarray || $1.numtypes == TY_bytearray) yyerror("operands of array type in -");
                         else $$.numtypes = $1.numtypes;
                         next_tempvar_name(tempvar); sprintf($$.place,"%s",tempvar);
                         GenQuad(MINUS_QUAD, $1.place, $3.place, $$.place);
                         if ($$.numtypes == TY_int)
                         	newTemporary(typeInteger);
                         else
                         	newTemporary(typeChar);
                       }
     | expr '*' expr   {
                         if ($1.numtypes != $3.numtypes) yyerror("operands of different type in *");
                         else if ($1.numtypes == TY_intarray || $1.numtypes == TY_bytearray) yyerror("operands of array type in *");
                         else $$.numtypes = $1.numtypes;
                         next_tempvar_name(tempvar); sprintf($$.place,"%s",tempvar);
                         GenQuad(MULT_QUAD, $1.place, $3.place, $$.place);
                         if ($$.numtypes == TY_int)
                         	newTemporary(typeInteger);
                         else
                         	newTemporary(typeChar);
                       }
     | expr '/' expr   {
                         if ($1.numtypes != $3.numtypes) yyerror("operands of different type in /");
                         else if ($1.numtypes == TY_intarray || $1.numtypes == TY_bytearray) yyerror("operands of array type in /");
                         else $$.numtypes = $1.numtypes;
                         next_tempvar_name(tempvar); sprintf($$.place,"%s",tempvar);
                         GenQuad(DIV_QUAD, $1.place, $3.place, $$.place);
                         if ($$.numtypes == TY_int)
                         	newTemporary(typeInteger);
                         else
                         	newTemporary(typeChar);
                       }
     | expr '%' expr   {
                         if ($1.numtypes != $3.numtypes) yyerror("operands of different type in %");
                         else if ($1.numtypes == TY_intarray || $1.numtypes == TY_bytearray) yyerror("operands of array type in %");
                         else $$.numtypes = $1.numtypes;
                         next_tempvar_name(tempvar); sprintf($$.place,"%s",tempvar);
                         GenQuad(MOD_QUAD, $1.place, $3.place, $$.place);
                         if ($$.numtypes == TY_int)
                         	newTemporary(typeInteger);
                         else
                         	newTemporary(typeChar);
                       }
     ;

l_value : T_id '[' expr ']'   {
                                tempse = lookupEntry($1, LOOKUP_ALL_SCOPES, true);
                                if (tempse == NULL)
                                	exit(1);
                                else if (tempse->entryType == ENTRY_VARIABLE) {
                                	if (tempse->u.eVariable.type->kind == TYPE_ARRAY || tempse->u.eVariable.type->kind == TYPE_IARRAY)
                                		$$.numtypes = (tempse->u.eVariable.type->refType == typeInteger) ? TY_int : TY_byte;
                                        else
                                		yyerror("array identifier expected");
                                }
                                else if (tempse->entryType == ENTRY_PARAMETER) {
                                	if (tempse->u.eParameter.type->kind == TYPE_ARRAY || tempse->u.eParameter.type->kind == TYPE_IARRAY)
                                		$$.numtypes = (tempse->u.eParameter.type->refType == typeInteger) ? TY_int : TY_byte;
                                        else
                                		yyerror("array identifier expected");
                                }
                                else
                                	yyerror("array identifier expected");

				if ($3.numtypes != TY_int)
					yyerror("offset of array shoulf be of type integer");

                                next_tempvar_name(tempvar); sprintf($$.place,"%s",tempvar);
                                GenQuad(ARRAY_QUAD, $1, $3.place, $$.place);
                                newTemporary(typePointer(($$.numtypes==TY_int) ? typeInteger : typeChar));
                                sprintf($$.place,"[%s]",tempvar);
                              }
        | T_id   {
                   tempse = lookupEntry($1, LOOKUP_ALL_SCOPES, true);
                   if (tempse == NULL)
                   	exit(1);
                   if (tempse->entryType == ENTRY_VARIABLE) {
                   	if (tempse->u.eVariable.type->kind == TYPE_ARRAY || tempse->u.eVariable.type->kind == TYPE_IARRAY)
                        	$$.numtypes = (tempse->u.eVariable.type->refType == typeInteger) ? TY_intarray : TY_bytearray;
                        else
                        	$$.numtypes = (tempse->u.eVariable.type == typeInteger) ? TY_int : TY_byte;
                   }
                   else if (tempse->entryType == ENTRY_PARAMETER) {
                   	if (tempse->u.eParameter.type->kind == TYPE_ARRAY || tempse->u.eParameter.type->kind == TYPE_IARRAY)
                        	$$.numtypes = (tempse->u.eParameter.type->refType == typeInteger) ? TY_intarray : TY_bytearray;
                        else
                        	$$.numtypes = (tempse->u.eParameter.type == typeInteger) ? TY_int : TY_byte;
                   }
                   else
                      yyerror("variable/parameter identifier expected");

                   sprintf($$.place,"%s",$1);
                 }
        | T_string   { $$.numtypes = TY_bytearray; sprintf($$.place,"\"%s\"",$1); }
        ;

cond : "true"    {
                   $$.ltrue = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*")); 
                   $$.lfalse = empty_list();
                 }
     | "false"   {
                   $$.ltrue = empty_list(); 
                   $$.lfalse = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*"));
                 }
     | '(' cond ')'   { $$.ltrue = $2.ltrue; $$.lfalse = $2.lfalse; }
     | '!' cond %prec UNARY   { $$.ltrue = $2.lfalse; $$.lfalse = $2.ltrue; }
     | expr "==" expr   {
                          if ($1.numtypes != $3.numtypes)
                          	yyerror("expressions of different type around ==");
                          $$.ltrue = make_list(GenQuad(EQ_QUAD, $1.place, $3.place, "*")); 
                          $$.lfalse = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*"));
                        }
     | expr "!=" expr   {
                          if ($1.numtypes != $3.numtypes)
                          	yyerror("expressions of different type around !=");
                          $$.ltrue = make_list(GenQuad(NE_QUAD, $1.place, $3.place, "*"));
                          $$.lfalse = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*"));
                        }
     | expr '<' expr    {
                          if ($1.numtypes != $3.numtypes)
                          	yyerror("expressions of different type around <");
                          $$.ltrue = make_list(GenQuad(LT_QUAD, $1.place, $3.place, "*"));
                          $$.lfalse = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*"));
                        }
     | expr '>' expr    {
                          if ($1.numtypes != $3.numtypes)
                          	yyerror("expressions of different type around >");
                          $$.ltrue = make_list(GenQuad(GT_QUAD, $1.place, $3.place, "*"));
                          $$.lfalse = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*"));
                        }
     | expr "<=" expr   {
                          if ($1.numtypes != $3.numtypes)
                          	yyerror("expressions of different type around <=");
                          $$.ltrue = make_list(GenQuad(LE_QUAD, $1.place, $3.place, "*"));
                          $$.lfalse = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*"));
                        }
     | expr ">=" expr   {
                          if ($1.numtypes != $3.numtypes)
                          	yyerror("expressions of different type around >=");
                          $$.ltrue = make_list(GenQuad(GE_QUAD, $1.place, $3.place, "*"));
                          $$.lfalse = make_list(GenQuad(JMP_QUAD, NULL, NULL, "*"));
                        }
     | cond '&'   { backpatch($1.ltrue,quad_num); }   cond   { $$.lfalse = merge($1.lfalse, $4.lfalse); $$.ltrue = $4.ltrue; }
     | cond '|'   { backpatch($1.lfalse,quad_num); }   cond   { $$.ltrue = merge($1.ltrue, $4.ltrue); $$.lfalse = $4.lfalse; }
     ;

%%

/************ Functions for intermediate code generation ************/

long GenQuad(QuadType q, char *a1, char *a2, char *dest)
{
	if (quad_num-q_off == MAX_QUAD_NUM) {
		internal("maximum number of quads reached");
		exit(1);
	}
	quad_array[quad_num-q_off].type = q;
	quad_array[quad_num-q_off].arg1 = my_strdup(a1 ? a1 : "−");
	quad_array[quad_num-q_off].arg2 = my_strdup(a2 ? a2 : "−");
	quad_array[quad_num-q_off].dest = my_strdup(dest ? dest : "−");

	return quad_num++;
}

void FlushQuads(void)
{
	long i, j;
	char *s;

	/* QUADS OPTIMIZATION */
	for (i = q_off+1; i < quad_num; i++) {
		j = i - q_off;

		/* Delete ret quad before endu quad */
		if (quad_array[j].type == ENDU_QUAD && quad_array[j-1].type == RET_QUAD)
			quad_array[j-1].type = NULL_QUAD;

		/* Conditional and non-conditional jumps simplification */
		/* CANCEL BECAUSE OF JUMPS OUT OF RANGE */
/*
		if (quad_array[j].type == JMP_QUAD && atoi(quad_array[j-1].dest) == i+1) {
			switch (quad_array[j-1].type) {
				case EQ_QUAD:
					quad_array[j-1].type = NE_QUAD;
					quad_array[j-1].dest = my_strdup(quad_array[j].dest);
					quad_array[j].type = NULL_QUAD;
					break;
				case NE_QUAD:
					quad_array[j-1].type = EQ_QUAD;
					quad_array[j-1].dest = my_strdup(quad_array[j].dest);
					quad_array[j].type = NULL_QUAD;
					break;
				case GT_QUAD:
					quad_array[j-1].type = LE_QUAD;
					quad_array[j-1].dest = my_strdup(quad_array[j].dest);
					quad_array[j].type = NULL_QUAD;
					break;
				case LT_QUAD:
					quad_array[j-1].type = GE_QUAD;
					quad_array[j-1].dest = my_strdup(quad_array[j].dest);
					quad_array[j].type = NULL_QUAD;
					break;
				case GE_QUAD:
					quad_array[j-1].type = LT_QUAD;
					quad_array[j-1].dest = my_strdup(quad_array[j].dest);
					quad_array[j].type = NULL_QUAD;
					break;
				case LE_QUAD:
					quad_array[j-1].type = GT_QUAD;
					quad_array[j-1].dest = my_strdup(quad_array[j].dest);
					quad_array[j].type = NULL_QUAD;
					break;
				default: break;
			}
		}
*/

		/* Inverse form of copy propagation transformation */
		if (quad_array[j].type == ASSIGN_QUAD && *(quad_array[j].arg1) == '$') {
			if (!strcmp(quad_array[j].arg1, quad_array[j-1].dest)) {
				quad_array[j-1].dest = my_strdup(quad_array[j].dest);
				quad_array[j].type = NULL_QUAD;
			}
		}
	}

	if (!ProduceInterm)
		return;

	for (i = q_off; i < quad_num; i++) {
		j = i - q_off;
		switch(quad_array[j].type) {
			case PLUS_QUAD:   s = "+"; break;
			case MINUS_QUAD:  s = "−"; break;
			case MULT_QUAD:   s = "*"; break;
			case DIV_QUAD:    s = "/"; break;
			case MOD_QUAD:    s = "%"; break;
			case EQ_QUAD:     s = "="; break;
			case NE_QUAD:     s = "<>"; break;
			case GT_QUAD:     s = ">"; break;
			case LT_QUAD:     s = "<"; break;
			case GE_QUAD:     s = ">="; break;
			case LE_QUAD:     s = "<="; break;
			case UNIT_QUAD:   s = "unit"; break;
			case ENDU_QUAD:   s = "endu"; break;
			case ASSIGN_QUAD: s = ":="; break;
			case ARRAY_QUAD:  s = "array"; break;
			case JMP_QUAD:    s = "jump"; break;
			case PAR_QUAD:    s = "par"; break;
			case CALL_QUAD:   s = "call"; break;
			case RET_QUAD:    s = "ret"; break;
			case RETV_QUAD:   s = "retv"; break;
			case NULL_QUAD:   continue;
			default:
				internal("FlushQuads: unknown quad type");
				exit(1);
		}
		fprintf(imm_stream, "%ld: %s, %s, %s, %s\n", i, s,
			quad_array[j].arg1, quad_array[j].arg2, quad_array[j].dest);
	}
}

void FreeQuads(void)
{
	long i, j;

	/* Free memory used by the quads */
	for (i = q_off; i < quad_num; i++) {
		j = i - q_off;
		free(quad_array[j].arg1);
		free(quad_array[j].arg2);
		free(quad_array[j].dest);
	}

	q_off = quad_num;
}

void backpatch(label_list list, long val)
{
	label_list next;
	char tmp[256];

	for (; list != NULL; list = next) {
		snprintf(tmp, 255, "%ld", val);
		free(quad_array[list->label-q_off].dest);
		quad_array[list->label-q_off].dest = my_strdup(tmp);
		next = list->next;
		free(list);
	}
}

label_list make_list(long val)
{
	label_list q;

	if ((q = malloc(sizeof(label_list_t))) == NULL) {
		internal("memory allocation failure");
		exit(1);
	}
	q->label = val;
	q->next = NULL;
	return q;
}

label_list empty_list()
{
	label_list q;
	q = NULL;
	return q;
}

label_list merge(label_list p, label_list q)
{
	label_list head;

	if (!p)
		return q;

	/* Get last element of p */
	for (head = p; p->next != NULL; p = p->next)
		;
	p->next = q;
	return head;
}

void next_tempvar_name(char *tempvar)
{
	sprintf(tempvar,"$%ld", last_tempvar);
	last_tempvar++;
}


/************ Add library functions to symbol table ************/

void builtinfunctions()
{
	se = newFunction("writeInteger");
	forwardFunction(se);
	openScope();
	newParameter("n", typeInteger, PASS_BY_VALUE, se);
	endFunctionHeader(se, typeVoid);
	closeScope();

	se = newFunction("writeByte");
	forwardFunction(se);
	openScope();
	newParameter("b", typeChar, PASS_BY_VALUE, se);
	endFunctionHeader(se, typeVoid);
	closeScope();

	se = newFunction("writeChar");
	forwardFunction(se);
	openScope();
	newParameter("b", typeChar, PASS_BY_VALUE, se);
	endFunctionHeader(se, typeVoid);
	closeScope();

	se = newFunction("writeString");
	forwardFunction(se);
	openScope();
	newParameter("s", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	endFunctionHeader(se, typeVoid);
	closeScope();

	se = newFunction("readInteger");
	forwardFunction(se);
	openScope();
	endFunctionHeader(se, typeInteger);
	closeScope();

	se = newFunction("readByte");
	forwardFunction(se);
	openScope();
	endFunctionHeader(se, typeChar);
	closeScope();

	se = newFunction("readChar");
	forwardFunction(se);
	openScope();
	endFunctionHeader(se, typeChar);
	closeScope();

	se = newFunction("readString");
	forwardFunction(se);
	openScope();
	newParameter("n", typeInteger, PASS_BY_VALUE, se);
	newParameter("s", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	endFunctionHeader(se, typeVoid);
	closeScope();

	se = newFunction("extend");
	forwardFunction(se);
	openScope();
	newParameter("b", typeChar, PASS_BY_VALUE, se);
	endFunctionHeader(se, typeInteger);
	closeScope();

	se = newFunction("shrink");
	forwardFunction(se);
	openScope();
	newParameter("i", typeInteger, PASS_BY_VALUE, se);
	endFunctionHeader(se, typeChar);
	closeScope();

	se = newFunction("strlen");
	forwardFunction(se);
	openScope();
	newParameter("s", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	endFunctionHeader(se, typeInteger);
	closeScope();

	se = newFunction("strcmp");
	forwardFunction(se);
	openScope();
	newParameter("s1", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	newParameter("s2", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	endFunctionHeader(se, typeInteger);
	closeScope();

	se = newFunction("strcpy");
	forwardFunction(se);
	openScope();
	newParameter("trg", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	newParameter("src", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	endFunctionHeader(se, typeVoid);
	closeScope();

	se = newFunction("strcat");
	forwardFunction(se);
	openScope();
	newParameter("trg", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	newParameter("src", typeIArray(typeChar), PASS_BY_REFERENCE, se);
	endFunctionHeader(se, typeVoid);
	closeScope();
}

/* Implementation of the simple stack for args in func calls */
void push(SymbolEntry *syme)
{
	if (stackPointer == STACKSIZE) {
		internal("args stack overflow");
		exit(1);
	}
	stack[stackPointer++] = syme;
}

SymbolEntry *pop()
{
	stackPointer--;
	if (stackPointer < 0) {
		internal("args stack underflow");
		exit(1);
	}
	return stack[stackPointer];
}

char *my_strdup(const char *str)
{
	int n = strlen(str) + 1;
	char *dup = malloc(n);

	if (dup)
		strcpy(dup, str);
	else
		internal("memory allocation failure");

	return dup;
}

void yyerror (const char * msg)
{
	fprintf(stderr, "Error, line %d: %s\n", lineno, msg);
	exit(1);
}

int parse ()
{
	return yyparse();
}

