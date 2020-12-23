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
	i := 1.
	[i <= self size and: [(self at: i) isBlank]] whileTrue: [i := i + 1.].
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
+ParserNode subclass: #ExtendBlockNode variables: #(tempSlot steps)
+ParserNode subclass: #ExtendBlockStmtNode.
+ExtendBlockStmtNode subclass: #ExtendInstanceVarsNode variables: #(vars)
+ExtendBlockStmtNode subclass: #ExtendMethodNode variables: #(fileName lineNum text)
+ExtendBlockStmtNode subclass: #ExtendExtraMethodNode variables: #(target fileName lineNum text)
+ExtendBlockStmtNode subclass: #ExtendClassVarDeclNode variables: #(target value)

!Parser
readExtendBlock | steps tempSlot lnum |
	steps := List new.

	" The extend block itself takes two arguments "
	tempSlot := tempNames size.
	maxTemps := maxTemps max: tempSlot + 2.

	" Now read in the content "
	lnum := lineNum.
	self nextLex.
	[ tokenType notNil and: [ tokenType ~= $] ] ] whileTrue: [
		steps add: self readExtendStatement
	].
	tokenType isNil ifTrue: [
		^self error: 'Invalid extend block!'
	].
	^(ExtendBlockNode at: lnum) tempSlot: tempSlot steps: steps
!

