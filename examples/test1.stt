/ test class instance variables
+Object subclass: #A variables: #( #a )
+A subclass: #B variables: #( #b )
!A
seta: x
	a <- x
!
!A
geta
   ^ a
!
!B
setb: y
   b <- y.
   a <- y + 1.
!
!B
getb
   ^ b
!
!B
test
   self seta: 3.
   self geta print.
   self setb: 7.
   self geta print.
   self getb print.
   Char newline print
!
+B new test
