# QR Code Animation
A tiny program that draws a sample animation to the
console, distributed inside of a QR code.

### Build Requirements
 - A Linux installation
 - binutils (For the GNU Linker)
 - sharutils (For uuencode)
 - nasm (For assembling)
 - qrencode (For creating the QR code)

### Decoding Requirements
 - A Linux installation
 - zbar (For zbarcam/zbarimg)
 - sharutils (For uudecode)

### Runtime Requirements
 - A Linux installation
 - A 64-bit x86-64/AMD64 CPU (Any modern x86 processor)

### How do I decode?
From an image file:
```
zbarimg --raw (FILEPATH) | uudecode
```

From the webcam:
```
zbarcam --raw | uudecode
```

Output will be a binary called "qr"

### How do I build/compile?
Navigate to the root folder of the repo and type "make" into
the console.  The output file will be under "bin/qr.png".
