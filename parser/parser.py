"""TOKEN types"""
ID, INTEGER, AND, OR, XOR, NOT, LPAREN, RPAREN, IFF, EOF = (
  'ID', 'INTEGER', 'AND', 'OR', 'XOR', 'NOT', '(', ')', 'IFF', 'EOF'
)

SYM_TO_TOKEN = {
  "&": AND,
  "|": OR,
  "~": NOT,
  "!": NOT,
  "^": XOR,
  "(": LPAREN,
  ")": RPAREN
}

class AST(object):
  def __init__(self):
    self.tree_value = 1

class UnaryOp(AST):
  def __init__(self, op, right):
    self.tree_value = 1 + right.tree_value
    self.right = right
    self.token = self.op = op

class BinOp(AST):
  def __init__(self, left, op, right):
    self.tree_value = 1 + left.tree_value + right.tree_value
    self.left = left
    self.token = self.op = op
    self.right = right

class Num(AST):
  def __init__(self, token):
    self.token = token
    self.value = token.value
    AST.__init__(self)

class Variable(AST):
  def __init__(self, token):
    self.token = token
    self.value = token.value
    AST.__init__(self)



class Token(object):
  def __init__(self, type, value):
    self.type = type
    self.value = value

  def __str__(self):
    return 'Token({type}, {value})'.format(
      type=self.type,
      value=repr(self.value)
    )

  def __repr__(self):
    return self.__str__()

class Lexer(object):
  def __init__(self, input):
    self.text = input
    self.pos = 0
    self.current_char = self.text[self.pos]

  def error(self):
    raise Exception('Invalid character')

  def advance(self):
    self.pos += 1
    if self.pos > len(self.text) - 1:
      self.current_char = None
    else:
      self.current_char = self.text[self.pos]

  def skip_whitespace(self):
    while (self.current_char is not None and self.current_char.isspace()):
      self.advance()

  def integer(self):
    num_str = ''
    while (self.current_char is not None and self.current_char.isdigit()):
      num_str += self.current_char
      self.advance()

    return int(num_str)

  def id(self):
    id_str = ''
    while (self.current_char is not None and self.current_char.isalpha()):
      id_str += self.current_char
      self.advance()

    return id_str

  def big_equal(self):
    while (self.current_char is not None and self.current_char == "="):
      self.advance()

  def get_next_token(self):
    while (self.current_char is not None):
      if self.current_char.isspace():
        self.skip_whitespace()
        continue

      if self.current_char.isdigit():
        return Token(INTEGER, self.integer())

      if self.current_char.isalpha():
        return Token(ID, self.id())

      if self.current_char == "<":
        self.advance()
        if self.current_char == "=":
          self.big_equal()
          if self.current_char == ">":
            self.advance()
            return Token(IFF, "<=>");
        error()

      sym_token = SYM_TO_TOKEN[self.current_char]
      if sym_token:
        self.advance()
        return Token(sym_token, self.current_char)

      self.error()

    return Token(EOF, None)

class Parser(object):
  """
  prog: expr EOF
  expr: term ((AND | OR | XOR | IFF) term)*
  term: NOT? factor
  factor: INTEGER | ID | LPAREN expr RPAREN
  """
  def __init__(self, lexer):
    self.lexer = lexer
    self.current_token = self.lexer.get_next_token()
    self.all_variables = set()
    self.ast = self.parse()

  def error(self):
    raise Exception('Invalid syntax')

  def eat(self, token_type):
    if self.current_token.type == token_type:
      self.current_token = self.lexer.get_next_token()
    else:
      self.error()

  def factor(self):
    token = self.current_token
    if token.type == INTEGER:
      self.eat(INTEGER)
      return Num(token)
    elif token.type == ID:
      self.eat(ID)
      self.all_variables.add(token.value)
      return Variable(token)
    elif token.type == LPAREN:
      self.eat(LPAREN)
      result = self.expr()
      self.eat(RPAREN)
      return result
    else:
      self.error()

  def term(self):
    token = self.current_token
    if token.type == NOT:
      self.eat(NOT)
      return UnaryOp(token, self.factor())
    else:
      return self.factor()

  def expr(self):
    result = self.term()

    while self.current_token.type in (OR, AND, XOR, IFF):
      token = self.current_token
      if token.type in (OR, AND, XOR, IFF):
        self.eat(token.type)
        result = BinOp(result, token, self.term())

    return result

  def parse(self):
    return self.expr()

class Optimizer(object):
  def __init__(self, ast):
    self.ast = ast

  def reduce(ast):
    pass

###############################################################################
#                                                                             #
#  INTERPRETER                                                                #
#                                                                             #
###############################################################################

class NodeVisitor(object):
  def visit(self, node):
    method_name = 'visit_' + type(node).__name__
    visitor = getattr(self, method_name, self.generic_visit)
    return visitor(node)

  def generic_visit(self, node):
    raise Exception('No visit_{} method'.format(type(node).__name__))


class Interpreter(NodeVisitor):
  def __init__(self, parser):
    self.parser = parser

  def visit_BinOp(self, node):
    if node.op.type == OR:
      return self.visit(node.left) | self.visit(node.right)
    elif node.op.type == AND:
      return self.visit(node.left) & self.visit(node.right)
    elif node.op.type == XOR:
      return self.visit(node.left) ^ self.visit(node.right)
    elif node.op.type == IFF:
      return ~(self.visit(node.left) ^ self.visit(node.right)) & 1

  def visit_UnaryOp(self, node):
    if node.op.type == NOT:
      return self.visit(node.right) ^ 1

  def visit_Num(self, node):
    return node.value

  def visit_Variable(self, node):
    try:
      return self.env[node.value]
    except KeyError:
      raise Exception("No value for variable: %s" % node.value)

  def interpret(self, env):
    self.env = env
    return self.visit(self.parser.ast)

class TruthTable(object):
  def __init__(self, text):
    lexer = Lexer(text)
    parser = Parser(lexer)
    print "AST value: %s" % str(parser.ast.tree_value)
    interpreter = Interpreter(parser)
    variables = list(parser.all_variables)
    variables.sort()
    headers = variables + [text]
    self.table = [headers]
    for i in reversed(range(0, 2 ** len(variables))):
      binary = list(("{:0" + str(len(variables)) + "b}").format(i))
      var_map = dict(zip(variables, map(int, binary)))
      res = interpreter.interpret(var_map)
      self.table.append(binary + [str(res)])
      if res:
        print(binary + [str(res)])

  def __str__(self):
    s = [[str(e) for e in row] for row in self.table]
    lens = [max(map(len, col)) for col in zip(*s)]
    fmt = '\t'.join('{{:{}}}'.format(x) for x in lens)
    f_table = [fmt.format(*row) for row in s]
    return '\n'.join(f_table)

def main():
  while True:
    try:
      text = raw_input('spi> ')
    except EOFError:
      break
    if not text:
      continue

    table = TruthTable(text)
    print(table)


if __name__ == '__main__':
  main()

