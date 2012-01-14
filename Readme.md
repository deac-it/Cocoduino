
# About

*Cocoduino* is an IDE for the Arduino written in native Cocoa. It's designed to be simple and easy to use and is a replacement for the official IDE.

*Cocoduino* plays perfectly well together with the official IDE and there are no compatibility problems.

![Cocoduino](http://fabian-kreiser.com/downloads/cocoduino.png)

# Download

You can download the latest version of the application [here](DOWNLOADLINK).

Make sure you have the [official IDE](http://arduino.cc/en/Main/Software) installed, because *Cocoduino* relies on tools that are shipped with it.

# Features

Cocoduino offers nearly the same features as the official IDE:

* **Sketchbook**
* **Serial Monitor**
* **Integrated Examples**
* **Multiple Files or Tabs**
* **Build and Upload to your Arduino**

Additionally, it supports Mac OS X features like:

* **Autosave**
* **Versions**
* **Fullscreen**

Last but not least, there is also:

* **Syntax Coloring**
* **Basic Code Completion**

# Limitations

1. **Build Process**
    
    As there is no official `CLI` interface for the Arduino build process, I can't guarantee that Cocoduino can compile all sketches that work with the official IDE.  
    If you want to more about the internal mechanisms of the build process, see "About the Use of Ino" below.

2. **File Architecture**
    
    The official IDE does use plain text files for the sketches with the path extension `.ino`. Those sketches need to be located inside of a directory with the same name as the main sketch file.  
    When using `NSDocument`, you'd actually want to use a binary data file which is far more powerful, because you can store additional metadata within the file. Or store multiple files in a single one, etc.  
    In order to preserve full compatibility to the official IDE, Cocoduino uses some hacks to use the same file architecture as the official IDE. There are some disadvantages when doing this: *Autosave* doesn't work without additional work and *Versions* is buggy. All in all, I think this was the right decision.

3. **Upload using Programmers**

    While Cocoduino supports nearly all Arduino boards *theoretically*, the use of *programmers* is neither tested nor "officially supported". 

# F.A.Q

1. **Will you add…?**

    Only if I think it'd improve the application. You are free to fork the project, though. (That's why it's open source.)

2. **My sketch won't compile**

    If you have problems with one particular sketch, please post to the [issues](https://github.com/fabiankr/Cocoduino/issues).

3. **Application crashes**

    *To err is human*. Please post the crash log to the [issues](https://github.com/fabiankr/Cocoduino/issues).

# Acknowledgments

Cocoduino uses *(modified)* versions of the following third party libraries:

* [Sparkle](http://sparkle.andymatuschak.org/)
* [SCEvents](http://stuconnolly.com/projects/code/)
* [AMSerialPort](http://www.harmless.de/cocoa-code.php)
* [MASPreferences](https://github.com/shpakovski/MASPreferences)
* [PSMTabBarControl](http://www.positivespinmedia.com/dev/PSMTabBarControl.html)
* [MGSFragaria](https://github.com/mugginsoft/Fragaria)

The tool used for the actual build process is *(strongly modified)*:

* [Ino](http://inotool.org/)