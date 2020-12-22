" eight queens exercise "
Object subclass: #NullQueen.

NullQueen extend [
first [
	^ true
]

next [
	^ false
]

checkRow: row column: column [
	^ false
]

result [
	^ List new
]
].

Object subclass: #Queen variables: #(row column neighbor).

Queen extend [
setColumn: aNumber neighbor: aQueen [
	column <- aNumber.
	neighbor <- aQueen
]

checkRow: testRow column: testColumn [
	| columnDifference |
	columnDifference <- testColumn - column.
	(((row = testRow) or:
		[ row + columnDifference = testRow]) or:
		[ row - columnDifference = testRow])
			ifTrue: [ ^ true ].
	^ neighbor checkRow: testRow column: testColumn
]

first [
	neighbor first.
	row <- 1.
	^ self testPosition
]

next [
	^ self advance and: [ self testPosition ]
]

advance [
	(row = 8)
		ifTrue: [ neighbor next ifFalse: [ ^ false ].
			row <- 0 ].
	row <- row + 1.
	^ true
]

testPosition [
	[ neighbor checkRow: row column: column ]
		whileTrue: [ self advance ifFalse: [ ^ false ]].
	^ true
]

result [
	^ neighbor result; addLast: row
]
].

Object subclass: #Main.

Main extend [
run [
	| lastQueen |
	lastQueen <- NullQueen new.
	1 to: 8 do: [:i | lastQueen <- Queen new; 
		setColumn: i neighbor: lastQueen ].
	lastQueen first.
	'got a result' printNl.
	lastQueen result do: [:x | x print. ' ' print ].
	Char newline print.
	[ lastQueen next ] whileTrue:
		[
	lastQueen result do: [:x | x print. ' ' print ].
	Char newline print ]
]
].

Main new run.
