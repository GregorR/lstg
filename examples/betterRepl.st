" Convenience function "
!String
leftStrip | i |
	i <- 1.
	[i <= self size and: [(self at: i) isBlank]] whileTrue: [i <- i + 1.].
	^self from: i.
!

" Class extendability "
+Object subclass: #ClassExtension variables: #(class)
+Node subclass: #ClassExtensionNode variables: #(instanceVars methods classMethods)

!ClassExtension
for: x
	class <- x.
!

!ClassExtension
extend: str | p node |
	p <- Parser new text: str.
	node <- p parseClassBlock: class class variables.
	node classMethods do: [:m|
		class class addMethod: m text.
	].
	node methods do: [:m|
		class addMethod: m text.
	].
	^ class
!

!Class
extend
	^ClassExtension new for: self
!

!Class
subclass: nm extend: str
	^ self subclass: nm classVariables: (Array new: 0) extend: str
!

!Class
subclass: nm classVariables: cv extend: str | p node c |
	" Parse the extend first to get variables "
	p <- Parser new text: str. " FIXME: Location "
	node <- p parseClassBlock: cv.
	node isNil ifTrue: [^nil].

	" Make the subclass "
	c <- self subclass: nm variables: node instanceVars classVariables: cv.

	" Add the class methods"
	node classMethods do: [:m|
		c class addMethod: m text. " FIXME: Location "
	].

	" Add the methods "
	node methods do: [:m|
		c addMethod: m text. " FIXME: Location "
	].

	^c
!

!ClassExtensionNode
instanceVars: anArray methods: aList classMethods: anotherList
	instanceVars <- anArray.
	methods <- aList.
	classMethods <- anotherList.
!

!ClassExtensionNode
instanceVars
	^instanceVars
!

!ClassExtensionNode
methods
	^methods
!

!ClassExtensionNode
classMethods
	^classMethods
!

" Parser extensions "
!Parser
token
	^token
!

!Parser
lineNum
	^lineNum
!

" Parsers for things other than method bodies "
!Parser
text: aString
	self text: aString instanceVars: (Array new: 0)
!

!Parser
text: aString lineNum: aNumber
	self text: aString lineNum: aNumber instanceVars: (Array new: 0)
!

!Parser
text: aString lineNum: aNumber instanceVars: anArray
	self text: aString instanceVars: anArray.
	lineNum <- aNumber
!

