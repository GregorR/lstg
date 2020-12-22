/  Concordance program
+Object subclass: #Concordance variables: #(dict)
!Concordance
word: word occursOnLine: line
	(dict includes: word)
		ifFalse: [ dict at: word put: List new ].
	((dict at: word) includes: line)
		ifFalse: [ (dict at: word) addLast: line]
!
!Concordance
fileIn	| text lineNumber words |
	lineNumber <- 0.
	[ text <- String input.  text notNil ]
		whileTrue: [ 
			text <- text collect: [ :c | c lowerCase ].
			lineNumber <- lineNumber + 1.
			words <- text break: ' .,'.
			words do: [ :word | self word: word 
				occursOnLine: lineNumber ] ]
!
!Concordance
displayDictionary
	dict binaryDo: [ :word :lines |
		word print.
		lines do: [ :line | ' ' print. line print ].
		Char newline print ]
!
!Concordance
run
	dict <- Dictionary new.
	self fileIn.
	self displayDictionary
!
+'enter test lines, followed by end-of-file'
+Concordance new run
/ end
