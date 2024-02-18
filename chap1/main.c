#include <stdio.h>
#include <string.h>

#include "prog1.h"
#include "slp.h"
#include "util.h"

#define max(a, b) ((a) > (b) ? (a) : (b))

/**
 *  第一题
 */

int maxargs(A_stm);

int maxargsExp(A_exp exp) {
  switch (exp->kind) {
    case A_idExp:
      return 1;
    case A_numExp:
      return 1;
    case A_opExp:
      return max(maxargsExp(exp->u.op.left), maxargsExp(exp->u.op.right));
    case A_eseqExp:
      return max(maxargs(exp->u.eseq.stm), maxargsExp(exp->u.eseq.exp));
    default:
      assert(FALSE);
  }
}

/**
 * 获取 print 函数的参数个数
 */
int maxargsList(A_expList list) {
  /*
  A_expList 中，kind 为 A_pairExpList 表示有 2 个及以上的元素，为 A_lastExpList
  表示 只有最后一个元素
  */
  switch (list->kind) {
    case A_pairExpList:
      return maxargsExp(list->u.pair.head) + maxargsList(list->u.pair.tail);
    case A_lastExpList:
      return maxargsExp(list->u.last);
    default:
      break;
  }
}

int maxargs(A_stm stm) {
  switch (stm->kind) {
    case A_compoundStm:
      return max(maxargs(stm->u.compound.stm1), maxargs(stm->u.compound.stm2));
    case A_assignStm:
      return maxargsExp(stm->u.assign.exp);
    case A_printStm:
      return maxargsList(stm->u.print.exps);
    default:
      assert(FALSE);
  }
}

/**
 * 第二题
 */

typedef struct table* Table_;
struct table {
  string id;
  int value;
  Table_ tail;
};

Table_ Table(string id, int value, struct table* tail) {
  Table_ t = checked_malloc(sizeof(*t));
  t->id = id;
  t->value = value;
  t->tail = tail;
  return t;
}

Table_ update(Table_ tail, string id, int value) {
  Table_ t = checked_malloc(sizeof(*tail));
  t->id = id;
  t->value = value;
  t->tail = tail;
  return t;
}

int lookup(Table_ t, string key) {
  assert(t != NULL);
  if (strcmp(t->id, key) == 0) {
    return t->value;
  } else {
    return lookup(t->tail, key);
  }
}

/**
 * 表示表达式的返回值和其所关联的变量表
 */
struct IntAndTable {
  int i;
  Table_ t;
};

struct IntAndTable calculate(A_binop, A_exp, A_exp);
Table_ interpList(A_expList_);

struct IntAndTable interpExp(A_exp e, Table_ t) {
  switch (e->kind) {
    case A_idExp: {
      struct IntAndTable iat = {lookup(t, e->u.id), t};
      return iat;
    }
    case A_numExp: {
      struct IntAndTable iat = {e->u.num, t};
      return iat;
    }
    case A_opExp: {
      // calculate 函数尚未实现
      struct IntAndTable iat = calculate(e->u.op.oper, e->u.op.left, e->u.op.right, t);
    }
    default:
      break;
  }
}

Table_ interpStm(A_stm stm, Table_ t) {
  switch (stm->kind) {
    case A_compoundStm:
      t = interpStm(stm->u.compound.stm1, t);
      t = interpStm(stm->u.compound.stm2, t);
      return t;
    case A_assignStm:
      struct IntAndTable iat = interpExp(stm->u.assign.exp, t);
      return update(iat.t, stm->u.assign.id, iat.i);
    case A_printStm:
      // interpList 函数尚未实现
      return interpList(stm->u.print.exps);
    default:
      break;
  }
}

int main() { printf("第一题测试答案：%d\n", maxargs(prog())); }