" Read a nestable thing as a string "
!Parser
readStringBlock | begin ln nesting nested push pop c i |
	begin <- index.
	ln <- lineNum.
	token isNil
	ifTrue: [
		nesting <- nil.
	]
	ifFalse: [
		nesting <- token at: 1.
	].
	nested <- Array new: 0.

	push <- [:v|
		nested <- nested with: nesting.
		nesting <- v.
	].
	pop <- [
		nested size = 0 ifTrue: [
			index <- i.
			lineNum <- ln.
			self nextLex.
			^text from: begin to: (i-1)
		].
		nesting <- nested at: nested size.
		nested <- nested from: 1 to: (nested size - 1).
	].

	i <- index.
	[i <= text size] whileTrue: [
		c <- text at: i.

		c = Char newline ifTrue: [ ln <- ln + 1. ].

		c = $' ifTrue: [
			" Search for string end "
			i <- i + 1.
			[i <= text size and: [(text at: i) ~= $']] whileTrue: [
				i <- i + 1.
			].
		].

		c = $" ifTrue: [
			" Just search for the comment end "
			i <- i + 1.
			[i <= text size and: [(text at: i) ~= $"]] whileTrue: [
				i <- i + 1.
			].
		].

		c = $$ ifTrue: [
			" Skip the next character "
			i <- i + 1.
		].

		c = $( ifTrue: [
			push value: c.
		].

		(c = $) and: [nesting = $(]) ifTrue: pop.

		c = $[ ifTrue: [
			push value: c.
		].

		(c = $] and: [nesting = $[]) ifTrue: pop.

		(c = $. and: [nesting isNil]) ifTrue: pop.

		i <- i + 1.
	].

	^nil
!

" Parse a blockalike that contains a class declaration "
!Parser
parseClassBlock: inClassVars | classVars iv ms cms isClassMethod mn mna mb beforeName afterName ln p meth node |
        classVars <- inClassVars.
        classVars isNil ifTrue: [classVars <- (Array new: 0)].
	iv <- classVars + instNames.
	ms <- List new.
	cms <- List new.

	[true] whileTrue: [
		beforeName <- index.
		ln <- lineNum.
		self nextLex.

		tokenType = $|
		ifTrue: [
			" This is instance variable declarations "
			iv <- classVars + self readMethodVariables.
			beforeName <- index.
			ln <- lineNum.
			self nextLex.
		].

		token isNil ifTrue: [
			node <- ClassExtensionNode new instanceVars: iv methods: ms classMethods: cms.
			^node
		].

		" Must be a method declaration "
		isClassMethod <- false.
		token = 'class' ifTrue: [
			" It's a class method "
			isClassMethod <- true.
			beforeName <- index.
			self nextLex.
		].

		" Get the name and arguments "
		argNames <- Array with: #self.
		mn <- self readMethodName.
		mn isNil ifTrue: [^mn].
		afterName <- index - 2.

		tokenType = $[ ifFalse: [
			self error: 'invalid method declaration'.
			^nil
		].

		" Read the method block "
		mb <- self readStringBlock.
		mb isNil ifTrue: [
			self error: 'cannot find end of method'.
			^nil
		].
		mb <- ((text from: beforeName to: afterName) + mb).

		" And pass it to another parser "
		isClassMethod
		ifTrue: [
			p <- Parser new
				text: mb
				lineNum: ln
				instanceVars: classVars.
			meth <- p parse: nil.
			cms add: meth.
		]
		ifFalse: [
			p <- Parser new
				text: mb
				lineNum: ln
				instanceVars: iv.
			meth <- p parse: nil.
			ms add: meth.
		].
	]
!

" Get the rest of the parser content "
!Parser
rest
	token isNil
	ifTrue: [
		^''
	]
	ifFalse: [
		^token + (text from: index).
	].
!

!Parser
setErrBlock: to
	errBlock <- to
!

" The REPL itself "
+Object subclass: #REPL variables: (Array new: 0) classVariables: #(variables inst newInst stepper transferer)

=REPL
repl
	^ self repl: nil
!

=REPL
main | arg doRepl command |
	" go through arguments "
	doRepl <- true.
	[arg <- System arg. arg notNil] whileTrue: [
		(arg at: 1) = $-
		ifTrue: [
			arg = '-v' ifTrue: [ System version printNl. ^0 ].
			(arg = '-h' or: [arg = '--help']) ifTrue: [
				System version printNl.
				'Use: lst [-i image] [-s size] [-d size] [-g] [-v] [-h] [input files] [-r]' printNl.
				'Options:' printNl.
				' -i file: Load an alternate image file.' printNl.
				' -s size|-d size: Sets the static/dynamic GC size.' printNl.
				' -g: Enables debugging mode.' printNl.
				' -v|--version: Shows version message.' printNl.
				' -h|--help: Shows this message.' printNl.
				' -r: Enables the REPL. The REPL is activated by default if no input file is' printNl.
				'     provided. Note that you *must* specify -r if you specify an input file' printNl.
				'     and want a REPL, and it must come *after* the input files.' printNl.
				^0
			].
			((arg = '-s' or: [arg = '-d']) or: [arg = '-i']) ifTrue: [ System arg. ].
			arg = '-r' ifTrue: [ doRepl <- true. ]
		]
		ifFalse: [
			doRepl <- false.
			File fileInREPL: arg.
		].
	].

	doRepl ifTrue: [ self repl. ].
!

=REPL
repl: file | cmd readLine handler line |
	variables <- (Array new: 0).
	inst <- (Object subclass: #REPLInstance) new.
	stepper <- Undefined parseMethod: 'step ^REPL inst step'.
	transferer <- Undefined parseMethod: 'rstep ^REPL transfer'.

	cmd <- ''.
	file isNil
	ifTrue: [
		'  -> ' print.
		readLine <- [line <- String input].
	]
	ifFalse: [
		readLine <- [line <- file readLine].
	].

	handler <- [
		cmd <- (cmd + line + (String newline)) leftStrip.
		cmd <- (self replCmd: cmd andPrint: file isNil) leftStrip.
		cmd = ''
		ifTrue: [
			file isNil ifTrue: ['  -> ' print.].
		]
		ifFalse: [
			file isNil ifTrue: ['...> ' print.].
		].
	].

	[readLine value. line isNil] whileFalse: handler.
	line <- '.'.
	handler value.
!

=REPL
replCmd: cmd andPrint: doPrint | prefix ncmd |
	cmd = '' ifTrue: [^cmd].

	prefix <- cmd at: 1.

	prefix = $| ifTrue: [
		ncmd <- self replVars: cmd.
		^self replCmd: ncmd leftStrip andPrint: doPrint.
	].

	prefix = $. ifTrue: [
		" Empty statement "
		^cmd from: 2.
	].

	^self replCode: cmd andPrint: doPrint
!

=REPL
replCode: icmd andPrint: doPrint | cmd p stmt text res |
	cmd <- icmd.
	p <- Parser new text: cmd instanceVars: (Array new: 0).
	[stmt <- p readStringBlock. stmt isNil] whileFalse: [
		cmd <- p rest from: 2.

		text <- 'step ^' + stmt.
		((globals at: #REPLInstance) addMethod: text) isNil ifFalse: [
			res <- (Context new perform: stepper withArguments: (Array new: 0)).
			doPrint ifTrue: [res printNl.].
			(globals at: #REPLInstance) removeMethod: #step.
		].
	].
	^cmd
!

=REPL
replVars: cmd | p c newC newVars val |
	" Get the new variables "
	p <- Parser new text: cmd instanceVars: (Array new: 0).
	p setErrBlock: [^''].
	p nextLex.
	newVars <- p readMethodVariables.
	p nextLex.
	newVars <- variables + newVars.

	" Make the new instance type "
	c <- globals at: #REPLInstance.
	newC <- Object subclass: #REPLInstance variables: newVars.
	newInst <- newC new.

	" Copy over the variables "
	variables do: [:var|
		var <- var asString.
		c addMethod: 'getv ^' + var.
		newC addMethod: 'setv: x ' + var + ' <- x'.
		(Context new perform: transferer withArguments: (Array new: 0)).
		newC removeMethod: #setv:.
	].
	variables <- newVars.
	inst <- newInst.
	^p rest
!

=REPL
transfer
	newInst setv: inst getv.
!

=REPL
inst
	^inst
!

" And a fileIn for it "
=File
fileInREPL: nm | file |
	file <- self openRead: nm.
	file opened ifFalse: [ ^self error: 'cannot open file ' + nm ].
	file fileInREPL.
	file close.
	^'file in completed'
!

!File
fileInREPL
	^REPL repl: self
!

+REPL main
