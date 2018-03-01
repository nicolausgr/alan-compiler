%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "intermediate.h"
#include "final.h"
#include "parser.h"

#define T_eof   0

void yyerror(const char *msg);
char hextochar(char msb, char lsb);

int ProduceInterm = 0;
int ProduceFinal = 0;
extern int parse();

int lineno = 1;
int comments_open = 0;
FILE *imm_stream = NULL;
FILE *final_stream = NULL;
int i, j;
char *p;
%}

L [a-zA-Z]
D [0-9]
H [0-9a-fA-F]
E \\n|\\t|\\r|\\0|\\\\|\\\'|\\\"|\\x{H}{H}

%x COMMENT

%%

"byte"        { return T_byte; }
"else"        { return T_else; }
"false"       { return T_false; }
"if"          { return T_if; }
"int"         { return T_int; }
"proc"        { return T_proc; }
"reference"   { return T_reference; }
"return"      { return T_return; }
"while"       { return T_while; }
"true"        { return T_true; }

   /* id */
{L}({L}|{D}|_)*       {
                        p = (char *) calloc(strlen(yytext)+1, sizeof(char));
                        strcpy(p, yytext);
                        yylval.string = p;
                        return T_id;
                      }
   /* constant */
{D}+                  {
                        yylval.integer = atoi(yytext);
                        return T_const;
                      }
   /* character */
\'{E}\'|\'.\'         {
                        if (yytext[1] != '\\')
                        	yylval.character = yytext[1];
                        else {
                        	switch (yytext[2]) {
                        		case 'n': yylval.character = '\n'; break;
                        		case 't': yylval.character = '\t'; break;
                        		case 'r': yylval.character = '\r'; break;
                        		case '0': yylval.character = '\0'; break;
                        		case '\\': yylval.character = '\\'; break;
                        		case '\'': yylval.character = '\''; break;
                        		case '\"': yylval.character = '\"'; break;
                        		case 'x': yylval.character = hextochar(yytext[3], yytext[4]); break;
                        		default: break;
                        	}
                        }
                        return T_char;
                      }
   /* string */
\"([^\"\n]|\\\")*\"   {
                        p = (char *) calloc(strlen(yytext)+1, sizeof(char));
                        i = 1; j = 0;
                        while (yytext[i] != '\0') {
                        	if (1)				/* (yytext[i] != '\\')   // to be put on the final code if needed */
                        		p[j++] = yytext[i++];
                        	else {
                        		i++;
                        		switch (yytext[i]) {
                        			case 'n': p[j++] = '\n'; i++; break;
                        			case 't': p[j++] = '\t'; i++; break;
                        			case 'r': p[j++] = '\r'; i++; break;
                        			case '0': p[j++] = '\0'; i++; break;
                        			case '\\': p[j++] = '\\'; i++; break;
                        			case '\'': p[j++] = '\''; i++; break;
                        			case '\"': p[j++] = '\"'; i++; break;
                        			case 'x': p[j++] = hextochar(yytext[i+1], yytext[i+2]); i += 3; break;
                        			default: p[j++] = yytext[i++]; break;
                        		}
                        	}
                        }
                        p[--j] = '\0';
                        yylval.string = p;
                        return T_string;
                      }

"="    { return yytext[0]; }
"+"    { return yytext[0]; }
"-"    { return yytext[0]; }
"*"    { return yytext[0]; }
"/"    { return yytext[0]; }
"%"    { return yytext[0]; }
"!"    { return yytext[0]; }
"&"    { return yytext[0]; }
"|"    { return yytext[0]; }
"=="   { return T_eq; }
"!="   { return T_neq; }
"<"    { return yytext[0]; }
">"    { return yytext[0]; }
"<="   { return T_le; }
">="   { return T_ge; }

"("    { return yytext[0]; }
")"    { return yytext[0]; }
"["    { return yytext[0]; }
"]"    { return yytext[0]; }
"{"    { return yytext[0]; }
"}"    { return yytext[0]; }
","    { return yytext[0]; }
":"    { return yytext[0]; }
";"    { return yytext[0]; }

