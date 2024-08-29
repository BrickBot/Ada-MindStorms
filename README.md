Ada/MindStorms
==============
These files are the source code for Ada/MindStorms 2.0, the most important part of which is ada2nqc, an Ada to NQC translator.  NQC is the "Not Quite C" language for Lego MindStorms developed by Dave Baum (http://www.enteract.com/~dbaum/nqc).


Project Details
---------------
ada2nqc.adb is the top level file in the make tree.  If you have AdaGIDE, building ada2nqc will automatically construct the translator executable ada2nqc.exe.  Other important files are:

* **lego.adb, lego.ads**:  	the Ada/Mindstorms API
* **trans_model.adb**:	contains the code that actually performs the translation
* **A95.g**:			an Ada grammar
* **other files**:		define data types and build the parse tree of the source Ada program

If you are making changes to the translator and/or adding functionality, you should never need to change anything apart from lego.adb, lego.ads, trans_model.adb, and possibly ada2nqc.adb if you are adding new command line arguments or options.


Usage
-----
From a command prompt,

	ada2nqc foo
		Translates foo.adb in the current directory to foo.nqc in the current directory
	
	ada2nqc foo bar
		Translates foo.adb in the current directory to bar.nqc in the current directory

Other extensions can be supplied; the default is .adb for the input file (first argument) and .nqc for the output file (second argument).


Prerequisites
-------------
From the archived [installation guide](https://web.archive.org/web/20080526011436/http://www.usafa.af.mil/df/dfcs/adamindstorms1.cfm), Ada/MindStorms works best with the following:
* GNU Ada Translator (GNAT)
* AdaGIDE (a GUI frontend to GNAT)

Both GNAT and AdaGIDE are available at the [AdaGIDE Home Page](http://adagide.martincarlisle.com/).


Links (some might need to be looked up via [archive.org](archive.org))
-----
* [An Ada Interface to Lego MindStorms](http://www.faginfamily.net/barry/Papers/AdaLetters.htm)
  + [Published ACM Paper](https://dl.acm.org/doi/10.1145/362076.362081)
  + [Ada MindStorms](https://web.archive.org/web/20080523112917/http://www.usafa.af.mil/df/dfcs/adamindstorms.cfm)
  + [User Guide and Manual 1.0](https://dl.acm.org/doi/10.1145/362076.569071)
  + [User Guide and Manual 2.0](https://dl.acm.org/doi/10.1145/772938.772941)
  + [Paper covering 3.0](http://www.faginfamily.net/barry/Papers/IEEERA.htm)
  + [Installation Instructions](https://web.archive.org/web/20080526011436/http://www.usafa.af.mil/df/dfcs/adamindstorms1.cfm)
  + [Link to author’s publications page](http://www.faginfamily.net/barry/#Publications)
  + [Manual](http://www.usafa.edu/df/dfcs/ada_Mindstorms_manual.cfm)
  + [AdaMindStorms Manual](http://www.citidel.org/bitstream/10117/145/7/Ada_Mindstorms_manual.htm)
* [AdaGIDE Home Page](http://adagide.martincarlisle.com/)
* [Successfully Build an Ada Compiler in Arch](http://wiki.archlinux.org/index.php/Successfully_Build_an_Ada_Compiler_in_Arch)
* [The GNU Ada Compiler](http://gnuada.sourceforge.net/)
