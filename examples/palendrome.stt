/ A simple palendrome tester
/ first, add a method to class String
!String
isPalendrome | string |
	string <- self select: [:c | c isAlphabetic ].
	string <- string collect: [:c | c lowerCase ].
	^ string = string reverse
!
/ next, add a new class with a few test cases
+Object subclass: #Pal
!Pal
test: aString
	aString print.
	' : ' print.
	aString isPalendrome print.
	Char newline print.
!
!Pal
runTests
	self test: 'A Man, A Plan, A Canal, Panama'.
	self test: 'Rats live on no Evil star'.
	self test: 'This is not a palendrome'
!
+Pal new runTests
/ end of file
