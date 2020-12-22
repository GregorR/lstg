Object subclass: #Inet variables: #().

Inet class extend [
firstIpStringFromHostname: nm [
    <251 0 nm>
]

firstIpAddressFromHostname: nm [
    <251 1 nm>
]

newIpAddressFromIpString: s [
    <251 2 s>
]

newSocketAddressFromIpAddress: addr port: p [
    <251 3 addr p>
]

newSocketAddressFromIpString: s port: p [
    <251 4 s p>
]

newSocketAddressFromHostname: nm port: p [
    <251 5 nm p>
]
].

Object subclass: #Socket variables: #(sockfd).

Socket extend [
socket [
    ^sockfd.
]

socket: fd [
    sockfd <- fd.
]

basicClose [
    <250 20 sockfd>
]

close [
    self basicClose.
    self socket: nil.
]

connect: socketAddr [
    <250 60 sockfd socketAddr>
]

canRead [
    <250 92 sockfd 1>
]

canReadWithTimeout: milliseconds [
    <250 92 sockfd 1 milliseconds>
]

canWrite [
    <250 92 sockfd 2>
]

canWriteWithTimeout: milliseconds [
    <250 92 sockfd 2 milliseconds>
]

basicRecv: aBuffer size: n [
    <250 80 sockfd aBuffer n>
]

basicRecv: aBuffer [
    ^ self basicRecv: aBuffer size: (aBuffer size).
]

recv: n [
    | aBuffer got |
    aBuffer <- String new: n.
    got <- self basicRecv: aBuffer size: n.
    got > 0
        ifTrue: [ ^ aBuffer from: 1 to: got ]
        ifFalse: [ ^ nil ].
]

recvAll [
    | buf total rc waitResult|
    total <- ''.
    buf <- String new: 2048.
    rc <- self basicRecv: buf.
    [ rc > 0 ] whileTrue: [
            total <- total + (buf from: 1 to: rc).
            waitResult <- self canReadWithTimeout: 500.
            waitResult <= 0 ifTrue: [^total].
            rc <- self basicRecv: buf size: 1024.
            0 = rc ifTrue: [^total].
            ].
    ^total
]

basicSend: bytes size: n [
    <250 70 sockfd bytes n>
]

send: aString [
    self basicSend: aString size: (aString size).
]
].

Socket subclass: #TCPSocket variables: #().

TCPSocket extend [
create [
    <250 11>.
]
].

Object subclass: #SocketTest variables: #().

SocketTest class extend [
lookupHost: hostName [
    ^Inet firstIpStringFromHostname: hostName.
]

lookupWord: word [
    | s addr rc buf |
    s <- TCPSocket new.
    s socket: (TCPSocket create).
    addr <- Inet newSocketAddressFromHostname: 'dict.org' port: 2628.
    rc <- s connect: addr.
    rc < 0 ifTrue: [^ 'cannot connect'].
    buf <- s recvAll.
    s send: 'DEFINE * "' + word + '"' + (Char cr asString) + (String newline).
    buf <- s recvAll. buf printNl.
    s send: 'QUIT ' + (Char cr asString) + (String newline).
    buf <- s recvAll.
    s close.
]
].
