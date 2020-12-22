!Object
isKindOf: aClass	| clas |
	clas <- self class.
	[ clas notNil ] whileTrue:
		[ clas == aClass ifTrue: [ ^ true ].
		  clas <- clas superclass ].
	^ false
!
!Undefined
main	| command |
	[ '-> ' print. command <- String input. command notNil ]
		whileTrue: [ command isEmpty
			ifFalse: [ command doIt print. Char newline print ] ]
!
=String
input	| value c nl |
	" read a line from input "
	value <- ''. nl <- Char newline.
	[ c <- Char input. 
	  c isNil ifTrue: [ ^ nil ]. c ~= nl ] whileTrue:
		[ value <- value + c asString ].
	^ value
!
!Number
to: limit do: aBlock  | i |
		" optimize arithmetic loops "
	i <- self.
	[ i <= limit ] whileTrue: [ aBlock value: i. i <- i + 1 ]
!
!File
readLine	| value  c|
	" read a line from input "
	value <- ''.
	[ c <- self readChar. 
	  c isNil ifTrue: [ ^ nil ]. c ~= Char newline ] whileTrue:
		[ value <- value + c asString ].
	^ value
!
!Parser
skipBlanks  | cc |
	[ cc <- self currentChar.
	  cc notNil and: [ cc isBlank ] ]
			whileTrue: [ index <- index + 1 ].
	(cc notNil and: [ cc = $" ] )
		ifTrue: [ self skipComment ]
!
!Parser
skipComment  | cc |
	[ index <- index + 1.
	  cc <- self currentChar.
	  cc isNil 
		ifTrue: [ ^ self error: 'unterminated comment'].
	  cc ~= $" ] whileTrue: [ nil ].
	self nextChar. self skipBlanks
!
+1 to: 15 do: [:x| x factorial print. Char newline print]
+(5 to: 1 by: -1) do: [:x| x printNl]
/ end of input
