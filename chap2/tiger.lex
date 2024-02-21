%{
#include <string.h>
#include <stdlib.h>
#include "util.h"
#include "tokens.h"
#include "errormsg.h"

int charPos=1;

int yywrap(void)
{
 charPos=1;
 return 1;
}

// 使指针前进，便于报错
void adjust(void)
{
 EM_tokPos=charPos;
 charPos+=yyleng;
}

/* 字符串字面量缓存 */
char* strBuf;
/* 缓存的当前长度 */
int bufLen;
/* 缓存的当前容量 */
int bufCap;

void init_buf() {
  /* 根据约定，不考虑内存泄漏 */
  strBuf = (char*)malloc(16);
  bufCap = 16;
  bufLen = 0;
  /* 将内存都初始化为0，省的手动添加结束符号 */
  memset(strBuf, 0, 16);
}

/* 附加一个字符 */
void add_char(char c)
{
  strBuf[bufLen++] = c;
  if (bufLen == bufCap) {
    /* 如果满了，则扩容到原来的 2 倍 */
    char* newStrBuf = (char*) malloc(bufLen * 2);
    /* 初始化为 0 */
    memset(newStrBuf, 0, bufLen * 2);
    /* 拷贝内容 */
    memcpy(newStrBuf, strBuf, bufLen);
    /* 按照约定，这里不用释放内存，但还是讲究一下罢 */
    free(strBuf);
    strBuf = newStrBuf;
    bufCap *= 2;
  }
}
%}

/* 注释状态 */
%x COMMENT
/* 字符串字面量状态 */
%x STRING_LITERAL

%%
  /* 跳过空白字符 */
[ \t\r]+        {adjust(); continue;}
  /* 到换行符时，增加 line number */
\n	            {adjust(); EM_newline(); continue;}

  /* 符号处理 */
","             {adjust(); return COMMA;}
":"             {adjust(); return COLON;}
";"             {adjust(); return SEMICOLON;}
"("             {adjust(); return LPAREN;}
")"             {adjust(); return RPAREN;}
"["             {adjust(); return LBRACK;}
"]"             {adjust(); return RBRACK;}
"{"             {adjust(); return LBRACE;}
"}"             {adjust(); return RBRACE;}
"."             {adjust(); return DOT;}
"+"             {adjust(); return PLUS;}
"-"             {adjust(); return MINUS;}
"*"             {adjust(); return TIMES;}
"/"             {adjust(); return DIVIDE;}
"="             {adjust(); return EQ;}
"<>"            {adjust(); return NEQ;}
"<"             {adjust(); return LT;}
"<="            {adjust(); return LE;}
">"             {adjust(); return GT;}
">="            {adjust(); return GE;}
"&"             {adjust(); return AND;}
"|"             {adjust(); return OR;}
":="            {adjust(); return ASSIGN;}

  /* 保留字 */
while           {adjust(); return WHILE;}
for             {adjust(); return FOR;}
to              {adjust(); return TO;}
break           {adjust(); return BREAK;}
let             {adjust(); return LET;}
in              {adjust(); return IN;}
end             {adjust(); return END;}
function        {adjust(); return FUNCTION;}
var             {adjust(); return VAR;}
type            {adjust(); return TYPE;}
array           {adjust(); return ARRAY;}
if              {adjust(); return IF;}
then            {adjust(); return THEN;}
else            {adjust(); return ELSE;}
do              {adjust(); return DO;}
of              {adjust(); return OF;}
nil             {adjust(); return NIL;}

  /* 数字字面量 */
[0-9]+	        {adjust(); yylval.ival=atoi(yytext); return INT;}

  /* 根据虎书，tiger 语言中的标识符是 以字母开始，由字母，数字和下划线组成的序列 */
[a-zA-Z][a-zA-Z0-9_]*  {adjust(); yylval.sval = yytext; return ID;}

  /* 注释处理 */
"/*"  {
  adjust();
  /* 处理注释时，进入状态 COMMENT */
  BEGIN(COMMENT);
}

<COMMENT>{
  "*/" {
    adjust();
    /* 回到初始状态 */
    BEGIN(INITIAL);
  }
  \n {
    adjust();
    EM_newline();
  }
  . {
    /* 忽略其他字符 */
    adjust();
  }
}

  /* 字符串字面量处理 */
\"  {
  adjust();
  init_buf();
  BEGIN(STRING_LITERAL);
}

<STRING_LITERAL>{
  \" {
    /* 字面量中的过程不需要 adjust, 因为不是独立的token */
    /* 但需要增加 charPos */
    charPos += yyleng;
    if (bufLen == 0) {
      /* 空字符串需要表示为 "(null)" */
      yylval.sval = "(null)";
    } else {
      yylval.sval = strBuf;
    }
    /* 退出 */
    BEGIN(INITIAL);
    return STRING;
  }

  \n {
    /* 不允许换行 */
    charPos += yyleng;
    EM_error(EM_tokPos, "Illegal new-line");
    yyterminate();
  }

  <<EOF>> {
    /* 不允许 EOF */
    EM_error(EM_tokPos, "Illegal EOF");
    yyterminate();
  }

    /* 转义字符处理, 需要脱去转义符号\ */
  \\n     {charPos += yyleng;add_char('\n');}
  \\t     {charPos += yyleng;add_char('\t');}
  \\r     {charPos += yyleng;add_char('\r');}
  \\b     {charPos += yyleng;add_char('\b');}
  \\f     {charPos += yyleng;add_char('\f');}

  "\\\""  {charPos += yyleng;add_char('"');}
  "\\'"   {charPos += yyleng;add_char('\'');}
  "\\/"   {charPos += yyleng;add_char('/');}
  "\\\\"  {charPos += yyleng;add_char('\\');}

  . {
    charPos += yyleng;
    add_char(yytext[0]);
  }
}

.	 {adjust(); EM_error(EM_tokPos,"illegal token");}