!Parser
readExtendStatement | preIndex preLine ret |
	" Easiest case: Instance variables "
	tokenType = $| ifTrue: [ ^self readExtendInstanceVars ].

	" Otherwise, we'll only know when we get to an interesting token "
	preIndex := index - token size.
	preLine := lineNum.

	[self tokenIsName or: [self tokenIsKeyword]] whileTrue: [
		self nextLex.
	].

	index := preIndex.
	lineNum := preLine.

	" Now decide based on what we have "
	tokenType = $[ ifTrue: [ ^self readExtendMethod ].
	token = '>>' ifTrue: [ ^self readExtendExtraMethod ].
	self tokenIsArrow ifTrue: [ ^self readExtendClassVarDecl ].
	^self error: 'Invalid extend statement'
!

!Parser
readExtendInstanceVars | ret |
	ret := (ExtendInstanceVarsNode at: lineNum) vars: self readMethodVariables.
	self nextLex.
	^ret
!

!Parser
readExtendMethod | preIndex ln name methodText |
	preIndex := index.
	ln := lineNum.
	self nextLex.
	self readMethodName.
	tokenType = $[ ifFalse: [
		^self error: 'Invalid method name'
	].
	name := text from: preIndex to: index - 2.

	" Now read the entire method as a string "
	methodText := self readStringBlock.
	methodText isNil ifTrue: [
		^self error: 'Invalid method body'
	].

	" And put it together "
	methodText := name + ' ' + methodText.
	^(ExtendMethodNode at: ln) fileName: fileName lineNum: ln text: methodText.
!

!Parser
readExtendExtraMethod | target ln node |
	self nextLex.

	" The target has to be in a unary continuation due to precedence "
	target := self unaryContinuation: self readTerm.

	" And at this point we must find >> "
	token = '>>' ifFalse: [
		^self error: 'Invalid foreign method extension'
	].
	self skipBlanks.
	ln := lineNum.

	" The rest is the method itself "
	node := self readExtendMethod.
	^(ExtendExtraMethodNode at: ln) target: target fileName: fileName lineNum: ln text: node text
!

!Parser
readExtendClassVarDecl | target value |
	" The target is just a name "
	self nextLex.
	self tokenIsName ifFalse: [
		^self error: 'Invalid class variable declaration'
	].
	target := token.
	self nextLex.

	" After that, it *must* have the arrow "
	self tokenIsArrow ifFalse: [
		^self error: 'Invalid class variable declaration'
	].
	self nextLex.

	" The rest is just a normal expression "
	value := self readExpression.

	" After which it *must* have a . "
	tokenType = $. ifFalse: [
		^self error: 'Invalid class variable declaration'
	].
	self nextLex.

	^(ExtendClassVarDeclNode at: lineNum) target: target value: value
!

" Nodes for class extendability "
!ExtendBlockNode
tempSlot: xtempSlot steps: xsteps
	tempSlot := xtempSlot.
	steps := xsteps.
!

!ExtendInstanceVarsNode
vars: xvars
	vars := xvars.
!

!ExtendMethodNode
fileName: xfileName lineNum: xlineNum text: xtext
	fileName := xfileName.
	lineNum := xlineNum.
	text := xtext.
!

!ExtendMethodNode
text
	^text
!

!ExtendExtraMethodNode
target: xtarget fileName: xfileName lineNum: xlineNum text: xtext
	target := xtarget.
	fileName := xfileName.
	lineNum := xlineNum.
	text := xtext.
!

!ExtendClassVarDeclNode
target: xtarget value: xvalue
	target := xtarget.
	value := xvalue.
!

" Compile an extend block into an actual block "
!ExtendBlockNode
compile: encoder block: inBlock | patchLocation |
	" An extend block is just a special kind of block "
	super compile: encoder.
	encoder genHigh: 4 low: (encoder genLiteral: lineNum).
	encoder genHigh: 12 low: tempSlot.
	patchLocation := encoder genVal: 0.

	" Our actual code chooses which step to perform based on user input "

	" 0: Push nil so we'll have something if it all goes wrong "
	encoder genHigh: 5 low: 10.

	" 1: Class variable names "
	self compile: encoder ifEq: 1 then: [
		self compileClassVarNames: encoder.
	].

	" 2: Instance variables names "
	self compile: encoder ifEq: 2 then: [
		self compileInstanceVarNames: encoder.
	].

	" 3: Class variable values "
	self compile: encoder ifEq: 3 then: [
		self compileClassVarValues: encoder.
	].

	" 4: Add methods "
	self compile: encoder ifEq: 4 then: [
		self compileMethods: encoder.
	].

	encoder genHigh: 15 low: 2. " return top of stack "
	encoder patch: patchLocation
!

" Compile a decision in an extend block of which step to perform "
!ExtendBlockNode
compile: encoder ifEq: val then: block | patchLocation |
	" First, check if it's equal "
	encoder genHigh: 3 low: tempSlot. " Compare the given step "
	encoder genHigh: 5 low: val. " Against the comparator step "
	encoder genHigh: 11 low: 3. " 11:3 is optimized == "

	" Branch if it's false "
	encoder genHigh: 15 low: 8. " branch if false instruction "
	patchLocation := encoder genVal: 0.

	" Pop the nil that's in the stack by default "
	encoder genHigh: 15 low: 5.

	" Now the actual steps "
	block value.

	" Return what it generated "
	encoder genHigh: 15 low: 2. " return "

	" And return to this point if it was false "
	encoder patch: patchLocation.
!

" General function for compiling lists "
!ExtendBlockNode
compileList: encoder step: block | add |
	" Make a list "
	encoder genHigh: 4 low: (encoder genLiteral: List).
	encoder pushArgs: 1.
	encoder genHigh: 8 low: 1.
	encoder genHigh: 9 low: (encoder genLiteral: #new).

	" Then add the elements "
	add := encoder genLiteral: #add:.
	steps do: [:step|
		block value: step value: add.
	].
!

" 1: Generate variable names "
!ExtendBlockNode
compileClassVarNames: encoder
	self compileList: encoder step: [:step :add|
		step compileClassVarName: encoder addMethod: add.
	].
!

!ExtendBlockStmtNode
compileClassVarName: encoder addMethod: add
	" Nothing "
	^self
!

!ExtendBlockStmtNode
compileListAdd: encoder addMethod: add value: block
	" Duplicate the list "
	encoder genHigh: 15 low: 4.

	" Generating the argument "
	encoder pushArgs: 2.
	block value.
	encoder popArgs: 1.

	" Call "
	encoder genHigh: 8 low: 2.
	encoder genHigh: 9 low: add.

	" Then pop our extraneous return "
	encoder genHigh: 15 low: 5.
!

!ExtendClassVarDeclNode
compileClassVarName: encoder addMethod: add
	self compileListAdd: encoder addMethod: add value: [
		encoder genHigh: 4 low: (encoder genLiteral: target asSymbol).
	].
!

" 2: Generate instance variable names "
!ExtendBlockNode
compileInstanceVarNames: encoder
	" Just go through each step, looking for one that generates instance variables "
	steps do: [:step|
		(step compileInstanceVarName: encoder) ifTrue: [^self].
	].

	" If we made it here, then nothing generated. Just return nil. "
	encoder genHigh: 5 low: 10.
!

!ExtendBlockStmtNode
compileInstanceVarName: encoder
	^false
!

!ExtendInstanceVarsNode
compileInstanceVarName: encoder
	encoder genHigh: 4 low: (encoder genLiteral: vars).
	^true
!

" 3: Generate variable values "
!ExtendBlockNode
compileClassVarValues: encoder
	self compileList: encoder step: [:step :add|
		step compileClassVarValue: encoder addMethod: add.
	].
!

!ExtendBlockStmtNode
compileClassVarValue: encoder addMethod: add
	^self
!

!ExtendClassVarDeclNode
compileClassVarValue: encoder addMethod: add
	self compileListAdd: encoder addMethod: add value: [
		value compile: encoder block: true.
	].
!

" 4: Generate methods "
!ExtendBlockNode
compileMethods: encoder
	" Put the target on the stack "
	encoder genHigh: 3 low: tempSlot + 1.

	" Then generate methods "
	steps do: [:step|
		step compileMethod: encoder.
	].
!

!ExtendBlockStmtNode
compileMethod: encoder
	^self
!

!ExtendMethodNode
compileMethod: encoder
	" The target is on the stack, so dup it "
	encoder genHigh: 15 low: 4.

	" Push our arguments "
	encoder pushArgs: 4.
	encoder genHigh: 4 low: (encoder genLiteral: text).
	encoder genHigh: 4 low: (encoder genLiteral: fileName).
	encoder genHigh: 4 low: (encoder genLiteral: lineNum).
	encoder popArgs: 3.

	" Make the call "
	encoder genHigh: 8 low: 4.
	encoder genHigh: 9 low: (encoder genLiteral: #addMethod:fromFile:atLine:).

	" And pop the resulting method "
	encoder genHigh: 15 low: 5.
!

!ExtendExtraMethodNode
compileMethod: encoder
	" Get our target "
	target compile: encoder block: true.

	" Push our arguments "
	encoder pushArgs: 4.
	encoder genHigh: 4 low: (encoder genLiteral: text).
	encoder genHigh: 4 low: (encoder genLiteral: fileName).
	encoder genHigh: 4 low: (encoder genLiteral: lineNum).
	encoder popArgs: 3.

	" Make the call "
	encoder genHigh: 8 low: 4.
	encoder genHigh: 9 low: (encoder genLiteral: #addMethod:fromFile:atLine:).

	" And pop the resulting method "
	encoder genHigh: 15 low: 5.
!

" And finally, the actual class behavior for extensions "
!Class
subclass: nm extend: eb | meta cv iv c index |
	" Get the class variable names "
	cv := (eb value: 1) asArray.

	" Make the metaclass "
	meta := Class new name: ('Meta' + nm asString) asSymbol
		parent: self class
		variables: cv.

	" Get the instance variables "
	iv := eb value: 2.
	iv isNil ifTrue: [
		iv := (Array new: 0).
	].

	" Make the main class "
	c := meta new name: nm
		parent: self
		variables: iv.
	globals at: nm put: c.

	" Fill the class variables' values "
	cv := (eb value: 3) asArray.
	index := self class instanceVariables size + 1.
	cv do: [:value|
		self in: c at: index put: value.
		index := index + 1.
	].

	" And finally, add all methods "
	eb value: 4 value: c.

	^c
!

+Object subclass: #ClassExtender variables: #(class)

!Class
extend
	^ClassExtender new forClass: self
!

!ClassExtender
forClass: xclass
	class := xclass.
!

!ClassExtender
extend: eb | tmp |
	" With an extension, there must be no class or instance variables defined "
	tmp := eb value: 1.
	tmp size > 0 ifTrue: [
		^self error: 'Class variable declarations may not appear in class extensions'
	].
	tmp := eb value: 2.
	tmp isNil ifFalse: [
		^self error: 'Instance variable declarations may not appear in class extension'
	].

	" Now just add all the methods "
	eb value: 4 value: class.

	^class
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
	begin := index.
	ln := lineNum.
	token isNil
	ifTrue: [
		nesting := nil.
	]
	ifFalse: [
		nesting := token at: 1.
	].
	nested := Array new: 0.

	push := [:v|
		nested := nested with: nesting.
		nesting := v.
	].
	pop := [
		nested size = 0 ifTrue: [
			index := i.
			lineNum := ln.
			self nextLex.
			^text from: begin to: (i-1)
		].
		nesting := nested at: nested size.
		nested := nested from: 1 to: (nested size - 1).
	].

	i := index.
	[i <= text size] whileTrue: [
		c := text at: i.

		c = Char newline ifTrue: [ ln := ln + 1. ].

		c = $' ifTrue: [
			" Search for string end "
			i := i + 1.
			[i <= text size and: [(text at: i) ~= $']] whileTrue: [
				i := i + 1.
			].
		].

		c = $" ifTrue: [
			" Just search for the comment end "
			i := i + 1.
			[i <= text size and: [(text at: i) ~= $"]] whileTrue: [
				i := i + 1.
			].
		].

		c = $$ ifTrue: [
			" Skip the next character "
			i := i + 1.
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

		i := i + 1.
	].

	^nil
!

!Parser
setErrBlock: to
	errBlock := to
!

" The REPL itself "
+Object subclass: #REPL variables: #(variables fileName cmd lineNum inst newInst transferer)
+Object subclass: #REPLFileReader variables: #(file)

=REPLFileReader
fileIn: nm | fr |
	fr := REPLFileReader new withFile: nm.
	fr fileIn.
!

!REPLFileReader
withFile: nm
	file := File openRead: nm.
	file opened ifFalse: [ ^self error: 'cannot open file ' + nm ].
	^self
!

!REPLFileReader
fileIn
	REPL new repl: file.
	file close.
	file := nil.
!

!REPL
repl
	^self repl: nil
!

=REPL
main | fileInMeth arg doRepl rf command |
	fileInMeth := Undefined parseMethod: 'fileIn: x ^x fileIn' fromFile: 'REPL' atLine: 1.

	" go through arguments "
	doRepl := true.
	[arg := System arg. arg notNil] whileTrue: [
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
				doRepl := false.
				File fileIn: System arg.
			].

			arg = '-r' ifTrue: [
				System version printNl.
				self new repl.
			].
		]
		ifFalse: [
			doRepl := false.
			rf := REPLFileReader new withFile: arg.
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
		fileName := '(input)'.
		readLine := [line := String input].
	]
	ifFalse: [
		fileName := file name.
		readLine := [line := file readFile].
	].
	lineNum := 1.
	cmd := ''.

	variables := (Array new: 0).
	inst := (Object subclass: #REPLInstance) new.
	transferer := Undefined parseMethod: 'transfer: x ^x transfer' fromFile: 'REPL' atLine: 1.

	" Initial prompt "
	file isNil ifTrue: [
		'  -> ' print.
	].

	" Main handler "
	handler := [
		cmd := cmd + line + String newline.

		" Run command(s) "
		(self replCmdAndPrint: file isNil) ifFalse: [^self].
		self leftStripCmd.

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
	line := '.'.
	handler value.

	cmd = '' ifFalse: [
		^self error: 'unhandled input'
	].
!

!REPL
trimCmd: i
	lineNum := lineNum + ((cmd from: 1 to: i-1) occurrencesOf: Char newline).
	cmd := cmd from: i.
!

!REPL
leftStripCmd | i |
	self trimCmd: cmd leftStripCt.
!

!REPL
dropOneLine
	[cmd ~= '' and: [(cmd at: 1) ~= Char newline]] whileTrue: [cmd := cmd from: 2].
!

!REPL
replCmdAndPrint: doPrint | prefix i |
	self leftStripCmd.

	cmd = '' ifTrue: [^true].

	prefix := cmd at: 1.

	prefix = $| ifTrue: [
		self replVars.
		^self replCmdAndPrint: doPrint
	].

	prefix = $! ifTrue: [
		" Special commands "
		self replSpecial ifFalse: [^false].
		^self replCmdAndPrint: doPrint
	].

	prefix = $. ifTrue: [
		" Empty statement "
		cmd := cmd from: 2.
		^self replCmdAndPrint: doPrint
	].

	(self replCodeAndPrint: doPrint) ifTrue: [
		^self replCmdAndPrint: doPrint
	].

	^true
!

!REPL
replCodeAndPrint: doPrint | p ln stmt text meth res |
	p := Parser new fileName: fileName lineNum: lineNum text: cmd instanceVars: (Array new: 0).
	ln := lineNum.
	stmt := p readStringBlock.
	stmt isNil ifTrue: [^false].

	self trimCmd: p index.

	text := 'step ^' + stmt.
	meth := (globals at: #REPLInstance) addMethod: text fromFile: fileName atLine: ln.
	meth isNil ifFalse: [
		res := (Context new perform: meth withArguments: (Array with: inst)).
		doPrint ifTrue: [res printNl.].
		(globals at: #REPLInstance) removeMethod: #step.
	].

	^true
!

!REPL
replVars | p c newC newVars val |
	" Get the new variables "
	p := Parser new fileName: fileName lineNum: lineNum text: cmd instanceVars: (Array new: 0).
	p setErrBlock: [self dropOneLine. ^self].
	p nextLex.
	newVars := p readMethodVariables.
	self trimCmd: p index.
	newVars := variables + newVars.

	" Make the new instance type "
	c := globals at: #REPLInstance.
	newC := Object subclass: #REPLInstance variables: newVars.
	newInst := newC new.

	" Copy over the variables "
	variables do: [:var|
		var := var asString.
		c addMethod: 'getv ^' + var fromFile: 'REPL' atLine: 1.
		newC addMethod: 'setv: x ' + var + ' := x' fromFile: 'REPL' atLine: 1.
		(Context new perform: transferer withArguments: (Array with: nil with: self)).
		newC removeMethod: #setv:.
	].
	variables := newVars.
	inst := newInst.
!

!REPL
replSpecial | p |
	" Get the command "
	p := Parser new fileName: fileName lineNum: lineNum text: cmd instanceVars: (Array new: 0).
	p nextChar.
	p nextLex.

	p token isNil ifTrue: [^true].
	p token = 'quit' ifTrue: [^false].

	'Unrecognized command: ' print.
	p token printNl.

	" Skip to the end of the line "
	self dropOneLine.

	^true.
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
