"
Copyright (C) 2020,        Gregor Richards

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the ""Software""), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
"

" Convenience functions "
!String
leftStripCt | i |
	i <- 1.
	[i <= self size and: [(self at: i) isBlank]] whileTrue: [i <- i + 1.].
	^i.
!

!String
leftStrip
	^self from: self leftStripCt.
!

!String
occurrencesOf: aChar
	^(self select: [:c| c = aChar]) size
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
	p <- Parser new fromExtendBlock: str instanceVars: class instanceVariables.
	node <- p parseClassBlock: class class variables.
	node classMethods do: [:m|
		class class addMethod: m text fromFile: m file atLine: m line.
	].
	node methods do: [:m|
		class addMethod: m text fromFile: m file atLine: m line.
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
	p <- Parser new fromExtendBlock: str instanceVars: (Array new: 0).
	node <- p parseClassBlock: cv.
	node isNil ifTrue: [^nil].

	" Make the subclass "
	c <- self subclass: nm variables: node instanceVars classVariables: cv.

	" Add the class methods"
	node classMethods do: [:m|
		c class addMethod: m text fromFile: m file atLine: m line.
	].

	" Add the methods "
	node methods do: [:m|
		c addMethod: m text fromFile: m file atLine: m line.
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
				fileName: fileName
				lineNum: ln
				text: mb
				instanceVars: classVars.
			meth <- p parse: nil.
			cms add: meth.
		]
		ifFalse: [
			p <- Parser new
				fileName: fileName
				lineNum: ln
				text: mb
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
+Object subclass: #REPL variables: #(variables fileName cmd lineNum inst newInst transferer)
+Object subclass: #REPLFileReader variables: #(file)

=REPLFileReader
fileIn: nm | fr |
	fr <- REPLFileReader new withFile: nm.
	fr fileIn.
!

!REPLFileReader
withFile: nm
	file <- File openRead: nm.
	file opened ifFalse: [ ^self error: 'cannot open file ' + nm ].
	^ self
!

!REPLFileReader
fileIn
	REPL new repl: file.
	file close.
	file <- nil.
!

!REPL
repl
	^ self repl: nil
!

=REPL
main | fileInMeth arg doRepl rf command |
	fileInMeth <- Undefined parseMethod: 'fileIn: x ^x fileIn' fromFile: 'REPL' atLine: 1.

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

			arg = '--lst' ifTrue: [
				" read in a standard LST file "
				doRepl <- false.
				File fileIn: System arg.
			].

			arg = '-r' ifTrue: [
				System version printNl.
				self new repl.
			].
		]
		ifFalse: [
			doRepl <- false.
			rf <- REPLFileReader new withFile: arg.
			Context new perform: fileInMeth withArguments: (Array with: nil with: rf).
		].
	].

	doRepl ifTrue: [
		System version printNl.
		self new repl.
	].
!

!REPL
repl: file | readLine handler line i |
	" Initial state "
	file isNil
	ifTrue: [
		fileName <- '(input)'.
		readLine <- [line <- String input].
	]
	ifFalse: [
		fileName <- file name.
		readLine <- [line <- file readFile].
	].
	lineNum <- 1.
	cmd <- ''.

	variables <- (Array new: 0).
	inst <- (Object subclass: #REPLInstance) new.
	transferer <- Undefined parseMethod: 'transfer: x ^x transfer' fromFile: 'REPL' atLine: 1.

	" Initial prompt "
	file isNil ifTrue: [
		'  -> ' print.
	].

	" Main handler "
	handler <- [
		cmd <- cmd + line + String newline.

		" Run command(s) "
		self replCmdAndPrint: file isNil.

		" Prompt "
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

!REPL
trimCmd: i
	lineNum <- lineNum + ((cmd from: 1 to: i-1) occurrencesOf: Char newline).
	cmd <- cmd from: i.
!

!REPL
leftStripCmd | i |
	self trimCmd: cmd leftStripCt.
!

!REPL
replCmdAndPrint: doPrint | prefix i |
	self leftStripCmd.

	cmd = '' ifTrue: [^self].

	prefix <- cmd at: 1.

	prefix = $| ifTrue: [
		self replVars: cmd.
		^self replCmdAndPrint: doPrint
	].

	prefix = $. ifTrue: [
		" Empty statement "
		cmd <- cmd from: 2.
		^self replCmdAndPrint: doPrint
	].

	self replCodeAndPrint: doPrint.
	^self replCmdAndPrint: doPrint
!

!REPL
replCodeAndPrint: doPrint | p ln stmt text meth res |
	p <- Parser new fileName: fileName lineNum: lineNum text: cmd instanceVars: (Array new: 0).
	[
		ln <- lineNum.
		stmt <- p readStringBlock.
		stmt isNil
	] whileFalse: [
		self trimCmd: p index.

		text <- 'step ^' + stmt.
		meth <- (globals at: #REPLInstance) addMethod: text fromFile: fileName atLine: ln.
		meth isNil ifFalse: [
			res <- (Context new perform: meth withArguments: (Array with: inst)).
			doPrint ifTrue: [res printNl.].
			(globals at: #REPLInstance) removeMethod: #step.
		].
	].
!

!REPL
replVars | p c newC newVars val |
	" Get the new variables "
	p <- Parser new fileName: fileName lineNum: lineNum text: cmd instanceVars: (Array new: 0).
	p setErrBlock: [^''].
	p nextLex.
	newVars <- p readMethodVariables.
	self trimCmd: p index.
	newVars <- variables + newVars.

	" Make the new instance type "
	c <- globals at: #REPLInstance.
	newC <- Object subclass: #REPLInstance variables: newVars.
	newInst <- newC new.

	" Copy over the variables "
	variables do: [:var|
		var <- var asString.
		c addMethod: 'getv ^' + var fromFile: 'REPL' atLine: 1.
		newC addMethod: 'setv: x ' + var + ' <- x' fromFile: 'REPL' atLine: 1.
		(Context new perform: transferer withArguments: (Array with: nil with: self)).
		newC removeMethod: #setv:.
	].
	variables <- newVars.
	inst <- newInst.
!

!REPL
transfer
	newInst setv: inst getv.
!

!REPL
inst
	^inst
!

" replace the main entry function "
!Undefined
main
	Char initialize.
	self initSingletons.
	REPL main.
!

+REPL main
