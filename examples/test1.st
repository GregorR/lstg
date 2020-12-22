" test class instance variables "
Object subclass: #A variables: #( #a ).
A subclass: #B variables: #( #b ).

A extend [
seta: x [
	a <- x
]

geta [
   ^ a
]
].

B extend [
setb: y [
   b <- y.
   a <- y + 1.
]

getb [
   ^ b
]

test [
   self seta: 3.
   self geta print.
   self setb: 7.
   self geta print.
   self getb print.
   Char newline print
]
].

B new test.