[ \t\r]+            { /* nothing */ }
\n                  { lineno++; }
\-\-(.)*            { /* nothing */ }
"(*"                { comments_open++; BEGIN(COMMENT); }
<COMMENT>"(*"       { comments_open++; }
<COMMENT>"*)"       { if (--comments_open == 0) BEGIN(INITIAL); }
<COMMENT>\n         { lineno++; }
<COMMENT>"("        { /* nothing */ }
<COMMENT>"*"        { /* nothing */ }
<COMMENT>[^(*\n]+   { /* nothing */ }

<<EOF>>	  { return T_eof; }
.         { yyerror("lexical error"); }

%%

char hextochar(char msb, char lsb)
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

int main (int argc, char **argv)
{
	int ret;
	int interm, fin;
	char fname[256], *ext;
	extern int ProduceInterm;
	extern int ProduceFinal;

	if (argc == 2) {
		strncpy(fname, argv[1], 256);
		if (strlen(argv[1]) > 255)
			fname[255] = '\0';

		ext = strstr(fname, ".alan");
		if (!ext) {
			fprintf(stderr, "Input filename's extension must be .alan\n");
			exit(1);
		}

		yyin = fopen(fname, "r");
		if (!yyin) {
			fprintf(stderr, "ERROR: Cannot open alan source file \'%s\'\n", fname);
			exit(1);
		}

		strcpy(ext, ".imm\0");
		imm_stream = fopen(fname, "w");
		if (!imm_stream) {
			fprintf(stderr, "ERROR: Cannot open intermediate code file \'%s\'\n", fname);
			exit(1);
		}
		
		strcpy(ext, ".asm\0");
		final_stream = fopen(fname, "w");
		if (!final_stream) {
			fprintf(stderr, "ERROR: Cannot open assembly code file \'%s\'\n", fname);
			exit(1);
		}

		ProduceInterm = 1;
		ProduceFinal = 1;
		ret = parse();
		fclose(yyin);
		if (ProduceInterm)
			fclose(imm_stream);
		if (ProduceFinal)
			fclose(final_stream);
		return ret;
	}
	else if (argc == 3 && (!strcmp(argv[1], "-i") || !strcmp(argv[1], "-f"))) {
		strncpy(fname, argv[2], 256);
		if (strlen(argv[2]) > 255)
			fname[255] = '\0';

		ext = strstr(fname, ".alan");
		if (!ext) {
			fprintf(stderr, "Input filename's extension must be .alan\n");
			exit(1);
		}

		if (argv[1][1] == 'i') {
			interm = 1;
			fin = 0;
		}
		else {
			interm = 0;
			fin = 1;
		}

		yyin = fopen(fname, "r");
		if (!yyin) {
			fprintf(stderr, "ERROR: Cannot open alan source file \'%s\'\n", fname);
			exit(1);
		}

		if (interm) {
			strcpy(ext, ".imm\0");
			imm_stream = fopen(fname, "w");
			if (!imm_stream) {
				fprintf(stderr, "ERROR: Cannot open intermediate code file \'%s\'\n", fname);
				exit(1);
			}
		}

		if (fin) {
			strcpy(ext, ".asm\0");
			final_stream = fopen(fname, "w");
			if (!final_stream) {
				fprintf(stderr, "ERROR: Cannot open assembly code file \'%s\'\n", fname);
				exit(1);
			}
		}

		ProduceInterm = interm;
		ProduceFinal = fin;
		ret = parse();
		fclose(yyin);
		if (ProduceInterm)
			fclose(imm_stream);
		if (ProduceFinal)
			fclose(final_stream);
		return ret;
	}
	else {
		printf("Usage: ./alan [option] <program-name>.alan\n\n");
		printf("option:\n");
		printf("\t-i    : Produce only intermediate code\n");
		printf("\t-f    : Produce only final code\n");
		printf("\t[none]: Produce both intermediate and final codes\n");
		return 1;
	}
}

