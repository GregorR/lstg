Set subclass: #Dict.
Dict subclass: #RotorDict variables: #(rotor).

Dict extend [
at: key ifAbsent: aBlock [
	| pos assoc |
	pos <- self location: key.
	((pos isNil) or: [(assoc <- members at: pos) isNil]) ifTrue: [
		^ aBlock value
	].
	^ assoc value
]

at: key put: value [
	| assoc pos |
	" Create the Association "
	assoc <- Association key: key value: value.

	" Insert it using Set's method "
	self add: assoc.

	^ value
]

binaryDo: aBlock [
	members do: [:assoc|
		assoc notNil ifTrue: [ aBlock value: (assoc key)
			value: (assoc value) ]
	]
]

keysDo: aBlock [
	members do: [:assoc|
		assoc notNil ifTrue: [ aBlock value: (assoc key) ]
	]
]

associationsDo: aBlock [
	members do: [:assoc|
		assoc notNil ifTrue: [ aBlock value: assoc ]
	]
]

basicDo: aBlock [
	^ self associationsDo: aBlock
]

keysAsArray [
	| i ret |
	ret <- Array new: self size.
	i <- 1.
	members do: [:assoc| ret at: i put: assoc key. i <- i + 1 ].
	^ ret
]

isEmpty [
	members do: [:assoc| assoc notNil ifTrue: [ ^ false ]].
	^ true
]

do: aBlock [
	members do: [:assoc| assoc notNil ifTrue:
		[ aBlock value: (assoc value) ] ]
]

removeKey: key ifAbsent: aBlock [
	| assoc |
	assoc <- Association key: key value: nil.
	super remove: assoc ifAbsent: [ ^ aBlock value ].
	^ key
]

removeKey: key [
	^ self removeKey: key ifAbsent: [ self noElement ]
]

remove: value ifAbsent: ignore [
	self error: 'Can only remove by key'
]
].

RotorDict extend [
rotorDo: aBlock [
	| start lim assoc |
	lim <- members size.
	rotor isNil ifTrue: [ rotor <- 1 ].
	start <- rotor.
	[true] whileTrue: [
		assoc <- members at: rotor.
		rotor <- rotor + 1.
		(rotor > lim) ifTrue: [ rotor <- 1 ].
		assoc notNil ifTrue: [ aBlock value: assoc ].
		(rotor = start) ifTrue: [ ^ self ]
	]
]

do: aBlock [
	^self rotorDo: [:assoc| aBlock value: assoc value]
]

keysDo: aBlock [
	^self rotorDo: [:assoc| aBlock value: assoc key]
]

binaryDo: aBlock [
	^self rotorDo: [:assoc| aBlock value: assoc key value: assoc value]
]
].
