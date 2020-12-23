"
Copyright (C) 1987 - 2005, Timothy A. Budd
Copyright (C) 2005 - 2007, Danny Reinhold
Copyright (C) 2007,        Charles R. Childers
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

" browser.st
	Utility to interactively examine data structures
"
Object subclass: #Browser [
	| stack |

" showPos
	Display stack of objects we're inspecting
"
showPos [
	| cnt |
	' == stack -> ' print.
	cnt := 0.
	stack do: [:obj|
		(cnt > 0) ifTrue: [ ' / ' print ].
		obj print.
		cnt := cnt + 1
	].
	'' printNl
]

" ivars
	Dump instance variables of named object
"
ivars: obj [
	| iv |
	iv := obj class instanceVariables.
	1 to: iv size do: [:idx|
		idx print. Char tab print.
		(iv at: idx) print. ': ' print.
		(Object in: obj at: idx) printNl
	]
]

" run:
	Compile and run Smalltalk expression on object
"
run: args on: obj [
	| t cl |
	" Assemble arguments into single String "
	args do: [:arg|
		t isNil ifTrue: [ t := arg ]
		 ifFalse: [ t := t + ' ' + arg ]
	].

	" Compile into xxBrowse Method for object's class "
	cl := obj class.
	t := 'xxBrowse' + String newline + String tab + '^ ' + t.
	(cl addMethod: t) notNil ifTrue: [
		" Compile OK, run and print result "
		obj xxBrowse printNl.
		" Now clean up (remove) browse method "
		cl removeMethod: #xxBrowse
	]
]

" on:
	Main UI loop for browser
"
on: top [
	| cmd done last obj args idx |
	stack := Array with: top.
	[true] whileTrue: [
		" Show where we are and get next command "
		self showPos.

		" Get next command, explode into cmd/args "
		'Browse> ' print.
		cmd := String input.
		(cmd isNil) ifTrue: [ ^ nil ].
		args := cmd break: ' '.
		cmd := args at: 1.
		args := args from: 2.

		" Get top of stack in its own variable "
		obj := stack at: (stack size).
		done := false.

		" Index with at: "
		((cmd = 'i') or: [cmd = 'index']) ifTrue: [
			last := stack at: (stack size).
			idx := (args at: 1) asNumber.
			last := last at: idx.
			last printNl.
			done := true
		].

		" Nest to last displayed object "
		((cmd = 'n') or: [cmd = 'nest']) ifTrue: [
			stack := stack with: last.
			done := true
		].

		" Show class "
		((cmd = 'c') or: [cmd = 'class']) ifTrue: [
			obj class printNl.
			done := true
		].

		" Pop up a stack level "
		((cmd = 'u') or: [cmd = 'up']) ifTrue: [
			(stack size < 2) ifTrue: [
				'Stack is empty' printNl
			] ifFalse: [
				stack := stack from: 1 to: (stack size - 1)
			].
			done := true
		].

		" Raw index "
		(cmd = 'ri') ifTrue: [
			idx := (args at: 1) asNumber.
			last := Object in: obj at: idx.
			last printNl.
			done := true
		].

		" List instance variables "
		((cmd = 'iv') or: [cmd = 'ivars']) ifTrue: [
			self ivars: obj.
			done := true
		].

		" Show size "
		((cmd = 'bs') or: [cmd = 'basicsize']) ifTrue: [
			obj basicSize printNl.
			done := true
		].
		((cmd = 'sz') or: [cmd = 'size']) ifTrue: [
			obj size printNl.
			done := true
		].

		" Print arbitrary expression "
		((cmd = 'p') or: [cmd = 'print']) ifTrue: [
			self run: args on: obj.
			done := true
		].

		" All done "
		((cmd = 'q') or: [cmd = 'quit']) ifTrue: [
			^ nil
		].

		" Unknown command? "
		done ifFalse: [ ('Unknown command: ' + cmd) printNl ]
	]
]

" o:
	Instantiate a browser on the named object
"
Browser class >> on: obj [
	self new on: obj
]
].
